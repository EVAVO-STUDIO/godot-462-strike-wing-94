param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InputDirectory = Join-Path $RepoRoot 'assets\runtime\environments\coast_chunks'
$OutputDirectory = Join-Path $RepoRoot 'assets\runtime\environments\coast_breaker_animation_v2'
$BuildDirectory = Join-Path $RepoRoot 'work\coast_breaker_build'
$Review = Join-Path $RepoRoot 'work\coast_breaker_animation_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
New-Item -ItemType Directory -Force -Path $OutputDirectory, $BuildDirectory | Out-Null

$Districts = @(
    'seawall_run', 'defended_inlet', 'reef_cliffs',
    'stormbreak_causeway', 'tidal_radar_marsh', 'submarine_pen_headland'
)
# The held cycle builds pressure, breaks, then drains. Width and opacity do not
# move at a perfectly constant rate: that small asymmetry keeps it from reading
# as a procedural pulse while still closing cleanly from phase 5 to phase 0.
$Phases = @(
    @{ Radius = 2; Opacity = 0.24 },
    @{ Radius = 3; Opacity = 0.31 },
    @{ Radius = 5; Opacity = 0.39 },
    @{ Radius = 7; Opacity = 0.46 },
    @{ Radius = 5; Opacity = 0.34 },
    @{ Radius = 3; Opacity = 0.27 }
)

foreach ($District in $Districts) {
    $Source = Join-Path $InputDirectory "$District.png"
    if (-not (Test-Path -LiteralPath $Source)) { throw "Coast district missing: $Source" }
    $WaterMask = Join-Path $BuildDirectory "$($District)_water.png"
    $Luminance = Join-Path $BuildDirectory "$($District)_luminance.png"
    # The coast plates consistently reserve the right-hand side for water. The
    # cool-channel test excludes asphalt and concrete while retaining dark sea.
    & $MagickPath $Source -alpha off -fx 'i<180?0:(((b-r)>0.025)&&((b-g)>0.005)?1:0)' -threshold '50%' $WaterMask
    & $MagickPath $Source -colorspace gray -level '22%,72%' $Luminance
    if ($LASTEXITCODE -ne 0) { throw "Failed to derive shoreline masks for $District" }

    for ($PhaseIndex = 0; $PhaseIndex -lt $Phases.Count; $PhaseIndex++) {
        $Phase = $Phases[$PhaseIndex]
        $Radius = [int]$Phase.Radius
        $Opacity = [double]$Phase.Opacity
        $Edge = Join-Path $BuildDirectory "$($District)_edge_$PhaseIndex.png"
        $Texture = Join-Path $BuildDirectory "$($District)_texture_$PhaseIndex.png"
        $RawAlpha = Join-Path $BuildDirectory "$($District)_raw_alpha_$PhaseIndex.png"
        $CoastalMass = Join-Path $BuildDirectory "$($District)_coastal_mass_$PhaseIndex.png"
        $Alpha = Join-Path $BuildDirectory "$($District)_alpha_$PhaseIndex.png"
        $Destination = Join-Path $OutputDirectory "$($District)_$PhaseIndex.png"

        & $MagickPath $WaterMask -morphology EdgeIn "Diamond:$Radius" -blur '0x0.35' $Edge
        & $MagickPath $Edge $Luminance -compose multiply -composite $Texture
        # Blend a dependable contact crest with plate-derived foam variation,
        # then taper only at district boundaries. The exact transparent boundary
        # rows make every adjacent district and final-to-first join AE=0.
        & $MagickPath $Edge -evaluate multiply '0.58' $Texture -evaluate multiply '0.42' -compose plus -composite -channel R -evaluate multiply $Opacity +channel $RawAlpha
        # Fragmented water-mask pixels used to become conspicuous 15px diamond
        # islands far offshore. Preserve only the connected coastal foam mass,
        # then reapply the original soft alpha so the breaker edge stays organic.
        & $MagickPath $RawAlpha -threshold '2%' -define 'connected-components:area-threshold=400' -define 'connected-components:mean-color=true' -connected-components 8 -threshold '50%' $CoastalMass
        & $MagickPath $RawAlpha $CoastalMass -compose multiply -composite $Alpha
        & $MagickPath -size '640x1024' canvas:'#b9dfe6' $Alpha -alpha off -compose CopyOpacity -composite -channel A -fx 'a*min(1,j/16)*min(1,(h-1-j)/16)' +channel -depth 8 $Destination
        if ($LASTEXITCODE -ne 0) { throw "Failed to build $District breaker phase $PhaseIndex" }
    }
}

$ReviewFrames = foreach ($District in $Districts) {
    foreach ($PhaseIndex in 0, 2, 3, 5) {
        Join-Path $OutputDirectory "$($District)_$PhaseIndex.png"
    }
}
& $MagickPath montage $ReviewFrames -thumbnail '160x256' -tile '4x6' -geometry '+5+16' -background '#0c1820' -fill white -pointsize 10 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build coast breaker animation review.' }

Write-Host "Built $($Districts.Count * $Phases.Count) registered coast-breaker frames."
Write-Host "Review: $Review"
