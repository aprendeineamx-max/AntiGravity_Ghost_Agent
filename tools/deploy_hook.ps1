$Source = "C:\AntiGravityExt\AntiGravity_Ghost_Agent\AntiGravity_Internal_Hook"
$Dest = "C:\Users\Administrator\AppData\Local\Programs\Antigravity\resources\app\extensions\antigravity-internal-hook"

Write-Host "Deploying Internal Hook..." -ForegroundColor Cyan
robocopy $Source $Dest /E

Write-Host "Deployment Complete." -ForegroundColor Green
Write-Host "Please Reload Window (Ctrl+R) to apply changes." -ForegroundColor Yellow
