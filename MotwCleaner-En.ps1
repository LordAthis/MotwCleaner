<#
.SYNOPSIS
    MotwCleaner v1.0 - Windows MOTW (Mark of the Web) unlocker
    Installs to right-click context menu – works on folders, folder background and files

.DESCRIPTION
    Windows marks files downloaded from the internet with "Mark of the Web" (MOTW),
    which prevents them from running. This script removes that lock recursively.
#>

param([string]$StartDir)

# --- ADMIN AUTO-RELAUNCH ---
# If not running as admin, restart with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $CurrentDir = if ($StartDir) { $StartDir } else { (Get-Location).Path }
    $Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -StartDir `"$CurrentDir`""
    Start-Process powershell.exe -ArgumentList $Arguments -Verb RunAs
    exit
}

# Set working directory – strip quotes and whitespace from the path
if ($StartDir) {
    $StartDir = $StartDir.Trim().Trim('"').Trim("'")
    # If a file was right-clicked, use its parent folder as target
    if (Test-Path $StartDir -PathType Leaf) {
        $StartDir = Split-Path -Parent $StartDir
    }
    if (Test-Path $StartDir) {
        Set-Location $StartDir
    } else {
        Write-Host "  [WARNING] StartDir does not exist: '$StartDir'" -ForegroundColor Yellow
        Write-Host "  Using current directory: $((Get-Location).Path)"  -ForegroundColor Yellow
    }
}

$ScriptName = "MotwCleaner.ps1"
$TargetDir  = "$env:SystemRoot\Scripts"
$FinalPath  = Join-Path $TargetDir $ScriptName

# --- 1. INSTALL LOGIC ---
# If the script is not running from its final location, offer installation
$CurrentLocation = $PSCommandPath
if (-not ($CurrentLocation.StartsWith($TargetDir, [System.StringComparison]::OrdinalIgnoreCase))) {

    Write-Host "--- INSTALL MODE ---" -ForegroundColor Yellow
    $Choice = Read-Host "Install/Update the script to the system? (y/n)"

    if ($Choice -ieq 'y') {

        # Create target directory if it doesn't exist
        if (-not (Test-Path $TargetDir)) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $CurrentLocation -Destination $FinalPath -Force
        Write-Host "Script copied to: $FinalPath" -ForegroundColor Cyan

        # --- Remove old RepoFixer entries too (renamed project) ---
        $OldEntries = @("Directory\\shell\\RepoFixer", "Directory\\Background\\shell\\RepoFixer", "*\\shell\\RepoFixer")
        $HKCRClean = [Microsoft.Win32.Registry]::ClassesRoot
        foreach ($OE in $OldEntries) { try { $HKCRClean.DeleteSubKeyTree($OE, $false) } catch {} }

        # --- Registry operations via .NET API ---
        # Microsoft.Win32.Registry handles the HKCR\* key directly,
        # without freezing like the PS provider or reg.exe.

        $MenuLabel = "Remove Lock (MotwCleaner)"
        $MenuIcon  = "powershell.exe,0"

        # Command for folder / folder background: StartDir = the folder itself
        $CmdFolder = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%1`""
        $CmdBg     = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FinalPath`" -StartDir `"%V`""
        # Command for files: %1 = the file itself – the script extracts the parent folder on startup
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
                # Cleanup: delete old key if it exists
                try { $HKCR.DeleteSubKeyTree($Entry.Hive, $false) } catch {}

                # Create new key
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
                Write-Host "  ERROR: $_" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Installation successful!" -ForegroundColor Green
        Write-Host "Right-click menu now shows: 'Remove Lock (MotwCleaner)'" -ForegroundColor Green
        Write-Host "Press any key to exit..."
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
        exit
    }
}

# --- 2. UNLOCK (the actual work) ---
$Target = (Get-Location).Path

# --- SAFETY BLOCKLIST ---
# Never run on system folders, even by accident
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
        Write-Host "  PROTECTED SYSTEM FOLDER - ACCESS DENIED    " -ForegroundColor Red
        Write-Host "  Target  : $Target"                           -ForegroundColor Red
        Write-Host "  Reason  : inside protected path: $Blocked"  -ForegroundColor Red
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
        exit 1
    }
}

Write-Host ""
Write-Host "--- MotwCleaner ACTIVE ---" -ForegroundColor Cyan
Write-Host "  Target: $Target"          -ForegroundColor White
Write-Host ""

$Files     = Get-ChildItem -Path $Target -Recurse -File -ErrorAction SilentlyContinue
$Total     = $Files.Count
$Counter   = 0
$Unblocked = 0
$Skipped   = 0

foreach ($File in $Files) {
    $Counter++
    $Percent = [int](($Counter / [Math]::Max($Total, 1)) * 100)
    Write-Progress -Activity "Removing locks..." -Status "$Counter / $Total - $($File.Name)" -PercentComplete $Percent

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

Write-Progress -Activity "Removing locks..." -Completed

Write-Host ""
Write-Host "DONE!" -ForegroundColor Green
Write-Host "  Unlocked : $Unblocked file(s)"
Write-Host "  Skipped  : $Skipped file(s) (access denied or already unlocked)"
Write-Host ""
Write-Host "Press any key to close..." -ForegroundColor Yellow
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
