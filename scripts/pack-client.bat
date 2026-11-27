@echo off
rem pack-client.bat - launch the client packing script by double click (same as running pack-client.ps1)
rem Arguments pass through, e.g. pack-client.bat -Version 2026-12-01
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack-client.ps1" %*
if errorlevel 1 (
  echo.
  echo Pack FAILED - see the error above.
) else (
  echo.
  echo Pack finished.
)
pause
