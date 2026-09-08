[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ProfilePath = Join-Path $Root '.evavo/godot-lab-native.json'
$LockPath = Join-Path $Root '.evavo/godot-lab-native.lock.json'
$RunnerPath = Join-Path $PSScriptRoot 'run_native_test_lab_release.ps1'
$DocPath = Join-Path $Root 'docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md'

foreach ($Path in @($ProfilePath, $LockPath, $RunnerPath, $DocPath)) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing native Test Lab contract file: $Path" }
}

$Profile = Get-Content -Raw -LiteralPath $ProfilePath | ConvertFrom-Json
$Lock = Get-Content -Raw -LiteralPath $LockPath | ConvertFrom-Json
$Runner = Get-Content -Raw -LiteralPath $RunnerPath
$Doc = Get-Content -Raw -LiteralPath $DocPath

if ([string]$Profile.schemaVersion -ne '2.0') { throw 'Native Test Lab profile must use schemaVersion 2.0.' }
$Journeys = @($Profile.journeys)
if ($Journeys.Count -ne 8) { throw "Expected exactly 8 bounded native journeys, got $($Journeys.Count)." }
$JourneyIds = @($Journeys | ForEach-Object { [string]$_.id })
if (@($JourneyIds | Sort-Object -Unique).Count -ne $JourneyIds.Count) { throw 'Native Test Lab journey IDs must be unique.' }

$ExpectedJourneyIds = @(
    'front-door-keyboard-1280x720',
    'front-door-keyboard-1920x1080',
    'options-controls-keyboard',
    'front-door-synthetic-gamepad',
    'bomber-low-strike-fixture',
    'missile-countermeasure-fixture',
    'orbital-combat-fixture',
    'final-boss-fixture'
)
foreach ($Id in $ExpectedJourneyIds) {
    if ($JourneyIds -notcontains $Id) { throw "Missing governed native journey: $Id" }
}

$FrontDoorIds = @(
    'front-door-keyboard-1280x720',
    'front-door-keyboard-1920x1080',
    'options-controls-keyboard',
    'front-door-synthetic-gamepad'
)
foreach ($Journey in $Journeys) {
    if (-not [bool]$Journey.required) { throw "Release journey is not required: $($Journey.id)" }
    if ([string]$Journey.scene -ne 'res://scenes/main.tscn') { throw "Journey uses unexpected scene: $($Journey.id)" }
    if ([string]$Journey.renderingMethod -ne 'gl_compatibility' -or [string]$Journey.renderingDriver -ne 'opengl3') {
        throw "Journey must use HYPERSONIC's GL Compatibility renderer: $($Journey.id)"
    }
    $Arguments = @($Journey.userArguments | ForEach-Object { [string]$_ })
    if ($Arguments -contains '--capture-invulnerable') { throw "Native Test Lab journey must not force invulnerability: $($Journey.id)" }
    if ($FrontDoorIds -contains [string]$Journey.id -and $Arguments.Count -ne 0) {
        throw "Authentic front-door journey must not use capture fixtures: $($Journey.id)"
    }
    foreach ($Step in @($Journey.steps)) {
        if (-not [string]$Step.type) { throw "Journey contains a step without a type: $($Journey.id)" }
    }
}

$Keyboard720 = @($Journeys | Where-Object { $_.id -eq 'front-door-keyboard-1280x720' })[0]
if ([int]$Keyboard720.width -ne 1280 -or [int]$Keyboard720.height -ne 720) { throw 'Primary keyboard journey must remain 1280x720.' }
$Keyboard1080 = @($Journeys | Where-Object { $_.id -eq 'front-door-keyboard-1920x1080' })[0]
if ([int]$Keyboard1080.width -ne 1920 -or [int]$Keyboard1080.height -ne 1080) { throw 'Secondary keyboard journey must remain 1920x1080.' }
$Gamepad = @($Journeys | Where-Object { $_.id -eq 'front-door-synthetic-gamepad' })[0]
if ([string]$Gamepad.device -ne 'synthetic_gamepad') { throw 'Gamepad journey must remain a synthetic_gamepad journey.' }
if (@($Gamepad.steps | Where-Object { $_.type -eq 'joy_axis' }).Count -lt 2 -or @($Gamepad.steps | Where-Object { $_.type -like 'joy_button*' }).Count -lt 4) {
    throw 'Gamepad journey no longer exercises real joypad axis/button events.'
}

$LabSha = ([string]$Lock.lab_sha).Trim().ToLowerInvariant()
if ($LabSha -notmatch '^[0-9a-f]{40}$') { throw 'Native Test Lab lock must contain an exact 40-character SHA.' }
if ([string]$Lock.profile -ne '.evavo/godot-lab-native.json') { throw 'Native Test Lab lock points at the wrong profile.' }
if ([string]$Lock.release_engine -ne '4.6.2') { throw 'Native Test Lab release engine must remain 4.6.2.' }

foreach ($Token in @('ExpectedLabSha','ExpectedTargetSha','GodotExecutable','MinimumGodotVersion = ''4.6.2''','clean HYPERSONIC worktree','clean Test Lab worktree')) {
    if (-not $Runner.Contains($Token)) { throw "Native Test Lab wrapper lost authority token: $Token" }
}
foreach ($Token in @('Authentic front-door journeys','Focused fixture journeys','exact Godot **4.6.2**','Do not use `-AllowNonInteractive` for release evidence')) {
    if (-not $Doc.Contains($Token)) { throw "Native Test Lab documentation lost truth boundary: $Token" }
}

Write-Host "HYPERSONIC native Test Lab contract passed: 8 journeys, Lab $LabSha, exact Godot 4.6.2." -ForegroundColor Green
