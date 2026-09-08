[CmdletBinding()]
param(
    [string]$LabRoot = '',
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$ArtifactRoot = 'work/test_lab_native',
    [int]$TimeoutSeconds = 1200,
    [switch]$AllowNonInteractive
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$LockPath = Join-Path $Root '.evavo/godot-lab-native.lock.json'
$ProfilePath = Join-Path $Root '.evavo/godot-lab-native.json'
$ResolveGodotScript = Join-Path $PSScriptRoot 'resolve_release_godot.ps1'

if (-not (Test-Path -LiteralPath $LockPath)) { throw "Missing Test Lab lock: $LockPath" }
if (-not (Test-Path -LiteralPath $ProfilePath)) { throw "Missing Test Lab profile: $ProfilePath" }
$Lock = Get-Content -Raw -LiteralPath $LockPath | ConvertFrom-Json
$ExpectedLabSha = ([string]$Lock.lab_sha).Trim().ToLowerInvariant()
if ($ExpectedLabSha -notmatch '^[0-9a-f]{40}$') { throw 'Pinned Test Lab SHA is invalid.' }
if ([string]$Lock.release_engine -ne '4.6.2') { throw 'HYPERSONIC native release evidence must remain pinned to Godot 4.6.2.' }

if (-not $LabRoot) {
    $LabRoot = Join-Path (Split-Path -Parent $Root) 'godot-game-test-lab'
}
$LabRoot = [System.IO.Path]::GetFullPath($LabRoot)
if (-not (Test-Path -LiteralPath $LabRoot)) { throw "Godot Game Test Lab checkout not found: $LabRoot" }
$LabInvoke = Join-Path $LabRoot 'scripts/Invoke-GodotLabNativeAgentQA.ps1'
if (-not (Test-Path -LiteralPath $LabInvoke)) { throw "Test Lab native runner missing: $LabInvoke" }

$TargetSha = ((& git -C $Root rev-parse HEAD 2>$null) | Select-Object -First 1).Trim().ToLowerInvariant()
$TargetBranch = ((& git -C $Root rev-parse --abbrev-ref HEAD 2>$null) | Select-Object -First 1).Trim()
if ($TargetSha -notmatch '^[0-9a-f]{40}$') { throw 'Unable to resolve exact HYPERSONIC target SHA.' }
if ($TargetBranch -ne 'main') { throw "Native release evidence must run from HYPERSONIC main, not '$TargetBranch'." }
$TargetDirty = @(& git -C $Root status --porcelain 2>$null)
if ($TargetDirty.Count -gt 0) { throw 'Native release evidence requires a clean HYPERSONIC worktree.' }

$ActualLabSha = ((& git -C $LabRoot rev-parse HEAD 2>$null) | Select-Object -First 1).Trim().ToLowerInvariant()
$LabDirty = @(& git -C $LabRoot status --porcelain 2>$null)
if ($ActualLabSha -ne $ExpectedLabSha) {
    throw "Test Lab authority mismatch. Expected $ExpectedLabSha, got $ActualLabSha. Checkout the pinned SHA before producing evidence."
}
if ($LabDirty.Count -gt 0) { throw 'Native release evidence requires a clean Test Lab worktree.' }

$GodotBin = [string](& $ResolveGodotScript -Preferred $GodotBin)
if (-not $GodotBin) { throw 'Unable to resolve the governed Godot 4.6.2 release executable.' }

$AllowedArtifactRoot = if ([System.IO.Path]::IsPathRooted($ArtifactRoot)) {
    [System.IO.Path]::GetFullPath($ArtifactRoot)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $ArtifactRoot))
}
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AllowedArtifactRoot.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Native Test Lab artifacts must remain inside $WorkRoot."
}
$ArtifactPath = Join-Path $AllowedArtifactRoot $TargetSha
New-Item -ItemType Directory -Force -Path $AllowedArtifactRoot | Out-Null

$InvokeArgs = @{
    TargetRepositoryPath = $Root
    ProfilePath = $ProfilePath
    ExpectedLabSha = $ExpectedLabSha
    ExpectedTargetSha = $TargetSha
    ArtifactPath = $ArtifactPath
    AllowedArtifactRoot = $AllowedArtifactRoot
    GodotExecutable = $GodotBin
    MinimumGodotVersion = '4.6.2'
    TimeoutSeconds = $TimeoutSeconds
    MaxTotalSeconds = 3600
    MaxArtifactGiB = 20
}
if ($AllowNonInteractive) { $InvokeArgs.AllowNonInteractive = $true }

Write-Host "Running HYPERSONIC native Test Lab journeys at target $TargetSha" -ForegroundColor Cyan
Write-Host "Pinned Test Lab: $ExpectedLabSha" -ForegroundColor DarkCyan
Write-Host "Governed Godot: $GodotBin" -ForegroundColor DarkCyan
& $LabInvoke @InvokeArgs
if ($LASTEXITCODE -ne 0) { throw "HYPERSONIC native Test Lab runner failed with exit code $LASTEXITCODE." }

$Handoff = [ordered]@{
    schema_version = 1
    target_sha = $TargetSha
    target_branch = $TargetBranch
    lab_sha = $ExpectedLabSha
    godot_executable = $GodotBin
    godot_version = ((@(& $GodotBin --version 2>&1) | Select-Object -First 1) -as [string]).Trim()
    profile = '.evavo/godot-lab-native.json'
    artifact_path = $ArtifactPath
    authority = 'Native synthetic-input evidence only. Human visual/audio/game-feel review and exact-SHA release signoff remain separate.'
}
$HandoffPath = Join-Path $ArtifactPath 'hypersonic-native-handoff.json'
$Handoff | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $HandoffPath -Encoding UTF8
Write-Host "HYPERSONIC native Test Lab handoff complete: $HandoffPath" -ForegroundColor Green
