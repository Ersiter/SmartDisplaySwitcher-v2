@echo off
setlocal enableextensions enabledelayedexpansion
title Smart Display Switcher

set "SELF=%~dp0"
set "SELF=%SELF:~0,-1%"
set "PS1=%SELF%\SmartDisplaySwitcher.ps1"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting admin rights...
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%PS1%" (
    echo [FAIL] Main script not found
    pause
    exit /b 1
)

set "ARGS="
:next
if "%~1"=="" goto :launch
if /i "%~1"=="-min" set "ARGS=%ARGS% -Minimized"
if /i "%~1"=="-lang" (
    shift
    set "ARGS=%ARGS% -Language %~1"
)
shift
goto :next

:launch
color 07
cls
echo.
echo   +--------------------------------------------------+
echo   ^|                                                  ^|
echo   ^|     Smart Display Switcher  v2.1                 ^|
echo   ^|                                                  ^|
echo   ^|     Starting in system tray...                   ^|
echo   ^|     Press Win+B to find the tray icon            ^|
echo   ^|                                                  ^|
echo   +--------------------------------------------------+
echo.

PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS1%" %ARGS%

if %ERRORLEVEL% NEQ 0 (
    color 0E
    echo [WARN] Exit code %ERRORLEVEL%
    pause
)

color 07
exit /b %ERRORLEVEL%
