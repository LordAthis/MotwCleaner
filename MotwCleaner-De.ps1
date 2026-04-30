<#
.SYNOPSIS
    MotwCleaner v1.0 - Windows MOTW (Mark of the Web) Entsperrer
    Installiert sich im Kontextmenü – funktioniert auf Ordnern, Ordnerhintergrund und Dateien

.DESCRIPTION
    Windows markiert aus dem Internet heruntergeladene Dateien mit "Mark of the Web" (MOTW),
    was deren Ausführung verhindert. Dieses Skript entfernt diese Sperre rekursiv.
#>

param([string]$StartDir)

# --- ADMIN AUTO-NEUSTART ---
# Falls nicht als Administrator gestartet, Neustart mit erhöhten Rechten
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $CurrentDir = if ($StartDir) { $StartDir } else { (Get-Location).Path }
    $Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -StartDir `"$CurrentDir`""
    Start-Process powershell.exe -ArgumentList $Arguments -Verb RunAs
    exit
}

# Arbeitsverzeichnis setzen – Anführungszeichen und Leerzeichen aus dem Pfad entfernen
if ($StartDir) {
    $StartDir = $StartDir.Trim().Trim('"').Trim("'")
    # Falls auf eine Datei geklickt wurde, den übergeordneten Ordner als Ziel verwenden
    if (Test-Path $StartDir -PathType Leaf) {
        $StartDir = Split-Path -Parent $StartDir
    }
    if (Test-Path $StartDir) {
        Set-Location $StartDir
    } else {
        Write-Host "  [WARNUNG] StartDir existiert nicht: '$StartDir'" -ForegroundColor Yellow
        Write-Host "  Aktuelles Verzeichnis wird verwendet: $((Get-Location).Path)" -ForegroundColor Yellow
    }
}

$ScriptName = "MotwCleaner.ps1"
$TargetDir  = "$env:SystemRoot\Scripts"
$FinalPath  = Join-Path $TargetDir $ScriptName

# --- 1. INSTALLATIONSLOGIK ---
# Falls das Skript nicht vom Zielort aus läuft, Installation anbieten
$CurrentLocation = $PSCommandPath
if (-not ($CurrentLocation.StartsWith($TargetDir, [System.StringComparison]::OrdinalIgnoreCase))) {

    Write-Host "--- INSTALLATIONSMODUS ---" -ForegroundColor Yellow
    $Choice = Read-Host "Skript ins System installieren/aktualisieren? (j/n)"

    if ($Choice -ieq 'j') {

        # Zielordner erstellen falls nicht vorhanden
        if (-not (Test-Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $CurrentLocation -Destination $FinalPath -Force
        Write-Host "Skript kopiert nach: $FinalPath" -ForegroundColor Cyan

        # --- Alte RepoFixer-Einträge ebenfalls entfernen (Projektumbenennung) ---
        $OldEntries = @("Directory\\shell\\RepoFixer", "Directory\\Background\\shell\\RepoFixer", "*\\shell\\RepoFixer")
        $HKCRClean = [Microsoft.Win32.Registry]::ClassesRoot
        foreach ($OE in $OldEntries) { try { $HKCRClean.DeleteSubKeyTree($OE, $false) } catch {} }

        # --- Registry-Operationen über .NET API ---
        # Microsoft.Win32.Registry behandelt den HKCR\* Schlüssel direkt,
        # ohne wie der PS-Provider oder reg.exe einzufrieren.

        $MenuLabel = "Sperre aufheben (MotwCleaner)"
        $MenuIcon  = "powershell.exe,0"

        # Befehl für Ordner / Ordnerhintergrund: StartDir = der Ordner selbst
        $CmdFolder = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%1`""
        $CmdBg     = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%V`""
        # Befehl für Dateien: %1 = die Datei selbst – das Skript ermittelt den übergeordneten Ordner beim Start
        $CmdFile   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%1`""

        $RegEntries = @(
            @{ Hive = "Directory\shell\MotwCleaner";            Cmd = $CmdFolder },
            @{ Hive = "Directory\Background\shell\MotwCleaner"; Cmd = $CmdBg     },
            @{ Hive = "*\shell\MotwCleaner";                    Cmd = $CmdFile   }
        )

        $HKCR = [Microsoft.Win32.Registry]::ClassesRoot

        foreach ($Entry in $RegEntries) {
            Write-Host "  Registry: HKCR\$($Entry.Hive)" -ForegroundColor DarkCyan
            try {
                # Bereinigung: alten Schlüssel löschen falls vorhanden
                try { $HKCR.DeleteSubKeyTree($Entry.Hive, $false) } catch {}

                # Neuen Schlüssel erstellen
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
                Write-Host "  FEHLER: $_" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Installation erfolgreich!" -ForegroundColor Green
        Write-Host "Rechtsklick-Menue zeigt jetzt: 'Sperre aufheben (MotwCleaner)'" -ForegroundColor Green
        Write-Host "Beliebige Taste zum Beenden druecken..."
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
        exit
    }
}

# --- 2. ENTSPERREN (die eigentliche Arbeit) ---
$Target = (Get-Location).Path

# --- SICHERHEITS-SPERRLISTE ---
# Systemordner werden niemals verarbeitet, auch nicht versehentlich
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
        Write-Host "  GESCHUETZTER SYSTEMORDNER - ZUGRIFF VERWEIGERT " -ForegroundColor Red
        Write-Host "  Ziel   : $Target"                           -ForegroundColor Red
        Write-Host "  Grund  : im gesperrten Bereich: $Blocked"   -ForegroundColor Red
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Beliebige Taste zum Beenden druecken..." -ForegroundColor Yellow
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
        exit 1
    }
}

Write-Host ""
Write-Host "--- MotwCleaner AKTIV ---" -ForegroundColor Cyan
Write-Host "  Ziel: $Target"           -ForegroundColor White
Write-Host ""

$Files     = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue
$Total     = $Files.Count
$Counter   = 0
$Unblocked = 0
$Skipped   = 0

foreach ($File in $Files) {
    $Counter++
    $Percent = [int](($Counter / [Math]::Max($Total, 1)) * 100)
    Write-Progress -Activity "Sperren werden aufgehoben..." -Status "$Counter / $Total - $($File.Name)" -PercentComplete $Percent

    try {
        # Zone.Identifier stream meglétét Get-Item -Stream-mel ellenőrizzük
        $WasLocked = $null -ne (Get-Item -Path $File.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue)
        Unblock-File -Path $File.FullName -ErrorAction Stop
        if ($WasLocked) { $Unblocked++ }
    }
    catch {
        Write-Host "  [SKIP] $($File.FullName): $_" -ForegroundColor DarkYellow
        $Skipped++
    }
}

Write-Progress -Activity "Sperren werden aufgehoben..." -Completed

Write-Host ""
Write-Host "FERTIG!" -ForegroundColor Green
Write-Host "  Entsperrt  : $Unblocked Datei(en)"
Write-Host "  Uebersprungen : $Skipped Datei(en) (Zugriff verweigert oder bereits entsperrt)"
Write-Host ""
Write-Host "Beliebige Taste zum Schliessen druecken..." -ForegroundColor Yellow
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
