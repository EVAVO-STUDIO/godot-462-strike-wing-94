param([string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Base = Join-Path $Root 'assets\runtime\enemies\machine_ground_layered\autonomous_armor_base.png'
$Output = Join-Path $Root 'assets\runtime\enemies\machine_ground_layered\locomotion\autonomous_armor'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Base -PathType Leaf)) { throw "Autonomous armour base not found: $Base" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

# Four robotic track pods advance in a six-pixel contact cycle while the hull,
# protected core and independent weapon pivot remain perfectly registered.
for ($Frame = 0; $Frame -lt 4; $Frame++) {
    $Bright = @()
    $Dark = @()
    foreach ($PodTop in @(4,17)) {
        $Y = $PodTop + $Frame * 2
        while ($Y -gt $PodTop + 5) { $Y -= 6 }
        for (; $Y -le $PodTop + 9; $Y += 6) {
            $Bright += "line 3,$Y 7,$Y line 28,$Y 32,$Y"
            if ($Y + 2 -le $PodTop + 9) { $Dark += "line 3,$($Y+2) 7,$($Y+2) line 28,$($Y+2) 32,$($Y+2)" }
        }
    }
    $Destination = Join-Path $Output "$Frame.png"
    & $Magick $Base -fill '#77a9aa' -draw ($Bright -join ' ') -fill '#172426' -draw ($Dark -join ' ') -colors 40 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build autonomous armour locomotion frame $Frame" }
}

Write-Host 'Built HYPERSONIC autonomous-armour locomotion cels.'
