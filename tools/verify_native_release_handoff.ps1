[CmdletBinding()]
param([string]$HandoffPath)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$LockPath = Join-Path $Root '.evavo/godot-lab-native.lock.json'
if (-not (Test-Path -LiteralPath $LockPath)) { throw 'Native Test Lab authority lock is missing.' }
$Lock = Get-Content -Raw -LiteralPath $LockPath | ConvertFrom-Json
$ExpectedLabSha = ([string]$Lock.lab_sha).Trim().ToLowerInvariant()

if (-not $HandoffPath) { throw 'Native Test Lab handoff path is required.' }
$AbsoluteHandoff = if ([System.IO.Path]::IsPathRooted($HandoffPath)) {
    [System.IO.Path]::GetFullPath($HandoffPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $HandoffPath))
}
$NativeRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work/test_lab_native'))
if (-not $AbsoluteHandoff.StartsWith($NativeRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Native Test Lab handoff must remain inside $NativeRoot."
}
if (-not (Test-Path -LiteralPath $AbsoluteHandoff)) { throw "Native Test Lab handoff is missing: $AbsoluteHandoff" }

$Handoff = Get-Content -Raw -LiteralPath $AbsoluteHandoff | ConvertFrom-Json
$HeadSha = (& git -C $Root rev-parse HEAD).Trim().ToLowerInvariant()
if ([int]$Handoff.schema_version -ne 1) { throw 'Native Test Lab handoff schema_version must be 1.' }
if ([string]$Handoff.target_sha -ne $HeadSha) { throw 'Native Test Lab handoff does not match the exact HYPERSONIC HEAD.' }
if (([string]$Handoff.lab_sha).ToLowerInvariant() -ne $ExpectedLabSha) { throw 'Native Test Lab handoff does not match the pinned Test Lab SHA.' }
if (-not ([string]$Handoff.godot_version).StartsWith('4.6.2')) { throw 'Native Test Lab handoff was not produced with Godot 4.6.2.' }
if (-not [bool]$Handoff.interactive_windows_session) { throw 'Native Test Lab handoff was not produced in an authoritative interactive Windows session.' }
if ([int]$Handoff.required_journey_count -ne 9) { throw 'Native Test Lab handoff must contain all 9 governed release journeys.' }
if (-not [bool]$Handoff.controller_maintenance_required) { throw 'Native Test Lab handoff lost the required controller-maintenance journey.' }
if ([string]$Handoff.profile -ne '.evavo/godot-lab-native.json') { throw 'Native Test Lab handoff core profile is incorrect.' }
if ([string]$Handoff.controller_maintenance_profile -ne '.evavo/godot-lab-controller-maintenance.json') { throw 'Native Test Lab handoff controller-maintenance profile is incorrect.' }

foreach ($Property in @('artifact_path','controller_maintenance_artifact_path')) {
    $Value = ([string]$Handoff.$Property).Trim()
    if (-not $Value) { throw "Native Test Lab handoff lost $Property." }
    $Resolved = [System.IO.Path]::GetFullPath($Value)
    if (-not $Resolved.StartsWith($NativeRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Native Test Lab handoff $Property escaped the governed artifact root."
    }
}

Write-Host "HYPERSONIC native handoff passed: 9 journeys including controller maintenance, target $HeadSha, Lab $ExpectedLabSha." -ForegroundColor Green
