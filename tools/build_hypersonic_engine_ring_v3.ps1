[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets/source/effects/hypersonic_engine_ring_v3'
$RuntimeRoot = Join-Path $Root 'assets/runtime/effects/persistent/hypersonic_engine_ring'
$CandidateRoot = Join-Path $Root 'work/hypersonic_engine_ring_v3/candidates'
$FinishedRoot = Join-Path $Root 'work/hypersonic_engine_ring_v3/finished'
$Sheet = Join-Path $CandidateRoot 'engine_ring_sheet.png'
New-Item -ItemType Directory -Force -Path $CandidateRoot,$FinishedRoot,$RuntimeRoot | Out-Null

& magick -background none -density 96 (Join-Path $SourceRoot 'engine_ring_sheet.svg') $Sheet
if ($LASTEXITCODE -ne 0) { throw 'Could not rasterize the hypersonic engine-ring sheet.' }

$Records = @()
for ($Index = 0; $Index -lt 6; $Index++) {
    $Candidate = Join-Path $CandidateRoot ("{0}.png" -f $Index)
    $Finished = Join-Path $FinishedRoot ("{0}.png" -f $Index)
    $Runtime = Join-Path $RuntimeRoot ("{0}.png" -f $Index)
    & magick $Sheet -crop ("128x128+{0}+0" -f ($Index * 128)) +repage $Candidate
    if ($LASTEXITCODE -ne 0) { throw "Could not extract engine-ring frame $Index." }
    node C:\Gitrepos\evavo-art-studio\tools\finish_raster_asset.mjs --input $Candidate --output $Finished --preset web-hero --spec (Join-Path $SourceRoot 'finish_spec.json') --print-evidence
    if ($LASTEXITCODE -ne 0) { throw "EVAVO Art Studio rejected engine-ring frame $Index." }
    Copy-Item -LiteralPath $Finished -Destination $Runtime -Force
    $Records += [ordered]@{
        frame = $Index
        source = 'assets/source/effects/hypersonic_engine_ring_v3/engine_ring_sheet.svg'
        runtime = "assets/runtime/effects/persistent/hypersonic_engine_ring/$Index.png"
        sha256 = (Get-FileHash -LiteralPath $Runtime -Algorithm SHA256).Hash
    }
}
[ordered]@{
    schema = 'hypersonic_engine_ring_v3'
    geometry = '128x128'
    pivot = @(64,64)
    frames = $Records
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $SourceRoot 'manifest.json') -Encoding UTF8
Write-Host 'Built six EVAVO-finished hypersonic engine-ring frames.' -ForegroundColor Green
