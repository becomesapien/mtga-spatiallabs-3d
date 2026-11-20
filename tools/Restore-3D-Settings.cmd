@echo off
rem Restores your saved MTG Arena 3D settings (run while Arena is closed, or press Ctrl+Alt+R in game afterwards).
cd /d "%~dp0"
copy /y "MTGA-SpatialLabs-3D.ini" "ReShadePreset.ini" >nul
echo MTG Arena 3D settings restored.
pause
