[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ProfilePath = Join-Path $Root '.evavo/godot-lab-native.json'
$ControllerProfilePath = Join-Path $Root '.evavo/godot-lab-controller-sortie.json'
$LockPath = Join-Path $Root '.evavo/godot-lab-native.lock.json'
$RunnerPath = Join-Path $PSScriptRoot 'run_native_test_lab_release.ps1'
$DocPath = Join-Path $Root 'docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md'

foreach ($Path in @($ProfilePath, $ControllerProfilePath, $LockPath, $RunnerPath, $DocPath)) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing native Test Lab contract file: $Path" }
}

$Profile = Get-Content -Raw -LiteralPath $ProfilePath | ConvertFrom-Json
$ControllerProfile = Get-Content -Raw -LiteralPath $ControllerProfilePath | ConvertFrom-Json
$Lock = Get-Content -Raw -LiteralPath $LockPath | ConvertFrom-Json
$Runner = Get-Content -Raw -LiteralPath $RunnerPath
$Doc = Get-Content -Raw -LiteralPath $DocPath

if ([string]$Profile.schemaVersion -ne '2.0') { throw 'Native Test Lab profile must use schemaVersion 2.0.' }
$Journeys = @($Profile.journeys)
if ($Journeys.Count -ne 8) { throw "Expected exactly 8 bounded core native journeys, got $($Journeys.Count)." }
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

# The maintenance profile is separate so the broad eight-journey matrix stays
# bounded while controller progression receives a dedicated authentic front-door
# contract. It must not use fixture arguments or global fake purchase actions.
if ([string]$ControllerProfile.schemaVersion -ne '2.0') { throw 'Controller sortie profile must use schemaVersion 2.0.' }
$ControllerJourneys = @($ControllerProfile.journeys)
if ($ControllerJourneys.Count -ne 1) { throw "Expected exactly one controller sortie-bay journey, got $($ControllerJourneys.Count)." }
$ControllerJourney = $ControllerJourneys[0]
if ([string]$ControllerJourney.id -ne 'controller-sortie-bay-maintenance' -or -not [bool]$ControllerJourney.required) {
    throw 'Controller sortie profile lost its required maintenance journey.'
}
if ([string]$ControllerJourney.device -ne 'synthetic_gamepad' -or [string]$ControllerJourney.scene -ne 'res://scenes/main.tscn') {
    throw 'Controller maintenance journey must use the main scene with synthetic gamepad events.'
}
if ([string]$ControllerJourney.renderingMethod -ne 'gl_compatibility' -or [string]$ControllerJourney.renderingDriver -ne 'opengl3') {
    throw 'Controller maintenance journey must use the production GL Compatibility renderer.'
}
if (@($ControllerJourney.userArguments).Count -ne 0) { throw 'Controller maintenance journey must be an authentic front-door run with no capture fixtures.' }
$ControllerButtons = @($ControllerJourney.steps | Where-Object { $_.type -like 'joy_button*' } | ForEach-Object { [int]$_.buttonIndex })
foreach ($Button in @(0,2,3,7,8,9,10,13,14)) {
    if ($ControllerButtons -notcontains $Button) { throw "Controller maintenance journey lost required physical button $Button." }
}
if (@($ControllerJourney.steps | Where-Object { $_.type -eq 'joy_axis' -and [int]$_.axis -eq 5 }).Count -lt 2) {
    throw 'Controller maintenance journey must exercise right-trigger primary selection.'
}
$MetadataKeys = @($ControllerJourney.assertions | Where-Object { $_.type -eq 'metadata_equals' } | ForEach-Object { [string]$_.key })
foreach ($Key in @('qa_buy_primary','qa_buy_generator','qa_service_hull','qa_service_shield','qa_buy_airframe','qa_buy_support','qa_cycle_support','qa_cycle_battlefield_support')) {
    if ($MetadataKeys -notcontains $Key) { throw "Controller maintenance journey lost router receipt assertion: $Key" }
}

$LabSha = ([string]$Lock.lab_sha).Trim().ToLowerInvariant()
if ($LabSha -notmatch '^[0-9a-f]{40}$') { throw 'Native Test Lab lock must contain an exact 40-character SHA.' }
if ([string]$Lock.profile -ne '.evavo/godot-lab-native.json') { throw 'Native Test Lab lock points at the wrong core profile.' }
if ([string]$Lock.release_engine -ne '4.6.2') { throw 'Native Test Lab release engine must remain 4.6.2.' }

foreach ($Token in @('ExpectedLabSha','ExpectedTargetSha','GodotExecutable','MinimumGodotVersion = ''4.6.2''','clean HYPERSONIC worktree','clean Test Lab worktree','godot-lab-controller-sortie.json','controller sortie-bay maintenance (1)','required_journey_count = 9','controller_sortie_required = $true')) {
    if (-not $Runner.Contains($Token)) { throw "Native Test Lab wrapper lost authority token: $Token" }
}
foreach ($Token in @('Authentic front-door journeys','Focused fixture journeys','Godot **4.6.2**','Do not use `-AllowNonInteractive` for release evidence','controller-sortie-bay-maintenance')) {
    if (-not $Doc.Contains($Token)) { throw "Native Test Lab documentation lost truth boundary: $Token" }
}

Write-Host "HYPERSONIC native Test Lab contract passed: 8 core + 1 controller-maintenance journeys, Lab $LabSha, exact Godot 4.6.2." -ForegroundColor Green
