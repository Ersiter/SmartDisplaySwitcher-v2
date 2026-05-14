@echo off
setlocal enableextensions enabledelayedexpansion
title Uninstall Smart Display Switcher

set "SD=%~dp0"
set "SD=%SD:~0,-1%"
set "TN=SmartDisplaySwitcher"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting admin rights...
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
color 07
echo.
echo   +--------------------------------------------------+
echo   ^|                                                  ^|
echo   ^|     Smart Display Switcher  v2.1                 ^|
echo   ^|                                                  ^|
echo   ^|     Uninstaller                                  ^|
echo   ^|                                                  ^|
echo   +--------------------------------------------------+
echo.

set /p "CONFIRM=    Are you sure? [Y/N]: "
if /i not "%CONFIRM%"=="Y" (echo   [-] Cancelled. & pause & exit /b 0)

echo.
echo   [*] Uninstalling...

echo   [*] Stopping processes...
taskkill /fi "windowtitle eq *SmartDisplaySwitcher*" /f >nul 2>&1
timeout /t 1 /nobreak >nul
color 0A & echo   [v] Processes stopped.

echo   [*] Removing scheduled tasks...
schtasks /query /tn "%TN%" >nul 2>&1
if !errorLevel! EQU 0 (
    schtasks /delete /tn "%TN%" /f >nul 2>&1
    color 0A & echo   [v] Removed: %TN%
) else (
    echo   [-] Not found: %TN%
)
schtasks /query /tn "ScreenControl" >nul 2>&1
if !errorLevel! EQU 0 (
    schtasks /delete /tn "ScreenControl" /f >nul 2>&1
    color 0A & echo   [v] Removed: ScreenControl
)

echo   [*] Removing shortcuts...
if exist "%USERPROFILE%\Desktop\Smart Display Switcher.lnk" (
    del "%USERPROFILE%\Desktop\Smart Display Switcher.lnk" >nul 2>&1
)
if exist "%PUBLIC%\Desktop\Smart Display Switcher.lnk" (
    del "%PUBLIC%\Desktop\Smart Display Switcher.lnk" >nul 2>&1
)
color 0A & echo   [v] Shortcuts removed.
echo.

set /p "KEEP=    Keep config and logs? [Y/N]: "
if /i not "%KEEP%"=="Y" (
    echo   [*] Removing data...
    if exist "%SD%\backup" (rd /s /q "%SD%\backup" >nul 2>&1)
    if exist "%TEMP%\SmartDisplaySwitcher.log" (del "%TEMP%\SmartDisplaySwitcher.log" >nul 2>&1)
    if exist "%SD%\config.json" (del "%SD%\config.json" >nul 2>&1)
    color 0A & echo   [v] Data removed.
)
echo.

color 07
echo   +--------------------------------------------------+
echo.
echo     Uninstall complete.
echo.
echo     Program files kept at:
echo     %SD%
echo.
echo     Delete manually to fully remove.
echo.
echo   +--------------------------------------------------+
echo.
pause
exit /b 0
