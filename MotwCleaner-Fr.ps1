<#
.SYNOPSIS
    MotwCleaner v1.0 - Déverrouilleur Windows MOTW (Mark of the Web)
    S'installe dans le menu contextuel – fonctionne sur les dossiers, l'arrière-plan et les fichiers

.DESCRIPTION
    Windows marque les fichiers téléchargés d'internet avec "Mark of the Web" (MOTW),
    ce qui empêche leur exécution. Ce script supprime ce verrou de façon récursive.
#>

param([string]$StartDir)

# --- REDÉMARRAGE EN ADMIN ---
# Si non exécuté en tant qu'administrateur, redémarrage avec privilèges élevés
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $CurrentDir = if ($StartDir) { $StartDir } else { (Get-Location).Path }
    $Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -StartDir `"$CurrentDir`""
    Start-Process powershell.exe -ArgumentList $Arguments -Verb RunAs
    exit
}

# Définir le répertoire de travail – supprimer les guillemets et espaces du chemin
if ($StartDir) {
    $StartDir = $StartDir.Trim().Trim('"').Trim("'")
    if (Test-Path $StartDir) {
        Set-Location $StartDir
    } else {
        Write-Host "  [AVERTISSEMENT] StartDir n'existe pas: '$StartDir'" -ForegroundColor Yellow
        Write-Host "  Utilisation du répertoire actuel: $((Get-Location).Path)" -ForegroundColor Yellow
    }
}

$ScriptName = "MotwCleaner.ps1"
$TargetDir  = "$env:SystemRoot\Scripts"
$FinalPath  = Join-Path $TargetDir $ScriptName

# --- 1. LOGIQUE D'INSTALLATION ---
# Si le script ne s'exécute pas depuis son emplacement final, proposer l'installation
$CurrentLocation = $PSCommandPath
if (-not ($CurrentLocation.StartsWith($TargetDir, [System.StringComparison]::OrdinalIgnoreCase))) {

    Write-Host "--- MODE INSTALLATION ---" -ForegroundColor Yellow
    $Choice = Read-Host "Installer/Mettre a jour le script dans le systeme? (o/n)"

    if ($Choice -ieq 'o') {

        # Créer le répertoire cible s'il n'existe pas
        if (-not (Test-Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $CurrentLocation -Destination $FinalPath -Force
        Write-Host "Script copie vers: $FinalPath" -ForegroundColor Cyan

        # --- Opérations de registre via l'API .NET ---
        # Microsoft.Win32.Registry gère directement la clé HKCR\*,
        # sans blocage comme le fournisseur PS ou reg.exe.

        $MenuLabel = "Supprimer le verrou (MotwCleaner)"
        $MenuIcon  = "powershell.exe,0"

        # Commande pour dossier / arrière-plan: StartDir = le dossier lui-même
        $CmdFolder = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%1`""
        $CmdBg     = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%V`""
        # Commande pour fichiers: %~dp1. = dossier parent du fichier
        $CmdFile   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%~dp1.`""

        $RegEntries = @(
            @{ Hive = "Directory\shell\MotwCleaner";            Cmd = $CmdFolder },
            @{ Hive = "Directory\Background\shell\MotwCleaner"; Cmd = $CmdBg     },
            @{ Hive = "*\shell\MotwCleaner";                    Cmd = $CmdFile   }
        )

        $HKCR = [Microsoft.Win32.Registry]::ClassesRoot

        foreach ($Entry in $RegEntries) {
            Write-Host "  Registre: HKCR\$($Entry.Hive)" -ForegroundColor DarkCyan
            try {
                # Nettoyage: supprimer l'ancienne clé si elle existe
                try { $HKCR.DeleteSubKeyTree($Entry.Hive, $false) } catch {}

                # Créer la nouvelle clé
                $Key = $HKCR.CreateSubKey($Entry.Hive)
                $Key.SetValue("", $MenuLabel)
                $Key.SetValue("Icon", $MenuIcon)
                $Key.Close()

                $CmdKey = $HKCR.CreateSubKey("$($Entry.Hive)\command")
                $CmdKey.SetValue("", $Entry.Cmd)
                $CmdKey.Close()

                Write-Host "  OK" -ForegroundColor Green
            }
            catch {
                Write-Host "  ERREUR: $_" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Installation reussie!" -ForegroundColor Green
        Write-Host "Le menu contextuel affiche maintenant: 'Supprimer le verrou (MotwCleaner)'" -ForegroundColor Green
        Write-Host "Appuyez sur une touche pour quitter..."
        Pause
        exit
    }
}

# --- 2. DÉVERROUILLAGE (le travail réel) ---
$Target = (Get-Location).Path

# --- LISTE DE BLOCAGE DE SÉCURITÉ ---
# Ne jamais traiter les dossiers système, même accidentellement
$BlockedPaths = @(
    $env:SystemRoot,
    "$env:SystemRoot\System32",
    "$env:SystemRoot\SysWOW64",
    "$env:SystemRoot\WinSxS",
    "$env:SystemRoot\Scripts",
    $env:ProgramFiles,
    ${env:ProgramFiles(x86)},
    $env:ProgramData,
    [System.Environment]::GetFolderPath("System"),
    [System.Environment]::GetFolderPath("Windows")
)

foreach ($Blocked in $BlockedPaths) {
    if (-not $Blocked) { continue }
    if ($Target.TrimEnd('\') -eq $Blocked.TrimEnd('\') -or
        $Target.StartsWith($Blocked.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host ""
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host "  DOSSIER SYSTEME PROTEGE - ACCES REFUSE     " -ForegroundColor Red
        Write-Host "  Cible  : $Target"                            -ForegroundColor Red
        Write-Host "  Raison : dans une zone protegee: $Blocked"   -ForegroundColor Red
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Appuyez sur une touche pour quitter..." -ForegroundColor Yellow
        Pause
        exit 1
    }
}

Write-Host ""
Write-Host "--- MotwCleaner ACTIF ---" -ForegroundColor Cyan
Write-Host "  Cible: $Target"          -ForegroundColor White
Write-Host ""

$Files     = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue
$Total     = $Files.Count
$Counter   = 0
$Unblocked = 0
$Skipped   = 0

foreach ($File in $Files) {
    $Counter++
    $Percent = [int](($Counter / [Math]::Max($Total, 1)) * 100)
    Write-Progress -Activity "Suppression des verrous..." -Status "$Counter / $Total - $($File.Name)" -PercentComplete $Percent

    try {
        Unblock-File -Path $File.FullName -ErrorAction Stop
        $Unblocked++
    }
    catch {
        Write-Host "  [SKIP] $($File.FullName): $_" -ForegroundColor DarkYellow
        $Skipped++
    }
}

Write-Progress -Activity "Suppression des verrous..." -Completed

Write-Host ""
Write-Host "TERMINE!" -ForegroundColor Green
Write-Host "  Déverrouillé : $Unblocked fichier(s)"
Write-Host "  Ignoré       : $Skipped fichier(s) (accès refusé ou déjà déverrouillé)"
Write-Host ""
Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Yellow
Pause
