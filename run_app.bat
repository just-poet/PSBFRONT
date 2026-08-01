@echo off
title FINIX Dashboard Runner
echo ===================================================
echo             FINIX DASHBOARD RUNNER
echo ===================================================
echo.

cd /d "%~dp0"

echo [1/3] Verifying dependencies...
call C:\Users\kumar\flutter\bin\flutter.bat pub get

echo.
echo [2/3] Choose how you want to open/run the screen:
echo ---------------------------------------------------
echo  [1] Open in Google Chrome (Web Mode - Recommended)
echo  [2] Open in Microsoft Edge (Web Mode)
echo  [3] Run on default connected Mobile Device / Emulator
echo ---------------------------------------------------
echo.

set /p choice="Select option (1, 2, or 3, default is 1): "

echo.
echo [3/3] Launching FINIX Dashboard...
echo ---------------------------------------------------

if "%choice%"=="2" (
    call C:\Users\kumar\flutter\bin\flutter.bat run -d edge
) else if "%choice%"=="3" (
    call C:\Users\kumar\flutter\bin\flutter.bat run
) else (
    call C:\Users\kumar\flutter\bin\flutter.bat run -d chrome
)

echo.
echo App closed.
pause
