# Test Runner for OmniControl
# Launches Mock Target and OmniControl to verify interaction

$p1 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\AntiGravityExt\AntiGravity_Ghost_Agent\tests\MockTargetApp.ps1" -PassThru
Start-Sleep -Seconds 2
$p2 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\AntiGravityExt\AntiGravity_Ghost_Agent\tools\OmniControl_HUD.ps1" -PassThru

Write-Host "Tests Running... Waiting for interaction (10s)..."
Start-Sleep -Seconds 15

# Cleanup
Stop-Process -Id $p2.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $p1.Id -Force -ErrorAction SilentlyContinue

# Check Result
if (Test-Path "C:\AntiGravityExt\AntiGravity_Ghost_Agent\tests\mock_status.txt") {
    Get-Content "C:\AntiGravityExt\AntiGravity_Ghost_Agent\tests\mock_status.txt"
}
else {
    Write-Host "FAIL: Log file not found."
}
