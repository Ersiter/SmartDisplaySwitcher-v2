<#
.SYNOPSIS
    Generate tray icon for Smart Display Switcher
.DESCRIPTION
    Creates a multi-resolution .ico file with a monitor-switch design.
    Supports 16x16, 32x32, 48x48, and 256x256 sizes.
#>

$outPath = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\tray.ico"
$assetsDir = Split-Path $outPath -Parent
if (-not (Test-Path $assetsDir)) {
    New-Item -Path $assetsDir -ItemType Directory -Force | Out-Null
}

Add-Type -AssemblyName System.Drawing

function New-IconImage([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    
    $pad = [math]::Max(1, $size * 0.08)
    $inner = $size - 2 * $pad
    
    # Monitor body color
    $bodyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 52, 73, 94))
    $accentBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 41, 128, 185))
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 52, 73, 94), [math]::Max(1, $size * 0.04))
    
    # Monitor screen
    $screenX = $pad
    $screenY = $pad
    $screenW = $inner
    $screenH = $inner * 0.72
    $g.FillRectangle($bodyBrush, $screenX, $screenY, $screenW, $screenH)
    
    # Monitor stand base
    $standW = $inner * 0.45
    $standH = $inner * 0.12
    $standX = ($size - $standW) / 2
    $standY = $screenY + $screenH + ($inner * 0.05)
    $g.FillRectangle($bodyBrush, $standX, $standY, $standW, $standH)
    
    # Monitor neck
    $neckW = $inner * 0.08
    $neckH = $inner * 0.1
    $neckX = ($size - $neckW) / 2
    $neckY = $screenY + $screenH
    $g.FillRectangle($bodyBrush, $neckX, $neckY, $neckW, $neckH)
    
    # Switch arrows (circular)
    $cx = $size / 2
    $cy = $screenY + $screenH * 0.45
    $r = $inner * 0.18
    $arrowPen = New-Object System.Drawing.Pen($accentBrush.Color, [math]::Max(1.5, $size * 0.035))
    $arrowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $arrowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
    
    # Draw two curved arrows (sync symbol)
    $arcRect = [System.Drawing.RectangleF]::new($cx - $r, $cy - $r * 0.7, $r * 2, $r * 1.4)
    $g.DrawArc($arrowPen, $arcRect.X, $arcRect.Y, $arcRect.Width, $arcRect.Height, 180, 180)
    
    $arcRect2 = [System.Drawing.RectangleF]::new($cx - $r, $cy - $r * 0.7, $r * 2 - 1, $r * 1.4 - 0)
    $g.DrawArc($arrowPen, $arcRect2.X, $arcRect2.Y, $arcRect2.Width, $arcRect2.Height, 0, 180)
    
    $g.Dispose()
    $bodyBrush.Dispose()
    $accentBrush.Dispose()
    $pen.Dispose()
    $arrowPen.Dispose()
    
    return $bmp
}

# Generate all sizes and pack into .ico
$sizes = @(16, 32, 48, 256)
$bitmaps = $sizes | ForEach-Object { New-IconImage -size $_ }

# Save as .ico
$stream = New-Object System.IO.FileStream($outPath, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter($stream)

# ICO header
$writer.Write([uint16]0)           # Reserved
$writer.Write([uint16]1)           # Type: ICO
$writer.Write([uint16]$sizes.Count) # Image count

# Image directory entries
$imageDataOffset = 6 + 16 * $sizes.Count
$pngData = @()

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $bmp = $bitmaps[$i]
    $sz = $sizes[$i]
    if ($sz -eq 256) { $sz = 0 }  # 256x256 stored as 0
    
    # Save as PNG for size efficiency
    $pngStream = New-Object System.IO.MemoryStream
    $bmp.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $pngStream.ToArray()
    $pngStream.Dispose()
    
    $writer.Write([byte]$sz)       # Width
    $writer.Write([byte]$sz)       # Height
    $writer.Write([byte]0)         # Color palette
    $writer.Write([byte]0)         # Reserved
    $writer.Write([uint16]1)       # Color planes
    $writer.Write([uint16]32)      # Bits per pixel
    $writer.Write([uint32]$pngBytes.Length)  # Image size
    $writer.Write([uint32]$imageDataOffset) # Image offset
    
    $pngData += $pngBytes
    $imageDataOffset += $pngBytes.Length
}

# Write image data
foreach ($data in $pngData) {
    $writer.Write($data)
}

$writer.Dispose()
$stream.Dispose()

# Cleanup bitmaps
$bitmaps | ForEach-Object { $_.Dispose() }

Write-Host "Icon created: $outPath" -ForegroundColor Green
Write-Host "Sizes: $($sizes -join ', ')px" -ForegroundColor Gray
