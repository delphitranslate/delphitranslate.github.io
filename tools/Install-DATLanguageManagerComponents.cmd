@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-DATLanguageManagerComponents.ps1" %*
if errorlevel 1 (
  echo.
  echo DAT Language Manager component setup failed. Review the message above.
  pause
  exit /b 1
)
echo.
echo DAT Language Manager component setup finished successfully.
pause
