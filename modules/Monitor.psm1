<#
.SYNOPSIS
    Monitor Detection Module / 鏄剧ず鍣ㄦ娴嬫ā鍧?.DESCRIPTION
    Detects monitor count and physical size via WMI and P/Invoke.
    閫氳繃 WMI 鍜?P/Invoke 鍙岄噸鏂规妫€娴嬫樉绀哄櫒鏁伴噺鍜岀墿鐞嗗昂瀵搞€?.NOTES
    Author: Ersiter
    Version: 2.1
#>

# Module-level config / 妯″潡绾ч厤缃?$Script:Config = $null

function Initialize-MonitorModule {
    <#
    .SYNOPSIS
        Initialize the monitor module with app config.
        鐢ㄥ簲鐢ㄩ厤缃垵濮嬪寲鏄剧ず鍣ㄦ娴嬫ā鍧椼€?    #>
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )
    $Script:Config = $Config
}

function Get-MonitorCount {
    <#
    .SYNOPSIS
        Get the number of active monitors.
        鑾峰彇褰撳墠娲昏穬鐨勬樉绀哄櫒鏁伴噺銆?    .OUTPUTS
        int - Active monitor count, minimum 1
    #>
    try {
        $monitors = Get-WmiObject -Namespace "root\wmi" -Class "WmiMonitorBasicDisplayParams" -ErrorAction Stop
        $activeCount = @($monitors | Where-Object { $_.Active }).Count
        return [Math]::Max($activeCount, 1)
    }
    catch {
        Write-Verbose "Get-MonitorCount failed / 鑾峰彇鏄剧ず鍣ㄦ暟閲忓け璐? $($_.Exception.Message)"
        return 1
    }
}

function Get-MonitorPhysicalSize {
    <#
    .SYNOPSIS
        Get the physical size (diagonal, in inches) of the primary monitor.
        鑾峰彇涓绘樉绀哄櫒鐨勭墿鐞嗗昂瀵革紙瀵硅绾匡紝鍗曚綅鑻卞锛夈€?    .DESCRIPTION
        Prefers WMI (from EDID data), falls back to P/Invoke (GDI HORZSIZE/VERTSIZE).
        浼樺厛浣跨敤 WMI锛堟潵鑷?EDID锛夛紝澶辫触鏃跺洖閫€鍒?GDI 鐗╃悊姣背鏁版柟妗堬紙涓嶅彈绯荤粺缂╂斁褰卞搷锛夈€?    .OUTPUTS
        double - Diagonal size in inches
    #>
    
    # WMI detection / WMI 妫€娴?    $wmiResult = Get-MonitorSize-WMI
    if ($wmiResult -gt 0) {
        return $wmiResult
    }
    
    # P/Invoke fallback / P/Invoke 鍥為€€鏂规
    if ($Script:Config.diagnostics.enableFallback) {
        $fallbackResult = Get-MonitorSize-Fallback
        if ($fallbackResult -gt 0) {
            return $fallbackResult
        }
    }
    
    # Default fallback / 榛樿鍥為€€鍊?    Write-Warning "Monitor detection failed, using default 15.6 inch / 妫€娴嬪け璐ワ紝浣跨敤榛樿鍊?15.6 鑻卞"
    return 15.6
}

function Get-MonitorSize-WMI {
    <#
    .SYNOPSIS
        Get physical size via WMI (WmiMonitorBasicDisplayParams).
        閫氳繃 WMI 鑾峰彇鏄剧ず鍣ㄧ墿鐞嗗昂瀵搞€?    .DESCRIPTION
        Converts centimeters to inches using EDID MaxHorizontalImageSize / MaxVerticalImageSize.
        灏?EDID 涓殑鍘樼背鍊艰浆鎹负鑻卞銆?    .OUTPUTS
        double - Size in inches, or 0 on failure
    #>
    try {
        $monitors = Get-WmiObject -Namespace "root\wmi" -Class "WmiMonitorBasicDisplayParams" -ErrorAction Stop
        
        if ($monitors) {
            foreach ($monitor in @($monitors)) {
                if ($monitor.Active) {
                    # Convert cm to inches / 鍘樼背杞嫳瀵?                    $widthInches = $monitor.MaxHorizontalImageSize * 0.393701
                    $heightInches = $monitor.MaxVerticalImageSize * 0.393701
                    
                    # Calculate diagonal / 璁＄畻瀵硅绾?                    $diagonalSize = [Math]::Sqrt($widthInches * $widthInches + $heightInches * $heightInches)
                    $diagonalSize = [Math]::Round($diagonalSize, 1)
                    
                    # Validate reasonable range / 楠岃瘉鍚堢悊鑼冨洿
                    if ($diagonalSize -gt 5 -and $diagonalSize -le $Script:Config.diagnostics.maxValidSize) {
                        return $diagonalSize
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "WMI detection failed / WMI 妫€娴嬪け璐? $($_.Exception.Message)"
    }
    
    return 0
}

function Get-MonitorSize-Fallback {
    <#
    .SYNOPSIS
        Get physical size via GDI (HORZSIZE/VERTSIZE from EDID).
        閫氳繃 GDI 鐨?HORZSIZE/VERTSIZE 甯搁噺鑾峰彇 EDID 鐗╃悊灏哄銆?    .DESCRIPTION
        Uses HORZSIZE(4) and VERTSIZE(6) which return physical mm from EDID,
        unaffected by Windows DPI scaling. Unlike the LOGPIXELSX approach which
        gets skewed by 125%/150% display scaling.
        浣跨敤 HORZSIZE(4) 鍜?VERTSIZE(6) 璇诲彇 EDID 鐗╃悊姣背鏁帮紝
        涓嶅彈 Windows DPI 缂╂斁褰卞搷锛岄伩鍏嶄簡 LOGPIXELSX 鏂规鍦?150% 缂╂斁涓嬬殑璇樊銆?    .OUTPUTS
        double - Size in inches, or 0 on failure
    #>
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class MonitorInfoHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hwnd);
    
    [DllImport("gdi32.dll")]
    public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
    
    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    
    // Physical width/height in mm from EDID / EDID 鐗╃悊姣背鏁?    private const int HORZSIZE = 4;
    private const int VERTSIZE = 6;
    
    public static float GetPhysicalSize() {
        IntPtr dc = GetDC(IntPtr.Zero);
        if (dc == IntPtr.Zero) return 0;
        
        try {
            int widthMm = GetDeviceCaps(dc, HORZSIZE);
            int heightMm = GetDeviceCaps(dc, VERTSIZE);
            
            if (widthMm <= 0 || heightMm <= 0) return 0;
            
            // mm to inches / 姣背杞嫳瀵?            float widthInches = widthMm / 25.4f;
            float heightInches = heightMm / 25.4f;
            
            // Diagonal / 瀵硅绾?            return (float)Math.Sqrt(widthInches * widthInches + heightInches * heightInches);
        }
        finally {
            ReleaseDC(IntPtr.Zero, dc);
        }
    }
}
"@ -ErrorAction Stop
        
        $size = [MonitorInfoHelper]::GetPhysicalSize()
        $size = [Math]::Round($size, 1)
        
        if ($size -gt 5 -and $size -le $Script:Config.diagnostics.maxValidSize) {
            return $size
        }
    }
    catch {
        Write-Verbose "P/Invoke fallback failed / P/Invoke 鍥為€€澶辫触: $($_.Exception.Message)"
    }
    
    return 0
}

function Get-DisplayMode {
    <#
    .SYNOPSIS
        Determine the current display mode based on monitor config.
        鏍规嵁鏄剧ず鍣ㄩ厤缃垽鏂綋鍓嶆ā寮忋€?    .DESCRIPTION
        Modes / 妯″紡:
          "dual"    - 2+ monitors connected / 鍙屽睆鎴栧灞?          "laptop"  - Small screen (below minPhysicalWidth) / 灏忓睆骞曪紙绗旇鏈級
          "desktop" - Large screen (above minPhysicalWidth) / 澶у睆骞曪紙妗岄潰锛?    .OUTPUTS
        string - "dual", "laptop", or "desktop"
    #>
    $monitorCount = Get-MonitorCount
    $physicalSize = Get-MonitorPhysicalSize
    $minWidth = $Script:Config.primaryMonitor.minPhysicalWidth
    
    # Dual screen has priority / 鍙屽睆浼樺厛鍒ゆ柇
    if ($monitorCount -ge 2) {
        return "dual"
    }
    
    # Single screen: size-based / 鍗曞睆锛氭寜灏哄鍒ゆ柇
    if ($physicalSize -lt $minWidth) {
        return "laptop"
    }
    else {
        return "desktop"
    }
}

function Get-DisplayInfo {
    <#
    .SYNOPSIS
        Get complete display information as a hashtable.
        鑾峰彇瀹屾暣鐨勬樉绀哄櫒淇℃伅锛屼互鍝堝笇琛ㄥ舰寮忚繑鍥炪€?    .OUTPUTS
        hashtable - Keys: MonitorCount, PhysicalSize, CurrentMode, IsLaptop, IsDesktop, IsDualScreen
    #>
    $count = Get-MonitorCount
    $size = Get-MonitorPhysicalSize
    $mode = Get-DisplayMode
    
    return @{
        MonitorCount = $count
        PhysicalSize = $size
        CurrentMode = $mode
        IsLaptop = ($mode -eq "laptop")
        IsDesktop = ($mode -eq "desktop")
        IsDualScreen = ($mode -eq "dual")
    }
}

Export-ModuleMember -Function @(
    'Initialize-MonitorModule',
    'Get-MonitorCount',
    'Get-MonitorPhysicalSize',
    'Get-DisplayMode',
    'Get-DisplayInfo'
)

