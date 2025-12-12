@echo off
title Chat Auto-Export (Standalone)
powershell.exe -ExecutionPolicy Bypass -File "%~dp0standalone_chat_exporter.ps1"
pause
