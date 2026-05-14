<#
.SYNOPSIS
    Configuration Manager Module / 配置管理模块
.DESCRIPTION
    Loads, saves, validates and backs up configuration files.
    Supports migration from legacy v1 config format.
    负责配置文件的加载、保存、验证和备份。支持从 v1 旧版配置迁移。
.NOTES
    Author: Ersiter
    Version: 2.1
#>

# Module state / 模块状态变量
$Script:ConfigPath = $null
$Script:Config = $null
$Script:BackupDir = $null

# Default configuration template / 默认配置模板
$Script:DefaultConfig = @{
    version = "2.0"
    primaryMonitor = @{
        minPhysicalWidth = 24
        dualScreenPrimary = "largest"
    }
    apps = @(
        @{
            name = "EasyDesktop"
            path = ""
            arguments = ""
            enabled = $true
        }
    )
    monitoring = @{
        checkInterval = 10
        idleThreshold = 300
    }
    display = @{
        language = "zh-CN"
        showNotifications = $true
        startMinimized = $false
    }
    wallpaper = @{
        laptopMode = ""
        desktopMode = ""
        dualMode = ""
        enabled = $false
    }
    diagnostics = @{
        enableFallback = $true
        maxValidSize = 100
        logLevel = "INFO"
    }
}

function Initialize-ConfigManager {
    <#
    .SYNOPSIS
        Initialize config system. Load existing or create default.
        初始化配置系统。加载已有配置或创建默认。
    .PARAMETER MigrateOld
        Try to migrate from legacy E:\SmartDisplaySwitcher\config.json
        尝试从旧版 config.json 迁移
    #>
    param(
        [string]$ConfigPath,
        [switch]$MigrateOld
    )
    
    if ($ConfigPath) {
        $Script:ConfigPath = $ConfigPath
    }
    else {
        $Script:ConfigPath = Join-Path $PSScriptRoot "..\config.json"
    }
    
    $configDir = Split-Path $Script:ConfigPath -Parent
    $Script:BackupDir = Join-Path $configDir "backup"
    
    if (-not (Test-Path $Script:BackupDir)) {
        New-Item -Path $Script:BackupDir -ItemType Directory -Force | Out-Null
    }
    
    if ($MigrateOld) {
        $oldConfigPath = "E:\SmartDisplaySwitcher\config.json"
        if (Test-Path $oldConfigPath) {
            Write-Verbose "Found legacy config, migrating..."
            $null = Migrate-OldConfig -OldPath $oldConfigPath
            return
        }
    }
    
    if (Test-Path $Script:ConfigPath) {
        $Script:Config = Load-ConfigFile -Path $Script:ConfigPath
    }
    else {
        Write-Verbose "Config not found, creating default"
        $Script:Config = $Script:DefaultConfig.Clone()
        $null = Save-Config
    }
}

function Load-ConfigFile {
    <#
    .SYNOPSIS
        Load and validate config from JSON file.
        从 JSON 文件加载并验证配置。与默认配置合并确保所有字段存在。
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Warning "Config file not found: $Path"
            return $Script:DefaultConfig.Clone()
        }
        
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        $config = $content | ConvertFrom-Json
        $config = Merge-Configs -Base $Script:DefaultConfig -Override $config
        
        return $config
    }
    catch {
        Write-Warning "Failed to load config: $($_.Exception.Message)"
        return $Script:DefaultConfig.Clone()
    }
}

function Merge-Configs {
    <#
    .SYNOPSIS
        Recursively merge user config over default config.
        递归合并用户配置到默认配置之上。
    #>
    param(
        [hashtable]$Base,
        [object]$Override
    )
    
    $result = $Base.Clone()
    
    if ($Override -is [PSCustomObject]) {
        $overrideHash = @{}
        foreach ($prop in $Override.PSObject.Properties) {
            if ($prop.Value -is [PSCustomObject]) {
                $overrideHash[$prop.Name] = ConvertTo-Hashtable -Object $prop.Value
            }
            else {
                $overrideHash[$prop.Name] = $prop.Value
            }
        }
        $Override = $overrideHash
    }
    
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key)) {
            if ($result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
                $result[$key] = Merge-Configs -Base $result[$key] -Override $Override[$key]
            }
            else {
                $result[$key] = $Override[$key]
            }
        }
        else {
            $result[$key] = $Override[$key]
        }
    }
    
    return $result
}

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Convert a PSCustomObject to a nested hashtable.
        将 PSCustomObject 递归转为嵌套 hashtable。
    #>
    param([object]$Object)
    
    $result = @{}
    foreach ($prop in $Object.PSObject.Properties) {
        if ($prop.Value -is [PSCustomObject]) {
            $result[$prop.Name] = ConvertTo-Hashtable -Object $prop.Value
        }
        elseif ($prop.Value -is [array]) {
            $result[$prop.Name] = @($prop.Value | ForEach-Object {
                if ($_ -is [PSCustomObject]) {
                    ConvertTo-Hashtable -Object $_
                }
                else {
                    $_
                }
            })
        }
        else {
            $result[$prop.Name] = $prop.Value
        }
    }
    return $result
}

function Save-Config {
    <#
    .SYNOPSIS
        Save current config to JSON file (with auto-backup).
        保存当前配置到 JSON 文件（自动备份）。
    #>
    param([string]$Path)
    
    $savePath = if ($Path) { $Path } else { $Script:ConfigPath }
    
    try {
        Backup-Config
        $json = $Script:Config | ConvertTo-Json -Depth 10
        $json | Set-Content -Path $savePath -Encoding UTF8
        Write-Verbose "Config saved: $savePath"
        return $true
    }
    catch {
        Write-Warning "Failed to save config: $($_.Exception.Message)"
        return $false
    }
}

function Backup-Config {
    <#
    .SYNOPSIS
        Create daily config backup. Keeps last 30 days.
        创建每日配置备份。保留最近 30 天。
    #>
    if (-not (Test-Path $Script:ConfigPath)) { return }
    
    try {
        $dateStr = Get-Date -Format "yyyyMMdd"
        $backupFile = Join-Path $Script:BackupDir "config_$dateStr.json"
        
        if (-not (Test-Path $backupFile)) {
            Copy-Item -Path $Script:ConfigPath -Destination $backupFile -Force
        }
        
        $cutoffDate = (Get-Date).AddDays(-30)
        Get-ChildItem -Path $Script:BackupDir -Filter "config_*.json" | 
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Backup failed: $($_.Exception.Message)"
    }
}

function Migrate-OldConfig {
    <#
    .SYNOPSIS
        Migrate configuration from legacy v1 format.
        从 v1 旧版配置格式迁移。仅供内部使用。
    #>
    param(
        [Parameter(Mandatory)]
        [string]$OldPath
    )
    
    try {
        $oldConfig = Get-Content -Path $OldPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        $Script:Config = $Script:DefaultConfig.Clone()
        
        if ($oldConfig.primaryMonitor) {
            $Script:Config.primaryMonitor.minPhysicalWidth = $oldConfig.primaryMonitor.minPhysicalWidth
        }
        
        if ($oldConfig.easyDesktop -and $oldConfig.easyDesktop.path) {
            $Script:Config.apps[0].path = $oldConfig.easyDesktop.path
        }
        
        if ($oldConfig.monitoring) {
            $Script:Config.monitoring.checkInterval = $oldConfig.monitoring.checkInterval
        }
        
        if ($oldConfig.diagnostics) {
            $Script:Config.diagnostics.enableFallback = $oldConfig.diagnostics.enableFallback
            $Script:Config.diagnostics.maxValidSize = $oldConfig.diagnostics.maxValidSize
        }
        
        $null = Save-Config
        Write-Verbose "Config migration successful"
        return $true
    }
    catch {
        Write-Warning "Config migration failed: $($_.Exception.Message)"
        $Script:Config = $Script:DefaultConfig.Clone()
        $null = Save-Config
        return $false
    }
}

function Get-Config {
    <# Return current config object. / 返回当前配置对象。 #>
    return $Script:Config
}

function Get-ConfigValue {
    <#
    .SYNOPSIS
        Get a config value by dot-path. / 通过点号路径获取配置值。
    .EXAMPLE
        Get-ConfigValue "primaryMonitor.minPhysicalWidth"
    #>
    param([Parameter(Mandatory)][string]$Path, [object]$Default = $null)
    
    try {
        $parts = $Path -split '\.'
        $value = $Script:Config
        
        foreach ($part in $parts) {
            if ($value -is [hashtable]) { $value = $value[$part] }
            else { $value = $value.$part }
            if ($null -eq $value) { return $Default }
        }
        return $value
    }
    catch { return $Default }
}

function Set-ConfigValue {
    <#
    .SYNOPSIS
        Set a config value by dot-path. / 通过点号路径设置配置值。
    .EXAMPLE
        Set-ConfigValue "display.language" "en-US"
    #>
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
    
    try {
        $parts = $Path -split '\.'
        $target = $Script:Config
        
        for ($i = 0; $i -lt $parts.Count - 1; $i++) {
            if ($target -is [hashtable]) { $target = $target[$parts[$i]] }
            else { $target = $target.$($parts[$i]) }
        }
        
        $last = $parts[-1]
        if ($target -is [hashtable]) { $target[$last] = $Value }
        else { $target.$last = $Value }
        return $true
    }
    catch {
        Write-Warning "Set-ConfigValue failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function @(
    'Initialize-ConfigManager',
    'Get-Config',
    'Get-ConfigValue',
    'Set-ConfigValue',
    'Save-Config',
    'Backup-Config'
)
