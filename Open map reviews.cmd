@echo off
powershell.exe -NoProfile -File "%~dp0tools\collection-review\Open-MapReviews.ps1"
if errorlevel 1 pause
