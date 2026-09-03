[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$OutputRoot = Join-Path $Root 'assets/runtime/enemies/hypersonic_pursuit'
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$Families = @(
    @{ Id='ace_interceptor'; Source='assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png'; Core=4; WingTop=5; WingBottom=20; Inset=6; Aft=6 },
    @{ Id='drone_hunter'; Source='assets/runtime/enemies/machine_air/drone_hunter_idle.png'; Core=3; WingTop=5; WingBottom=20; Inset=5; Aft=5 },
    @{ Id='phase_interceptor'; Source='assets/runtime/enemies/orbital_air/phase_interceptor_idle.png'; Core=2; WingTop=2; WingBottom=23; Inset=3; Aft=7 }
)

function Set-StrongestPixel {
    param([System.Drawing.Bitmap]$Image, [int]$X, [int]$Y, [System.Drawing.Color]$Color)
    if ($X -lt 0 -or $Y -lt 0 -or $X -ge $Image.Width -or $Y -ge $Image.Height) { return }
    $Existing = $Image.GetPixel($X,$Y)
    if ($Color.A -ge $Existing.A) { $Image.SetPixel($X,$Y,$Color) }
}

foreach ($Family in $Families) {
    $SourcePath = Join-Path $Root $Family.Source
    $Source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $FamilyOutput = Join-Path $OutputRoot $Family.Id
    New-Item -ItemType Directory -Force -Path $FamilyOutput | Out-Null
    $CenterX = ($Source.Width - 1) / 2.0

    for ($Frame = 0; $Frame -lt 10; $Frame++) {
        $Ratio = $Frame / 9.0
        $Ease = $Ratio * $Ratio * (3.0 - 2.0 * $Ratio)
        $Output = New-Object System.Drawing.Bitmap($Source.Width,$Source.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for ($Y = 0; $Y -lt $Source.Height; $Y++) {
            for ($X = 0; $X -lt $Source.Width; $X++) {
                $Pixel = $Source.GetPixel($X,$Y)
                if ($Pixel.A -eq 0) { continue }
                $Distance = [Math]::Abs($X - $CenterX)
                $WingBand = $Y -ge $Family.WingTop -and $Y -le $Family.WingBottom
                if ($WingBand -and $Distance -gt $Family.Core) {
                    $Side = if ($X -lt $CenterX) { -1.0 } else { 1.0 }
                    $Outer = [Math]::Min(1.0, ($Distance - $Family.Core) / [Math]::Max(1.0,$CenterX - $Family.Core))
                    $NewX = [Math]::Round($X - $Side * $Family.Inset * $Ease * (0.42 + 0.58 * $Outer))
                    $NewY = [Math]::Round($Y + $Family.Aft * $Ease * (0.35 + 0.65 * $Outer))
                    Set-StrongestPixel $Output $NewX $NewY $Pixel
                } else {
                    Set-StrongestPixel $Output $X $Y $Pixel
                }
            }
        }
        $Output.Save((Join-Path $FamilyOutput ('pursuit_{0:D2}.png' -f $Frame)),[System.Drawing.Imaging.ImageFormat]::Png)
        $Output.Dispose()
    }
    $Source.Dispose()
}

Write-Host 'Authored 30 hypersonic pursuit exposures.' -ForegroundColor Green
