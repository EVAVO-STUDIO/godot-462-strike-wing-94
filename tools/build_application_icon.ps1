[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceCraft = Join-Path $Root 'assets/runtime/craft/vx94/vx94_fighter_v1.png'
$Output = Join-Path $Root 'assets/runtime/brand/hypersonic_application_icon.png'
$OutputDirectory = Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Add-Type -AssemblyName System.Drawing
$Canvas = [System.Drawing.Bitmap]::new(256,256,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$Graphics = [System.Drawing.Graphics]::FromImage($Canvas)
$Graphics.Clear([System.Drawing.Color]::Transparent)
$Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

$Outer = [System.Drawing.Point[]]@(
    [System.Drawing.Point]::new(68,8), [System.Drawing.Point]::new(188,8),
    [System.Drawing.Point]::new(248,68), [System.Drawing.Point]::new(248,188),
    [System.Drawing.Point]::new(188,248), [System.Drawing.Point]::new(68,248),
    [System.Drawing.Point]::new(8,188), [System.Drawing.Point]::new(8,68)
)
$Inner = [System.Drawing.Point[]]@(
    [System.Drawing.Point]::new(73,18), [System.Drawing.Point]::new(183,18),
    [System.Drawing.Point]::new(238,73), [System.Drawing.Point]::new(238,183),
    [System.Drawing.Point]::new(183,238), [System.Drawing.Point]::new(73,238),
    [System.Drawing.Point]::new(18,183), [System.Drawing.Point]::new(18,73)
)
$Graphics.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,8,18,27))),$Outer)
$Graphics.DrawPolygon((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,169,194,204),6)),$Outer)
$Graphics.DrawPolygon((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,45,79,96),4)),$Inner)

$Graphics.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,204,50,30))),[System.Drawing.Point[]]@(
    [System.Drawing.Point]::new(25,177), [System.Drawing.Point]::new(231,54),
    [System.Drawing.Point]::new(231,72), [System.Drawing.Point]::new(25,195)
))
$Graphics.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,237,192,68))),[System.Drawing.Point[]]@(
    [System.Drawing.Point]::new(25,198), [System.Drawing.Point]::new(231,75),
    [System.Drawing.Point]::new(231,82), [System.Drawing.Point]::new(25,205)
))

$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,226,235,232))),42,47,54,13)
$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,226,235,232))),42,47,13,52)
$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,226,235,232))),83,47,13,52)
$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,226,235,232))),42,80,54,13)

$Craft = [System.Drawing.Image]::FromFile($SourceCraft)
$CraftWidth = 118
$CraftHeight = [int][Math]::Round($Craft.Height * ($CraftWidth / [double]$Craft.Width))
$CraftX = [int][Math]::Round((256 - $CraftWidth) / 2.0)
$CraftY = 48
$Graphics.DrawImage($Craft,[System.Drawing.Rectangle]::new($CraftX,$CraftY,$CraftWidth,$CraftHeight),0,0,$Craft.Width,$Craft.Height,[System.Drawing.GraphicsUnit]::Pixel)

$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,226,235,232))),61,222,134,5)
$Graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,204,50,30))),103,232,50,5)

$Canvas.Save($Output,[System.Drawing.Imaging.ImageFormat]::Png)
$Craft.Dispose()
$Graphics.Dispose()
$Canvas.Dispose()
Write-Host "HYPERSONIC application icon built: $Output" -ForegroundColor Green
