@echo off
setlocal enableextensions enabledelayedexpansion
title Install Smart Display Switcher

set "SD=%~dp0"
set "SD=%SD:~0,-1%"
set "TN=SmartDisplaySwitcher"
set "PS1=%SD%\SmartDisplaySwitcher.ps1"
set "BAT=%SD%\Start-Switcher.bat"
set "MOD=%SD%\modules"
set "ICO=%SD%\assets\tray.ico"

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
echo   ^|     Installer                                    ^|
echo   ^|                                                  ^|
echo   +--------------------------------------------------+
echo.

echo   [*] Checking files...
set "OK=1"
if not exist "%PS1%" (set "OK=0" & echo   [x] Missing: SmartDisplaySwitcher.ps1)
if not exist "%BAT%" (set "OK=0" & echo   [x] Missing: Start-Switcher.bat)
if not exist "%MOD%" (set "OK=0" & echo   [x] Missing: modules\)
for %%m in (Monitor DesktopControl ProcessManager ConfigManager I18n Logger) do (
    if not exist "%MOD%\%%m.psm1" (set "OK=0" & echo   [x] Missing: %%m.psm1)
)
if "%OK%"=="0" (color 0C & pause & exit /b 1)
color 0A
echo   [v] All files verified.
echo.

schtasks /query /tn "ScreenControl" >nul 2>&1
if !errorLevel! EQU 0 (
    echo   [-] Removing legacy task...
    schtasks /delete /tn "ScreenControl" /f >nul 2>&1
)

schtasks /query /tn "%TN%" >nul 2>&1
if !errorLevel! EQU 0 (
    echo   [!] Already installed.
    set /p "RE=    Reinstall? [Y/N]: "
    if /i not "!RE!"=="Y" (echo   [-] Cancelled. & pause & exit /b 0)
    schtasks /delete /tn "%TN%" /f >nul 2>&1
    echo   [v] Old task removed.
    echo.
)

color 07
echo   [*] Creating scheduled task...
schtasks /create /tn "%TN%" /tr "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File %PS1% -Minimized" /sc onlogon /rl highest /f >nul 2>&1

if !errorLevel! EQU 0 (
    color 0A
    echo   [v] Task created: %TN%
    echo       Trigger:  User logon
    echo       Mode:     Background hidden
    echo.
) else (
    color 0C
    echo   [x] Task creation failed.
    pause
    exit /b 1
)

color 07
set /p "SC=    Create desktop shortcut? [Y/N]: "
if /i "%SC%"=="Y" (
    echo   [*] Creating shortcut...
    powershell -Command "$lnk=[System.Environment]::GetFolderPath('Desktop')+'\Smart Display Switcher.lnk';$ws=New-Object -ComObject WScript.Shell;$sc=$ws.CreateShortcut($lnk);$sc.TargetPath='%BAT%';$sc.WorkingDirectory='%SD%';$sc.IconLocation='%ICO%';$sc.Save();if(Test-Path $lnk){exit 0}else{exit 1}"
    if !errorLevel! EQU 0 (
        color 0A
        echo   [v] Shortcut created with icon.
    ) else (
        color 0E
        echo   [!] Shortcut may have failed.
    )
    echo.
)

color 07
echo   +--------------------------------------------------+
echo.
echo     Install complete.
echo.
echo     Auto-start:  Enabled - runs on user logon
echo     Start now:   Start-Switcher.bat
echo     Uninstall:   uninstall.bat
echo.
echo   +--------------------------------------------------+
echo.
pause
exit /b 0
