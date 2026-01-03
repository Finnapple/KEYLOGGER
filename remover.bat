@echo off
echo Killing script.exe...
taskkill /f /im script.exe >nul 2>&1

echo Checking startup registry...
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run

echo Deleting WindowsService registry entry...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WindowsService /f

echo.
echo Done.
pause
