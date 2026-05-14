<#
.SYNOPSIS
    Process Manager Module
.DESCRIPTION
    Manages third-party desktop applications
.NOTES
    Author: Ersiter
    Version: 2.1
#>

function Test-ProcessRunning {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName,
        [string]$ExecutablePath
    )
    
    try {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        
        if (-not $processes) {
            return $false
        }
        
        if ($ExecutablePath -and (Test-Path $ExecutablePath)) {
            $normalizedPath = (Resolve-Path $ExecutablePath).Path.ToLower()
            
            foreach ($proc in $processes) {
                try {
                    $procPath = $proc.MainModule.FileName.ToLower()
                    if ($procPath -eq $normalizedPath) {
                        return $true
                    }
                }
                catch { }
            }
            return $false
        }
        
        return $true
    }
    catch {
        Write-Verbose "Process check failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-ProcessInfo {
    param(
        [Parameter(Mandatory)]
        [string]$ProcessName
    )
    
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($process) {
            return @{
                Running = $true
                PID = $process.Id
                Name = $process.ProcessName
                StartTime = $process.StartTime
                MemoryMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
            }
        }
    }
    catch { }
    
    return @{ Running = $false }
}

function Start-DesktopApp {
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        [string]$Arguments = ""
    )
    
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        Write-Warning "App path is empty"
        return $false
    }
    
    $cleanPath = $ExecutablePath.Trim('"')
    if (-not (Test-Path $cleanPath -PathType Leaf)) {
        Write-Warning "App not found: $cleanPath"
        return $false
    }
    
    $processName = [System.IO.Path]::GetFileNameWithoutExtension($cleanPath)
    
    if (Test-ProcessRunning -ProcessName $processName -ExecutablePath $cleanPath) {
        Write-Verbose "$processName already running"
        return $true
    }
    
    try {
        $startParams = @{
            FilePath = $cleanPath
            PassThru = $true
            ErrorAction = "Stop"
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Arguments)) {
            $startParams.ArgumentList = $Arguments
        }
        
        $newProcess = Start-Process @startParams
        Start-Sleep -Milliseconds 800
        
        if (Test-ProcessRunning -ProcessName $processName) {
            Write-Verbose "$processName started (PID: $($newProcess.Id))"
            return $true
        }
        else {
            Write-Warning "$processName exited immediately"
            return $false
        }
    }
    catch {
        Write-Warning "Failed to start $processName`: $($_.Exception.Message)"
        return $false
    }
}

function Stop-DesktopApp {
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        [int]$TimeoutSeconds = 5
    )
    
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        return $true
    }
    
    $cleanPath = $ExecutablePath.Trim('"')
    $processName = [System.IO.Path]::GetFileNameWithoutExtension($cleanPath)
    
    if (-not (Test-ProcessRunning -ProcessName $processName)) {
        Write-Verbose "$processName not running"
        return $true
    }
    
    try {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        
        if ($processes) {
            foreach ($proc in $processes) {
                try {
                    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
                        $proc.CloseMainWindow() | Out-Null
                    }
                }
                catch { }
            }
            
            $waited = 0
            while ($waited -lt $TimeoutSeconds) {
                Start-Sleep -Milliseconds 500
                $waited += 0.5
                
                if (-not (Test-ProcessRunning -ProcessName $processName)) {
                    Write-Verbose "$processName closed gracefully"
                    return $true
                }
            }
            
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Verbose "$processName force stopped"
        }
        
        return $true
    }
    catch {
        Write-Warning "Failed to stop $processName`: $($_.Exception.Message)"
        return $false
    }
}

function Restart-DesktopApp {
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        [string]$Arguments = ""
    )
    
    Stop-DesktopApp -ExecutablePath $ExecutablePath
    Start-Sleep -Milliseconds 300
    return Start-DesktopApp -ExecutablePath $ExecutablePath -Arguments $Arguments
}

Export-ModuleMember -Function @(
    'Test-ProcessRunning',
    'Get-ProcessInfo',
    'Start-DesktopApp',
    'Stop-DesktopApp',
    'Restart-DesktopApp'
)

