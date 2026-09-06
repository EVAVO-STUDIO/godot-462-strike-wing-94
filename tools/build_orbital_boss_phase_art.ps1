param(
    [string]$ArtStudioRoot = 'C:\Gitrepos\evavo-art-studio',
    [string]$NodeBin = 'node',
    [string]$PythonBin = 'python'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets/source/enemies/orbital_phase_v2'
$Manifest = Get-Content -LiteralPath (Join-Path $Source 'manifest.json') -Raw | ConvertFrom-Json
$Request = Join-Path $Source 'art_studio_request.json'
$Run = 'work/orbital_phase_build/' + [guid]::NewGuid().ToString('N')
$Plan = Join-Path $Root ($Run + '/plan.json')
$Candidate = $Run + '/candidate'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Plan) | Out-Null

& $NodeBin (Join-Path $ArtStudioRoot 'scripts/compile-project-art-sandbox.mjs') --workspace-root $Root --request $Request --output $Plan
if ($LASTEXITCODE -ne 0) { throw 'EVAVO orbital phase-art plan compilation failed.' }
& $PythonBin (Join-Path $ArtStudioRoot 'tools/run_project_art_sandbox.py') --workspace-root $Root --plan $Plan --output-root $Candidate
if ($LASTEXITCODE -ne 0) { throw 'EVAVO orbital phase-art sandbox execution failed.' }

# Verify every reviewed output before changing any runtime file. The sandbox
# binds the immutable fragments; these hashes also protect the approved recipe.
foreach ($Frame in $Manifest.frames) {
    $Path = Join-Path $Root ($Candidate + '/' + $Frame.file)
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Frame.sha256) {
        throw "Orbital phase-art rebuild differs from reviewed pixels: $($Frame.file)"
    }
}
$Runtime = Join-Path $Root $Manifest.runtime_directory
foreach ($Frame in $Manifest.frames) {
    Copy-Item -LiteralPath (Join-Path $Root ($Candidate + '/' + $Frame.file)) -Destination (Join-Path $Runtime $Frame.file)
}
Write-Host 'Rebuilt 24 reviewed orbital boss phase overlays through EVAVO Art Studio.'
Write-Host "Source-bound build receipt: $Candidate/_evavo/project-art-sandbox-receipt.json"
