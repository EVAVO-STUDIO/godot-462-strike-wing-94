[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$OutputDirectory = Join-Path $Root 'assets/runtime/effects/aircraft_navigation_lights'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Add-Type -AssemblyName System.Drawing

function Write-LightSprite {
    param(
        [string]$Name,
        [System.Drawing.Color]$Halo,
        [System.Drawing.Color]$Mid,
        [System.Drawing.Color]$Core
    )

    $Bitmap = [System.Drawing.Bitmap]::new(5, 5, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $Bitmap.SetPixel(2, 0, $Halo)
        $Bitmap.SetPixel(0, 2, $Halo)
        $Bitmap.SetPixel(4, 2, $Halo)
        $Bitmap.SetPixel(2, 4, $Halo)
        $Bitmap.SetPixel(1, 1, $Halo)
        $Bitmap.SetPixel(3, 1, $Halo)
        $Bitmap.SetPixel(1, 3, $Halo)
        $Bitmap.SetPixel(3, 3, $Halo)
        $Bitmap.SetPixel(2, 1, $Mid)
        $Bitmap.SetPixel(1, 2, $Mid)
        $Bitmap.SetPixel(3, 2, $Mid)
        $Bitmap.SetPixel(2, 3, $Mid)
        $Bitmap.SetPixel(2, 2, $Core)
        $Path = Join-Path $OutputDirectory ($Name + '.png')
        $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $Bitmap.Dispose()
    }
}

Write-LightSprite 'port_red' `
    ([System.Drawing.Color]::FromArgb(36, 116, 8, 3)) `
    ([System.Drawing.Color]::FromArgb(132, 205, 38, 20)) `
    ([System.Drawing.Color]::FromArgb(255, 255, 103, 67))
Write-LightSprite 'starboard_green' `
    ([System.Drawing.Color]::FromArgb(34, 2, 92, 53)) `
    ([System.Drawing.Color]::FromArgb(126, 22, 190, 111)) `
    ([System.Drawing.Color]::FromArgb(255, 115, 255, 190))
Write-LightSprite 'anti_collision_white' `
    ([System.Drawing.Color]::FromArgb(42, 108, 139, 151)) `
    ([System.Drawing.Color]::FromArgb(156, 191, 221, 230)) `
    ([System.Drawing.Color]::FromArgb(255, 244, 252, 255))

Write-Host "Built restrained aircraft navigation lights at $OutputDirectory"
