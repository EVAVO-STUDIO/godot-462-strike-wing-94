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
$MenuContext = Require-Text 'scripts/controller_menu_context_director.gd'
$Guidance = Require-Text 'scripts/first_sortie_guidance_director.gd'
$InputTest = Require-Text 'tools/input_bindings_self_test.gd'
$NativeContract = Require-Text 'tools/verify_native_test_lab_contract.ps1'
$NativeRunner = Require-Text 'tools/run_native_test_lab_release.ps1'
$NativeHandoff = Require-Text 'tools/verify_native_release_handoff.ps1'
$NativeDocs = Require-Text 'docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md'
$CandidateGate = Require-Text 'tools/validate_windows_candidate.ps1'
$HumanSignoff = Require-Text 'tools/verify_human_release_signoff.ps1'
$SignoffTemplate = Require-Text 'docs/RELEASE_SIGNOFF_TEMPLATE.json' | ConvertFrom-Json
Require-Text '.evavo/godot-lab-controller-sortie.json' | Out-Null
Require-Text 'scripts/first_sortie_guidance_surface.gd' | Out-Null

foreach ($Token in @(
    'ControllerSortieBayDirector="*res://scripts/controller_sortie_bay_director.gd"',
    'ControllerMenuContextDirector="*res://scripts/controller_menu_context_director.gd"',
    'FirstSortieGuidanceDirector="*res://scripts/first_sortie_guidance_director.gd"'
)) {
    if (-not $Project.Contains($Token)) { throw "Project lost release-critical autoload: $Token" }
}

foreach ($Token in @('JOY_BUTTON_X','buy_primary','JOY_BUTTON_Y','buy_generator','JOY_BUTTON_LEFT_SHOULDER','service_hull','JOY_BUTTON_RIGHT_SHOULDER','service_shield','JOY_BUTTON_LEFT_STICK','buy_airframe','JOY_BUTTON_RIGHT_STICK','buy_support','front_end_screen','"sortie"','StartupSequenceDirector')) {
    if (-not $Router.Contains($Token)) { throw "Controller sortie-bay router lost contextual maintenance contract: $Token" }
}
foreach ($Token in @('process_priority = -45','_wanted_context','"options"','"controls"','JOY_BUTTON_B','JOY_BUTTON_A','fire_secondary','_restore_universal_buttons')) {
    if (-not $MenuContext.Contains($Token)) { throw "Controller menu-context router lost safe front-end remap contract: $Token" }
}

foreach ($Token in @('FLIGHT CHECK // %s-%s/LS STEER','POWER // %s-%s/RS THROTTLE','ALTITUDE // %s-%s / D-PAD','MISSILE // %s / LT COUNTERMEASURE','EGRESS // %s / D-PAD UP -> HIGH','MACH GATE // HOLD %s / LB AFTERBURNER','_keyboard_label','InputMap.action_get_events','mission_index','game_mode','active_secret_mission_id','ThreatWarningRules.homing_count','egress_active')) {
    if (-not $Guidance.Contains($Token)) { throw "Mission 1 guidance lost onboarding/rebinding contract: $Token" }
}

foreach ($Token in @('ControllerSortieBayDirector','ControllerMenuContextDirector','FirstSortieGuidanceDirector','A-D/LS STEER','V / LT COUNTERMEASURE','SHIFT / LB AFTERBURNER')) {
    if (-not $InputTest.Contains($Token)) { throw "Input regression suite lost release guidance/controller guard: $Token" }
}

foreach ($Token in @('godot-lab-controller-sortie.json','controller-sortie-bay-maintenance','controller-options-controls-navigation','required_journey_count = 10','controller_sortie_required = $true','controller_menu_required = $true')) {
    if (-not $NativeContract.Contains($Token) -and -not $NativeRunner.Contains($Token)) { throw "Native release contract lost ten-journey controller authority: $Token" }
}
foreach ($Token in @('required_journey_count -ne 10','controller_sortie_required','controller_menu_required','controller_sortie_profile','godot-lab-controller-sortie.json','Godot 4.6.2')) {
    if (-not $NativeHandoff.Contains($Token)) { throw "Native handoff verifier lost ten-journey controller authority: $Token" }
}
foreach ($Token in @('ten required journeys','controller-sortie-bay-maintenance','controller-options-controls-navigation','controller_maintenance_reviewed','controller_menu_navigation_reviewed','Godot **4.6.2**')) {
    if (-not $NativeDocs.Contains($Token)) { throw "Native release documentation lost ten-journey truth boundary: $Token" }
}

foreach ($Property in @('controller_maintenance_reviewed','controller_menu_navigation_reviewed')) {
    if ($null -eq $SignoffTemplate.native_test_lab.PSObject.Properties[$Property]) {
        throw "Release signoff template lost native_test_lab.$Property."
    }
    if (-not $HumanSignoff.Contains("native_test_lab.$Property")) {
        throw "Human signoff verifier lost native_test_lab.$Property."
    }
}
foreach ($Token in @('verify_native_release_handoff.ps1','controller_maintenance_reviewed','controller_menu_navigation_reviewed','ten-journey')) {
    if (-not $CandidateGate.Contains($Token)) { throw "Final candidate gate lost controller front-end authority: $Token" }
}

Write-Host 'HYPERSONIC supplemental release contract passed: contextual controller maintenance/menu navigation, 10 native journeys and rebound-aware Mission 1 guidance are governed.' -ForegroundColor Green
