param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\orbital_boss_layered\orbital_boss_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\orbital_boss_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Orbital-boss component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas)
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity center -background none -extent $Canvas -colors 64 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build orbital-boss component: $Name" }
}

Build-Component 'command_collar' '230x310+0+0' '29x29' '33x33'
Build-Component 'command_dish' '175x300+225+0' '29x27' '33x31'
Build-Component 'command_beam' '95x300+390+0' '14x30' '18x34'
Build-Component 'command_beam_recoil' '85x300+480+0' '13x26' '18x34'
Build-Component 'command_mast_folded' '115x305+565+0' '16x31' '20x35'
Build-Component 'command_mast_deployed' '115x305+675+0' '16x32' '20x36'
Build-Component 'command_core_normal' '80x190+780+120' '13x25' '17x29'
Build-Component 'command_core_overload' '80x190+855+120' '13x25' '17x29'
Build-Component 'command_core_ruptured' '90x190+930+120' '14x25' '18x29'

Build-Component 'phase_lens_calm' '135x180+255+330' '40x40' '44x44'
Build-Component 'phase_lens_charge' '135x180+385+330' '40x40' '44x44'
Build-Component 'phase_lens_aligned' '135x180+515+330' '40x40' '44x44'
Build-Component 'phase_lens_unstable' '145x180+645+330' '41x40' '45x44'
Build-Component 'phase_shutter_closed' '100x190+795+340' '17x31' '21x35'
Build-Component 'phase_shutter_open' '125x190+895+340' '19x31' '23x35'
Build-Component 'phase_projector' '150x185+300+485' '22x28' '26x32'
Build-Component 'phase_projector_damaged' '170x185+450+485' '24x28' '28x32'

Build-Component 'warden_collar' '260x260+0+650' '32x32' '36x36'
Build-Component 'warden_rail' '120x300+270+630' '16x39' '20x43'
Build-Component 'warden_rail_recoil' '90x300+390+630' '14x35' '20x43'
Build-Component 'warden_point_turret' '190x230+490+650' '27x23' '31x27'
Build-Component 'warden_clamp_closed' '120x240+710+650' '18x30' '22x34'
Build-Component 'warden_clamp_open' '190x240+825+650' '28x30' '32x34'
Build-Component 'warden_vent_closed' '170x175+130+910' '25x23' '29x27'
Build-Component 'warden_vent_hot' '170x175+300+910' '25x23' '29x27'
Build-Component 'warden_rail_scorched' '250x185+460+900' '39x24' '43x28'
Build-Component 'warden_clamp_broken' '310x185+710+900' '43x24' '47x28'

Build-Component 'ark_aperture_closed' '155x195+255+1070' '37x37' '41x41'
Build-Component 'ark_aperture_opening' '155x195+405+1070' '37x37' '41x41'
Build-Component 'ark_aperture_open' '175x195+555+1070' '39x37' '43x41'
Build-Component 'ark_arc_retracted' '105x230+750+1060' '17x34' '21x38'
Build-Component 'ark_arc_extended' '170x250+850+1040' '25x37' '29x41'
Build-Component 'ark_tracking_pylon' '230x225+35+1300' '24x31' '28x35'
Build-Component 'ark_core_normal' '155x220+260+1300' '17x28' '21x32'
Build-Component 'ark_core_overload' '155x220+410+1300' '17x28' '21x32'
Build-Component 'ark_core_ruptured' '180x220+555+1300' '19x28' '23x32'
Build-Component 'ark_cracked_plate' '150x200+760+1315' '26x23' '30x27'
Build-Component 'ark_arc_severed' '115x210+905+1315' '22x28' '26x32'

Write-Host 'Built HYPERSONIC layered BLACK SKY boss art.'
