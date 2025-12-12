Write-Host "Reiniciando AntiGravity..." -ForegroundColor Cyan

Stop-Process -Name "Antigravity" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process "C:\Users\Administrator\AppData\Local\Programs\Antigravity\Antigravity.exe"

Write-Host "Completado!" -ForegroundColor Green
Start-Sleep -Seconds 2
