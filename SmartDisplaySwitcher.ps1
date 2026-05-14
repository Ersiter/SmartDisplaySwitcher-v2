<#
.SYNOPSIS
    Smart Display Switcher - Enhanced Version
.DESCRIPTION
    Automatically detects monitor type and switches desktop layout.
    Supports system tray mode with Windows Forms.
.NOTES
    Author: Ersiter
    Version: 2.1
    License: MIT
#>

#Requires -Version 5.1

param (
    [switch]$Minimized,
    [string]$ConfigPath,
    [string]$Language
)

$ErrorActionPreference = "Stop"

$Script:ScriptDir = $PSScriptRoot
if (-not $Script:ScriptDir) {
    $Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$Script:ModulesDir = Join-Path $Script:ScriptDir "modules"
$Script:Running = $false
$Script:TrayIcon = $null
$Script:ContextMenu = $null
$Script:MonitorTimer = $null
$Script:LastMode = $null

function Import-RequiredModules {
    $modules = @('Monitor', 'DesktopControl', 'ProcessManager', 'ConfigManager', 'I18n', 'Logger')
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $Script:ModulesDir "$module.psm1"
        
        if (Test-Path $modulePath) {
            try {
                Import-Module $modulePath -Force -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to load module: $module - $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        else {
            Write-Host "Module not found: $modulePath" -ForegroundColor Red
            exit 1
        }
    }
}

function Initialize-Application {
    Import-RequiredModules
    
    $logPath = Join-Path $env:TEMP "SmartDisplaySwitcher.log"
    $backupDir = Join-Path $Script:ScriptDir "backup"
    Initialize-Logger -LogPath $logPath -BackupDir $backupDir -ConsoleOutput (-not $Minimized)
    
    $configFile = if ($ConfigPath) { $ConfigPath } else { Join-Path $Script:ScriptDir "config.json" }
    Initialize-ConfigManager -ConfigPath $configFile -MigrateOld
    
    $config = Get-Config
    
    $langDir = Join-Path $Script:ScriptDir "lang"
    $defaultLang = if ($Language) { $Language } else { $config.display.language }
    Initialize-I18n -LangDir $langDir -DefaultLang $defaultLang
    
    Initialize-MonitorModule -Config $config
    
    Write-Info "Application initialized" -Component "Main"
}

function Invoke-ModeSwitch {
    param(
        [Parameter(Mandatory)]
        [string]$Mode
    )
    
    $config = Get-Config
    
    if ($Mode -eq "laptop") {
        Write-Info "Switching to laptop mode" -Component "Switch"
        Set-DesktopIconsVisibility -Visible $false
        
        foreach ($app in $config.apps) {
            if ($app.enabled -and $app.path) {
                Start-DesktopApp -ExecutablePath $app.path -Arguments $app.arguments
            }
        }
        
        if ($config.wallpaper.enabled -and $config.wallpaper.laptopMode) {
            Set-Wallpaper -Path $config.wallpaper.laptopMode
        }
    }
    elseif ($Mode -eq "desktop") {
        Write-Info "Switching to desktop mode" -Component "Switch"
        Set-DesktopIconsVisibility -Visible $true
        
        foreach ($app in $config.apps) {
            if ($app.path) {
                Stop-DesktopApp -ExecutablePath $app.path
            }
        }
        
        if ($config.wallpaper.enabled -and $config.wallpaper.desktopMode) {
            Set-Wallpaper -Path $config.wallpaper.desktopMode
        }
    }
    elseif ($Mode -eq "dual") {
        Write-Info "Switching to dual-screen mode" -Component "Switch"
        Set-DesktopIconsVisibility -Visible $true
        
        foreach ($app in $config.apps) {
            if ($app.path) {
                Stop-DesktopApp -ExecutablePath $app.path
            }
        }
        
        if ($config.wallpaper.enabled -and $config.wallpaper.dualMode) {
            Set-Wallpaper -Path $config.wallpaper.dualMode
        }
    }
    
    if ($config.display.showNotifications) {
        $modeName = t ("status.modes." + $Mode)
        $title = t "app.name"
        $message = t -Key "notification.modeChanged" -Args @($modeName)
        Show-Notification -Title $title -Message $message
    }
}

function New-TrayIcon {
    # Assemblies pre-loaded in Main()
    
    $Script:TrayIcon = New-Object System.Windows.Forms.NotifyIcon
    $Script:TrayIcon.Text = t "app.name"
    $Script:TrayIcon.Visible = $true
    
    try {
        $icoPath = Join-Path $Script:ScriptDir "assets\tray.ico"
        if (Test-Path $icoPath) {
            $Script:TrayIcon.Icon = [System.Drawing.Icon]::new($icoPath)
        }
        else {
            $Script:TrayIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\System32\shell32.dll")
        }
    }
    catch {
        $Script:TrayIcon.Icon = [System.Drawing.SystemIcons]::Application
    }
    
    $Script:ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    
    # Status item
    $statusItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $statusItem.Text = Get-StatusText
    $statusItem.Enabled = $false
    [void]$Script:ContextMenu.Items.Add($statusItem)
    [void]$Script:ContextMenu.Items.Add("-")
    
    # Run detection
    $detectItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $detectItem.Text = t "menu.options.runDetection"
    $detectItem.Add_Click({
        $mode = Get-DisplayMode
        Invoke-ModeSwitch -Mode $mode
        Update-TrayMenu
    })
    [void]$Script:ContextMenu.Items.Add($detectItem)
    
    # Force laptop mode
    $laptopItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $laptopItem.Text = t "menu.options.forceLaptop"
    $laptopItem.Add_Click({
        Invoke-ModeSwitch -Mode "laptop"
        Update-TrayMenu
    })
    [void]$Script:ContextMenu.Items.Add($laptopItem)
    
    # Force desktop mode
    $desktopItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $desktopItem.Text = t "menu.options.forceDesktop"
    $desktopItem.Add_Click({
        Invoke-ModeSwitch -Mode "desktop"
        Update-TrayMenu
    })
    [void]$Script:ContextMenu.Items.Add($desktopItem)
    
    [void]$Script:ContextMenu.Items.Add("-")
    
    # Edit config
    $configItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $configItem.Text = t "menu.options.editConfig"
    $configItem.Add_Click({
        $cfgPath = Join-Path $Script:ScriptDir "config.json"
        Start-Process notepad.exe -ArgumentList $cfgPath
    })
    [void]$Script:ContextMenu.Items.Add($configItem)
    
    # View log
    $logItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $logItem.Text = t "menu.options.viewLog"
    $logItem.Add_Click({
        $lp = Get-LogPath
        if (Test-Path $lp) {
            Start-Process notepad.exe -ArgumentList $lp
        }
    })
    [void]$Script:ContextMenu.Items.Add($logItem)
    
    [void]$Script:ContextMenu.Items.Add("-")
    
    # Exit
    $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitItem.Text = t "menu.options.exit"
    $exitItem.Add_Click({
        $Script:Running = $false
        $Script:TrayIcon.Visible = $false
        [System.Windows.Forms.Application]::Exit()
    })
    [void]$Script:ContextMenu.Items.Add($exitItem)
    
    $Script:TrayIcon.ContextMenuStrip = $Script:ContextMenu
    
    # Double-click handler
    $Script:TrayIcon.Add_DoubleClick({
        $mode = Get-DisplayMode
        Invoke-ModeSwitch -Mode $mode
        Update-TrayMenu
    })
}

function Update-TrayMenu {
    if ($Script:ContextMenu -and $Script:ContextMenu.Items.Count -gt 0) {
        $Script:ContextMenu.Items[0].Text = Get-StatusText
    }
}

function Get-StatusText {
    $info = Get-DisplayInfo
    $modeKey = "status.modes." + $info.CurrentMode
    $modeName = t $modeKey
    $modePrefix = t -Key "status.mode" -Args @($modeName)
    $sizeStr = [string]$info.PhysicalSize
    $countStr = [string]$info.MonitorCount
    
    return "$modePrefix | ${sizeStr}in | ${countStr}x"
}

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    if ($Script:TrayIcon) {
        $Script:TrayIcon.ShowBalloonTip(3000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
    }
}

function Main {
    # Single-instance mutex (prevents multiple copies)
    $mutex = New-Object System.Threading.Mutex($false, 'Global\SmartDisplaySwitcher')
    if (-not $mutex.WaitOne(0, $false)) {
        Write-Host 'Smart Display Switcher is already running in the system tray.' -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        return
    }
    
    Initialize-Application
    
    $Script:Running = $true
    
    # Load Windows Forms (MUST be before creating any Forms objects)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $Script:MonitorTimer = New-Object System.Windows.Forms.Timer
    $Script:MonitorTimer.Interval = (Get-Config).monitoring.checkInterval * 1000
    $Script:MonitorTimer.Add_Tick({
        try {
            $currentMode = Get-DisplayMode
            if ($currentMode -ne $Script:LastMode) {
                Write-Info "Mode change: $($Script:LastMode) -> $currentMode" -Component "Monitor"
                Invoke-ModeSwitch -Mode $currentMode
                $Script:LastMode = $currentMode
                Update-TrayMenu
            }
        }
        catch {
            Write-Warn "Monitor error: $($_.Exception.Message)"
        }
    })
    $Script:LastMode = $null
    
    try {
        New-TrayIcon
        
        $Script:MonitorTimer.Start()
        
        $Script:LastMode = Get-DisplayMode
        Write-Info "Initial mode: $($Script:LastMode)" -Component "Monitor"
        
        # Hide console window (tray icon stays in system tray)
        try {
            Add-Type -Name ConsoleWindow -Namespace Win32 -MemberDefinition '
                [DllImport("kernel32.dll")]
                public static extern IntPtr GetConsoleWindow();
                [DllImport("user32.dll")]
                public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            '
            $hwnd = [Win32.ConsoleWindow]::GetConsoleWindow()
            if ($hwnd -ne [IntPtr]::Zero) {
                [Win32.ConsoleWindow]::ShowWindow($hwnd, 0) | Out-Null
            }
        }
        catch { }
        
        if (-not $Minimized) {
            Show-Notification -Title (t "app.name") -Message "Running in system tray"
        }
        
        [System.Windows.Forms.Application]::Run()
    }
    catch {
        Write-Host ""
        Write-Host "Tray icon failed. Running in console mode instead." -ForegroundColor Yellow
        Write-Host "Right-click tray icon or close this window to exit." -ForegroundColor DarkGray
        Write-Host ""
        # Keep running with timer even without tray
        while ($Script:Running) { Start-Sleep -Seconds 2 }
    }
    finally {
        $Script:Running = $false
        
        if ($Script:MonitorTimer) {
            $Script:MonitorTimer.Stop()
            $Script:MonitorTimer.Dispose()
        }
        
        if ($Script:TrayIcon) {
            $Script:TrayIcon.Visible = $false
            $Script:TrayIcon.Dispose()
        }
        
        if ($mutex) { $mutex.ReleaseMutex(); $mutex.Dispose() }
        
        Write-Info "Application exited" -Component "Main"
    }
}

Main

