@echo off
title Autodromo Bot Racing - Terminal Server
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "src\server\iniciar_terminal.ps1"
pause
