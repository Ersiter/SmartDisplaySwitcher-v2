<#
.SYNOPSIS
    Logger Module / 日志模块
.DESCRIPTION
    Unified logging with levels, file rotation, and console output.
    统一日志系统，支持多级别、文件轮转和彩色控制台输出。
.NOTES
    Author: Ersiter
    Version: 2.1
#>

# Log levels / 日志级别
enum LogLevel {
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    FATAL = 4
}

# Module state / 模块状态变量
$Script:LogPath = $null
$Script:MinLevel = [LogLevel]::INFO
$Script:MaxLogSizeMB = 10
$Script:BackupDir = $null
$Script:ConsoleOutput = $true

# Console colors per level / 各级别控制台颜色
$Script:LevelColors = @{
    [LogLevel]::DEBUG = "DarkGray"
    [LogLevel]::INFO  = "Gray"
    [LogLevel]::WARN  = "Yellow"
    [LogLevel]::ERROR = "Red"
    [LogLevel]::FATAL = "Magenta"
}

function Initialize-Logger {
    <#
    .SYNOPSIS
        Initialize the logger with paths and settings.
        初始化日志系统，设置日志路径、级别和输出选项。
    #>
    param(
        [string]$LogPath,
        [LogLevel]$MinLevel = [LogLevel]::INFO,
        [int]$MaxLogSizeMB = 10,
        [string]$BackupDir,
        [bool]$ConsoleOutput = $true
    )
    
    $Script:LogPath = if ($LogPath) { $LogPath } else { "$env:TEMP\SmartDisplaySwitcher.log" }
    $Script:MinLevel = $MinLevel
    $Script:MaxLogSizeMB = $MaxLogSizeMB
    $Script:ConsoleOutput = $ConsoleOutput
    
    if ($BackupDir) {
        $Script:BackupDir = $BackupDir
    }
    else {
        $Script:BackupDir = Split-Path $Script:LogPath -Parent
    }
    
    $logDir = Split-Path $Script:LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Rotate-LogIfNeeded
}

function Write-LogMessage {
    <#
    .SYNOPSIS
        Core logging function. Write a message with level and optional component tag.
        核心日志函数。写入带级别和可选组件标签的消息。
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [LogLevel]$Level = [LogLevel]::INFO,
        [string]$Component = ""
    )
    
    if ($Level -lt $Script:MinLevel) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $levelStr = $Level.ToString().PadRight(5)
    $componentStr = if ($Component) { " [$Component]" } else { "" }
    $logEntry = "[$timestamp] [$levelStr]$componentStr $Message"
    
    try {
        $logEntry | Out-File -FilePath $Script:LogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($Script:ConsoleOutput) {
        $color = $Script:LevelColors[$Level]
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Write-Debug {
    <# Write DEBUG level log. / 写入 DEBUG 级别日志。 #>
    param([string]$Message, [string]$Component = "")
    Write-LogMessage -Message $Message -Level ([LogLevel]::DEBUG) -Component $Component
}

function Write-Info {
    <# Write INFO level log. / 写入 INFO 级别日志。 #>
    param([string]$Message, [string]$Component = "")
    Write-LogMessage -Message $Message -Level ([LogLevel]::INFO) -Component $Component
}

function Write-Warn {
    <# Write WARN level log. / 写入 WARN 级别日志。 #>
    param([string]$Message, [string]$Component = "")
    Write-LogMessage -Message $Message -Level ([LogLevel]::WARN) -Component $Component
}

function Write-LogError {
    <# Write ERROR level log. / 写入 ERROR 级别日志。(Named LogError to avoid conflict with built-in Write-Error) #>
    param([string]$Message, [string]$Component = "")
    Write-LogMessage -Message $Message -Level ([LogLevel]::ERROR) -Component $Component
}

function Write-Fatal {
    <# Write FATAL level log. / 写入 FATAL 级别日志。 #>
    param([string]$Message, [string]$Component = "")
    Write-LogMessage -Message $Message -Level ([LogLevel]::FATAL) -Component $Component
}

function Rotate-LogIfNeeded {
    <#
    .SYNOPSIS
        Rotate log file if it exceeds max size (compress old, start fresh).
        日志文件超过最大大小时压缩归档并清空。
    #>
    if (-not (Test-Path $Script:LogPath)) { return }
    
    try {
        $logFile = Get-Item $Script:LogPath
        $sizeMB = $logFile.Length / 1MB
        
        if ($sizeMB -ge $Script:MaxLogSizeMB) {
            $dateStr = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupFile = Join-Path $Script:BackupDir "log_$dateStr.zip"
            
            if (-not (Test-Path $Script:BackupDir)) {
                New-Item -Path $Script:BackupDir -ItemType Directory -Force | Out-Null
            }
            
            Compress-Archive -Path $Script:LogPath -DestinationPath $backupFile -Force
            Clear-Content -Path $Script:LogPath
            
            Write-Verbose "Log rotated: $backupFile"
            Cleanup-OldLogs
        }
    }
    catch {
        Write-Verbose "Log rotation failed: $($_.Exception.Message)"
    }
}

function Cleanup-OldLogs {
    <#
    .SYNOPSIS
        Remove log backups older than 30 days.
        清理 30 天前的日志备份。
    #>
    if (-not (Test-Path $Script:BackupDir)) { return }
    
    try {
        $cutoffDate = (Get-Date).AddDays(-30)
        
        Get-ChildItem -Path $Script:BackupDir -Filter "log_*.zip" | 
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch { }
}

function Get-LogPath {
    <# Return current log file path. / 返回当前日志文件路径。 #>
    return $Script:LogPath
}

function Clear-Log {
    <# Clear the log file. / 清空日志文件。 #>
    if (Test-Path $Script:LogPath) {
        Clear-Content -Path $Script:LogPath -ErrorAction SilentlyContinue
    }
}

function Set-LogLevel {
    <# Set minimum log level. / 设置最低日志级别。 #>
    param([Parameter(Mandatory)][LogLevel]$Level)
    $Script:MinLevel = $Level
}

Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-LogMessage',
    'Write-Debug',
    'Write-Info',
    'Write-Warn',
    'Write-LogError',
    'Write-Fatal',
    'Get-LogPath',
    'Clear-Log',
    'Set-LogLevel'
)
