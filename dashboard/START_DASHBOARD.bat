@echo off
title OmniDashboard Server
echo [AntiGravity] Starting OmniDashboard...
echo [INFO] Server listening on http://localhost:1337
powershell -ExecutionPolicy Bypass -File "server\OmniServer.ps1"
pause
