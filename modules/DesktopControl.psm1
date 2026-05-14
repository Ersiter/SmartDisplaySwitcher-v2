<#
.SYNOPSIS
    Desktop Icon Control Module
.DESCRIPTION
    Controls desktop icon visibility via registry.
    Restarts Explorer to apply changes (required for Nodesktop policy).
.NOTES
    Author: Ersiter
    Version: 2.1
#>

function Set-DesktopIconsVisibility {
    param(
        [Parameter(Mandatory)]
        [bool]$Visible,
        [switch]$Force
    )
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $regName = "Nodesktop"
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    $targetValue = if ($Visible) { 0 } else { 1 }
    
    $currentValue = $null
    try {
        $currentValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
    }
    catch { }
    
    if (-not $Force -and $currentValue -eq $targetValue) {
        Write-Verbose "Desktop icons already in target state"
        return $false
    }
    
    Set-ItemProperty -Path $regPath -Name $regName -Value $targetValue -Force
    
    # Restart Explorer to apply the Nodesktop policy change
    # WM_SETTINGCHANGE is NOT sufficient for this registry key
    Restart-ExplorerProcess
    
    Write-Verbose "Desktop icons set to: Visible=$Visible"
    return $true
}

function Get-DesktopIconsVisibility {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $regName = "Nodesktop"
    
    try {
        $value = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop).$regName
        return ($value -ne 1)
    }
    catch {
        return $true
    }
}

function Restart-ExplorerProcess {
    try {
        $explorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        
        if ($explorerProcesses) {
            $explorerProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
            Start-Process -FilePath "explorer.exe" -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 300
            Write-Verbose "Explorer restarted"
        }
        else {
            Start-Process -FilePath "explorer.exe" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "Failed to restart Explorer: $($_.Exception.Message)"
    }
}

function Set-Wallpaper {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Wallpaper not found: $Path"
        return $false
    }
    
    try {
        $code = @'
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    
    public const int SPI_SETDESKWALLPAPER = 0x0014;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;
    
    public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
'@
        Add-Type -TypeDefinition $code -ErrorAction Stop
        [Wallpaper]::Set($Path)
        Write-Verbose "Wallpaper set: $Path"
        return $true
    }
    catch {
        Write-Warning "Failed to set wallpaper: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function @(
    'Set-DesktopIconsVisibility',
    'Get-DesktopIconsVisibility',
    'Restart-ExplorerProcess',
    'Set-Wallpaper'
)

