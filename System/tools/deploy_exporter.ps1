$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$Source = Join-Path $ScriptDir "..\..\AntiGravity_Chat_Exporter"
$Dest = "C:\Users\Administrator\AppData\Local\Programs\Antigravity\resources\app\extensions\antigravity-chat-exporter"

Write-Host "Deploying Chat Exporter..." -ForegroundColor Cyan
robocopy $Source $Dest /E

Write-Host "Deployment Complete." -ForegroundColor Green
Write-Host "Please Reload Window (Ctrl+R)." -ForegroundColor Yellow
