@echo off
title Chat Export - Real Chat
cls
echo.
echo ========================================
echo  REAL CHAT EXPORT - INSTRUCTIONS
echo ========================================
echo.
echo Step 1: Copy the chat in AntiGravity
echo     - Click on the chat panel
echo     - Press Ctrl+A (select all)
echo     - Press Ctrl+C (copy)
echo.
echo Step 2: Run this script
echo     - The script will read your clipboard
echo     - Parse and export automatically
echo.
echo ========================================
echo.
pause
echo.
echo Running export script...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0export_real_chat_now.ps1"
