@echo off
echo [AntiGravity] Closing previous instances (Port 1337)...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":1337" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
timeout /t 1 /nobreak >nul
title OmniDashboard Server
echo [AntiGravity] Starting OmniDashboard...
echo [INFO] Server listening on http://localhost:1337
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "server\OmniServer.ps1"
pause
