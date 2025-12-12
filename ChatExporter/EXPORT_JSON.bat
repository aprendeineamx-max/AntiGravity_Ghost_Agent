@echo off
title Chat Export JSON - Launcher
color 0B

echo.
echo ========================================
echo  CHAT EXPORT JSON v2.0
echo ========================================
echo.
echo Dual format export (JSON + Markdown)
echo.
pause

echo.
echo Executing export...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0export_json.ps1"

echo.
echo ========================================
echo.
echo Export complete!
echo Check your Documents\AntiGravity_Chat_Exports folder
echo.
pause
