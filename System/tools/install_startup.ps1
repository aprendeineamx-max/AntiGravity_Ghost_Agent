<#
.SYNOPSIS
Installs OmniControl to Windows Startup folder.

.DESCRIPTION
Created a Shortcut in the current user's Startup folder
pointing to the START_OMNICONTROL.bat launcher.
#>

$TargetFile = Join-Path $PSScriptRoot "..\START_OMNICONTROL.bat"
$ShortcutName = "AntiGravity OmniControl.lnk"
$StartupPath = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupPath $ShortcutName

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetFile
$Shortcut.WorkingDirectory = Split-Path $TargetFile
$Shortcut.WindowStyle = 7 # Minimized
$Shortcut.Description = "Auto-Start for AntiGravity Overwatch"
$Shortcut.IconLocation = "shell32.dll,238" # Shield Icon
$Shortcut.Save()

Write-Host " [OK] Installed to Startup: $ShortcutPath" -ForegroundColor Green
Write-Host " OmniControl will now start automatically with Windows." -ForegroundColor Gray
Start-Sleep -Seconds 3
