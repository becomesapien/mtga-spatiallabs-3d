@echo off
title MTG Arena 3D for Acer SpatialLabs - Installer
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Install-MTGA-3D.ps1" %*
echo.
pause
