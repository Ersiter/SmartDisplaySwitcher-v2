<#
.SYNOPSIS
    Internationalization Module / 鍥介檯鍖栨ā鍧?.DESCRIPTION
    Multi-language support with JSON language files.
    鍩轰簬 JSON 璇█鏂囦欢鐨勫璇█鏀寔銆傝繍琛屾椂鍒囨崲銆?.NOTES
    Author: Ersiter
    Version: 2.1
#>

# Module variables / 妯″潡鍙橀噺
$Script:CurrentLang = "zh-CN"
$Script:LangData = @{}
$Script:LangDir = $null

function Initialize-I18n {
    <#
    .SYNOPSIS
        Initialize i18n with language directory and default language.
        鍒濆鍖栧浗闄呭寲妯″潡锛岃缃瑷€鐩綍鍜岄粯璁よ瑷€銆?    #>
    param(
        [string]$LangDir,
        [string]$DefaultLang = "zh-CN"
    )
    
    $Script:LangDir = if ($LangDir) { $LangDir } else { Join-Path $PSScriptRoot "..\lang" }
    $Script:CurrentLang = $DefaultLang
    
    Load-Language -LangCode $Script:CurrentLang
}

function Load-Language {
    <#
    .SYNOPSIS
        Load a language pack from JSON file.
        浠?JSON 鏂囦欢鍔犺浇璇█鍖呫€?    .PARAMETER LangCode
        Language code (e.g. zh-CN, en-US) / 璇█浠ｇ爜
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LangCode
    )
    
    $langFile = Join-Path $Script:LangDir "$LangCode.json"
    
    if (Test-Path $langFile) {
        try {
            $Script:LangData = Get-Content -Path $langFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $Script:CurrentLang = $LangCode
            Write-Verbose "Language loaded / 璇█宸插姞杞? $LangCode"
        }
        catch {
            Write-Warning "Failed to load language file / 鍔犺浇璇█鏂囦欢澶辫触: $langFile"
        }
    }
    else {
        Write-Warning "Language file not found / 璇█鏂囦欢涓嶅瓨鍦? $langFile"
    }
}

function Set-Language {
    <#
    .SYNOPSIS
        Switch the current language at runtime.
        杩愯鏃跺垏鎹㈠綋鍓嶈瑷€銆?    .PARAMETER LangCode
        Target language code / 鐩爣璇█浠ｇ爜
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LangCode
    )
    
    Load-Language -LangCode $LangCode
}

function Get-CurrentLanguage {
    <#
    .SYNOPSIS
        Get the active language code.
        鑾峰彇褰撳墠璇█浠ｇ爜銆?    #>
    return $Script:CurrentLang
}

# Short alias / 绠€鍐欏埆鍚?鈥?primary API
function t {
    <#
    .SYNOPSIS
        Translate a key. Supports dot-path nesting and format arguments.
        缈昏瘧鎸囧畾鐨勯敭銆傛敮鎸佺偣鍙疯矾寰勫祵濂楀拰鏍煎紡鍖栧弬鏁般€?    .PARAMETER Key
        Translation key (e.g. "menu.title") / 缈昏瘧閿?    .PARAMETER Args
        Format arguments / 鏍煎紡鍖栧弬鏁版暟缁?    .EXAMPLE
        t "menu.title"
        t "status.mode" -Args @("laptop")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        [array]$Args = @()
    )
    
    try {
        # Walk dot-path / 瑙ｆ瀽鐐瑰彿璺緞
        $parts = $Key -split '\.'
        $value = $Script:LangData
        
        foreach ($part in $parts) {
            if ($value -is [PSCustomObject]) {
                $value = $value.$part
            }
            elseif ($value -is [hashtable]) {
                $value = $value[$part]
            }
            else {
                return $Key
            }
            
            if ($null -eq $value) {
                return $Key
            }
        }
        
        # Format if string with args / 鏍煎紡鍖栧瓧绗︿覆
        if ($value -is [string] -and $Args.Count -gt 0) {
            return [string]::Format($value, $Args)
        }
        
        return $value
    }
    catch {
        return $Key
    }
}

function Get-Translation {
    <#
    .SYNOPSIS
        Full-name alias of t() for readability.
        t() 鐨勫畬鏁村悕绉扮増鏈紝鍙鎬ф洿濂姐€?    #>
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        [array]$Args = @()
    )
    
    return t -Key $Key -Args $Args
}

function Get-AvailableLanguages {
    <#
    .SYNOPSIS
        List all available language codes.
        鍒楀嚭鎵€鏈夊彲鐢ㄧ殑璇█浠ｇ爜銆?    .OUTPUTS
        string[] - Language codes
    #>
    if (Test-Path $Script:LangDir) {
        return Get-ChildItem -Path $Script:LangDir -Filter "*.json" | 
            ForEach-Object { $_.BaseName }
    }
    
    return @("zh-CN", "en-US")
}

Export-ModuleMember -Function @(
    'Initialize-I18n',
    'Set-Language',
    'Get-CurrentLanguage',
    't',
    'Get-Translation',
    'Get-AvailableLanguages'
)

