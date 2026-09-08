[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Require-Text([string]$RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing supplemental release-contract file: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path
}

$Project = Require-Text 'project.godot'
$Router = Require-Text 'scripts/controller_sortie_bay_director.gd'
$Guidance = Require-Text 'scripts/first_sortie_guidance_director.gd'
$InputTest = Require-Text 'tools/input_bindings_self_test.gd'
$NativeContract = Require-Text 'tools/verify_native_test_lab_contract.ps1'
$NativeRunner = Require-Text 'tools/run_native_test_lab_release.ps1'
$NativeHandoff = Require-Text 'tools/verify_native_release_handoff.ps1'
$NativeDocs = Require-Text 'docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md'
$CandidateGate = Require-Text 'tools/validate_windows_candidate.ps1'
$SignoffTemplate = Require-Text 'docs/RELEASE_SIGNOFF_TEMPLATE.json' | ConvertFrom-Json
Require-Text '.evavo/godot-lab-controller-maintenance.json' | Out-Null
Require-Text 'scripts/first_sortie_guidance_surface.gd' | Out-Null

foreach ($Token in @(
    'ControllerSortieBayDirector="*res://scripts/controller_sortie_bay_director.gd"',
    'FirstSortieGuidanceDirector="*res://scripts/first_sortie_guidance_director.gd"'
)) {
    if (-not $Project.Contains($Token)) { throw "Project lost release-critical autoload: $Token" }
}

foreach ($Token in @('JOY_BUTTON_X','buy_primary','JOY_BUTTON_Y','buy_generator','JOY_BUTTON_LEFT_SHOULDER','service_hull','JOY_BUTTON_RIGHT_SHOULDER','service_shield','JOY_BUTTON_LEFT_STICK','buy_airframe','JOY_BUTTON_RIGHT_STICK','buy_support','front_end_screen','"sortie"','StartupSequenceDirector')) {
    if (-not $Router.Contains($Token)) { throw "Controller sortie-bay router lost contextual maintenance contract: $Token" }
}

foreach ($Token in @('A-D/LS STEER','SPACE/A FIRE','T-G/RS THROTTLE','Q/Y GEOMETRY','PGUP-PGDN / D-PAD','V / LT COUNTERMEASURE','PGUP / D-PAD UP -> HIGH','SHIFT / LB AFTERBURNER','mission_index','game_mode','active_secret_mission_id','ThreatWarningRules.homing_count','egress_active')) {
    if (-not $Guidance.Contains($Token)) { throw "Mission 1 guidance lost onboarding contract: $Token" }
}

foreach ($Token in @('ControllerSortieBayDirector','FirstSortieGuidanceDirector','A-D/LS STEER','V / LT COUNTERMEASURE','SHIFT / LB AFTERBURNER')) {
    if (-not $InputTest.Contains($Token)) { throw "Input regression suite lost release guidance/controller guard: $Token" }
}

foreach ($Token in @('godot-lab-controller-maintenance.json','controller-sortie-bay-maintenance','Expected exactly 9 bounded native journeys','required_journey_count','controller_maintenance_required')) {
    if (-not $NativeContract.Contains($Token) -and -not $NativeRunner.Contains($Token)) { throw "Native release contract lost nine-journey maintenance authority: $Token" }
}
foreach ($Token in @('required_journey_count -ne 9','controller_maintenance_required','controller_maintenance_profile','Godot 4.6.2')) {
    if (-not $NativeHandoff.Contains($Token)) { throw "Native handoff verifier lost controller-maintenance authority: $Token" }
}
foreach ($Token in @('nine required journeys','controller-sortie-bay-maintenance','controller_maintenance_reviewed','Godot **4.6.2**')) {
    if (-not $NativeDocs.Contains($Token)) { throw "Native release documentation lost nine-journey truth boundary: $Token" }
}

if ($null -eq $SignoffTemplate.native_test_lab.PSObject.Properties['controller_maintenance_reviewed']) {
    throw 'Release signoff template lost native_test_lab.controller_maintenance_reviewed.'
}
foreach ($Token in @('verify_native_release_handoff.ps1','controller_maintenance_reviewed','nine-journey native Test Lab authority')) {
    if (-not $CandidateGate.Contains($Token)) { throw "Final candidate gate lost controller-maintenance authority: $Token" }
}

Write-Host 'HYPERSONIC supplemental release contract passed: contextual controller maintenance, 9 native journeys and Mission 1 guidance are governed.' -ForegroundColor Green
