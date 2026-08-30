[CmdletBinding()]
param([string]$GodotBin = $env:GODOT_BIN)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Resolve-Godot {
    param([string]$Preferred)
    if ($Preferred -and (Test-Path $Preferred)) { return (Resolve-Path $Preferred).Path }
    foreach ($Candidate in @('godot','godot4','Godot_v4.6.2-stable_win64_console.exe','Godot_v4.6.2-stable_win64.exe')) {
        $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($Command) {
            $Executable = $Command.Source
            $Item = Get-Item -LiteralPath $Executable
            if ($Item.LinkType -and $Item.Target) { $Executable = [string](@($Item.Target)[0]) }

            # The Windows GUI binary detaches immediately, leaving
            # $LASTEXITCODE unset and allowing validation to report a false
            # failure (or race the test). Prefer its paired console build.
            if ($Executable -notmatch '_console\.exe$') {
                $ConsoleExecutable = $Executable -replace '\.exe$', '_console.exe'
                if (Test-Path -LiteralPath $ConsoleExecutable) { return $ConsoleExecutable }
            }
            return $Executable
        }
    }
    return $null
}

function Assert-Contains([string]$Text, [string[]]$Tokens, [string]$Label) {
    foreach ($Token in $Tokens) {
        if (-not $Text.Contains($Token)) { throw "$Label missing token: $Token" }
    }
}

function Assert-UniqueIds($Collection, [string]$Label) {
    $Ids = @($Collection | ForEach-Object { $_.id })
    if ($Ids -contains $null -or $Ids -contains '') { throw "Blank id in $Label" }
    if (@($Ids | Sort-Object -Unique).Count -ne $Ids.Count) { throw "Duplicate id in $Label" }
}

function Mission-Context($World, [string]$MissionId) {
    $Property = $World.mission_context.PSObject.Properties[$MissionId]
    if ($null -eq $Property) { return $null }
    return $Property.Value
}

Write-Host 'Validating HYPERSONIC...' -ForegroundColor Cyan

$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd','scripts/product_identity.gd','scripts/startup_sequence_director.gd','scripts/startup_sequence_surface.gd','data/product_identity.json',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd',
    'scripts/boss_rules.gd','scripts/boss_signature_rules.gd','scripts/boss_director.gd','scripts/bomb_rules.gd',
    'scripts/campaign_save.gd','scripts/save_recovery_rules.gd','scripts/run_seed_rules.gd','scripts/mission_state_rules.gd','scripts/mission_flow_rules.gd',
    'scripts/movement_pattern_rules.gd','scripts/weapon_pickup_rules.gd','scripts/accuracy_rules.gd','scripts/reward_rules.gd','scripts/service_rules.gd',
    'scripts/energy_rules.gd','scripts/tech_progression_rules.gd','scripts/airframe_rules.gd','scripts/airframe_director.gd',
    'scripts/directed_energy_rules.gd','scripts/directed_energy_director.gd',
    'scripts/strategic_warhead_rules.gd','scripts/strategic_warhead_surface.gd','scripts/strategic_warhead_director.gd',
    'scripts/encounter_rules.gd','scripts/encounter_director.gd','scripts/support_rules.gd','scripts/support_director.gd',
    'scripts/player_mount_rules.gd','scripts/player_mount_director.gd',
    'scripts/craft_form_rules.gd','scripts/altitude_rules.gd','scripts/craft_form_director.gd',
    'scripts/environment_rules.gd','scripts/environment_surface.gd','scripts/environment_director.gd',
    'scripts/altitude_transition_surface.gd','scripts/altitude_transition_director.gd',
    'scripts/combat_art_surface.gd','scripts/combat_art_director.gd','scripts/airframe_cue_surface.gd','scripts/airframe_cue_director.gd',
    'scripts/afterburner_cue_surface.gd','scripts/afterburner_cue_director.gd','scripts/weapon_mount_cue_surface.gd','scripts/weapon_mount_cue_director.gd',
    'scripts/damage_state_surface.gd','scripts/damage_state_director.gd','scripts/combat_fx_surface.gd','scripts/combat_fx_director.gd',
    'scripts/intercept_route_rules.gd','scripts/intercept_route_surface.gd','scripts/intercept_route_director.gd',
    'scripts/battlefield_support_rules.gd','scripts/battlefield_support_surface.gd','scripts/battlefield_support_director.gd',
    'scripts/strike_ordnance_rules.gd','scripts/strike_ordnance_surface.gd','scripts/strike_ordnance_director.gd',
    'scripts/electromagnetic_cue_surface.gd','scripts/electromagnetic_cue_director.gd',
    'scripts/mission_intel_rules.gd','scripts/mission_intel_surface.gd','scripts/mission_intel_director.gd',
    'scripts/loadout_schematic_surface.gd','scripts/loadout_schematic_director.gd',
    'scripts/retro_sfx_rules.gd','scripts/retro_sfx_director.gd',
    'scripts/pixel_font.gd','scripts/pixel_ui_surface.gd','scripts/pixel_ui_director.gd',
    'scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd',
    'tools/product_identity_self_test.gd','tools/startup_sequence_self_test.gd','tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd','tools/save_recovery_self_test.gd',
    'tools/encounter_self_test.gd','tools/support_self_test.gd','tools/craft_form_self_test.gd','tools/battlefield_support_self_test.gd','tools/environment_self_test.gd',
    'tools/strike_ordnance_self_test.gd','tools/tech_progression_self_test.gd','tools/boss_signature_self_test.gd','tools/combat_art_self_test.gd','tools/afterburner_self_test.gd','tools/player_mount_self_test.gd',
    'data/weapons.json','data/generators.json','data/airframes.json','data/support_systems.json','data/battlefield_support.json',
    'data/enemies.json','data/missions.json','data/spawn_profiles.json','data/environment_profiles.json','data/campaign.json','data/campaign_world.json','data/player_craft.json','data/player_mounts.json',
    'docs/90S_SHOOTER_BIBLE.md','docs/CAMPAIGN_CANON.md','docs/CRAFT_ALTITUDE_SYSTEM.md','docs/VX94_COMBAT_ART_DIRECTION.md','docs/STRATEGIC_ORBITAL_ENDGAME.md','docs/ARCHITECTURE.md'
)
foreach ($RelativePath in $Required) {
    if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" }
}

$TrackedFiles = @(git -C $Root ls-files 2>$null)
foreach ($Forbidden in @(
    '.github/workflows','.godot','build','dist',
    'scripts/spawn_safety_director.gd','scripts/spawn_safety_rules.gd','scripts/missile_behavior_director.gd','scripts/missile_behavior_rules.gd',
    'scripts/mission_state_director.gd','scripts/bomb_guard_director.gd','scripts/mission_flow_director.gd','scripts/movement_pattern_director.gd',
    'scripts/run_seed_director.gd','scripts/weapon_pickup_director.gd','scripts/accuracy_director.gd','scripts/reward_director.gd','scripts/service_director.gd',
    'scripts/boss_hud_director.gd','scripts/boss_hud_rules.gd','scripts/threat_warning_director.gd'
)) {
    $Prefix = $Forbidden.TrimEnd('/','\') + '/'
    if (@($TrackedFiles | Where-Object { $_ -eq $Forbidden -or $_.StartsWith($Prefix) }).Count -gt 0) { throw "Forbidden generated/obsolete path committed: $Forbidden" }
}

$Weapons = Get-Content -Raw (Join-Path $Root 'data/weapons.json') | ConvertFrom-Json
$Generators = Get-Content -Raw (Join-Path $Root 'data/generators.json') | ConvertFrom-Json
$Airframes = Get-Content -Raw (Join-Path $Root 'data/airframes.json') | ConvertFrom-Json
$Supports = Get-Content -Raw (Join-Path $Root 'data/support_systems.json') | ConvertFrom-Json
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json
$World = Get-Content -Raw (Join-Path $Root 'data/campaign_world.json') | ConvertFrom-Json
$Mounts = Get-Content -Raw (Join-Path $Root 'data/player_mounts.json') | ConvertFrom-Json
$Identity = Get-Content -Raw (Join-Path $Root 'data/product_identity.json') | ConvertFrom-Json

Assert-UniqueIds $Weapons.weapons 'weapons'
Assert-UniqueIds $Generators.generators 'generators'
Assert-UniqueIds $Airframes.airframes 'airframes'
Assert-UniqueIds $Supports.supports 'support systems'
Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'
Assert-UniqueIds $Profiles.profiles 'spawn profiles'
Assert-UniqueIds $Mounts.mounts 'player mounts'

if ([string]$Identity.full_title -ne 'HYPERSONIC' -or [string]$Identity.aircraft_designation -ne 'VX-94' -or [string]$Identity.aircraft_class -ne 'Variable Strike Fighter' -or [string]$Identity.aircraft_class_abbreviation -ne 'VSF') { throw 'Production identity hierarchy is invalid.' }
if ([string]$Identity.developer -ne 'EVAVO Studio' -or [string]$Identity.publisher -ne 'EVAVO Studio') { throw 'EVAVO Studio product ownership metadata is invalid.' }
if ([string]$Identity.save_namespace -ne 'hypersonic' -or @($Identity.legacy_save_namespaces) -notcontains 'strike_wing_94') { throw 'Save namespace migration metadata is invalid.' }

$EvavoRoot = Join-Path $Root 'assets/runtime/brand/front_door_raw_art_v1'
$EvavoHashes = @{
    'evavo_splash_plate_v1.png' = 'D834FAF8795C85EADAF80C50278B0638D8D1B7025C92DC58D40D98A6EEAEC232'
    'evavo_corner_sparkle_00.png' = 'C4C7FD9077527941C94C54F68217CD19DD007C87FF57356040D825278BB899E7'
    'evavo_corner_sparkle_09.png' = '73BA295C81D953611776B3E92938512AF5E6D3D5C4E1B63BA666BBEEF5674ECE'
}
foreach ($Asset in $EvavoHashes.Keys) {
    $AssetPath = Join-Path $EvavoRoot $Asset
    if (-not (Test-Path -LiteralPath $AssetPath)) { throw "Missing approved EVAVO splash asset: $Asset" }
    if ((Get-FileHash -LiteralPath $AssetPath -Algorithm SHA256).Hash -ne $EvavoHashes[$Asset]) { throw "Modified approved EVAVO splash asset: $Asset" }
}

$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -ne 8) { throw 'Campaign requires exactly eight primary tiers.' }
if (@($Generators.generators).Count -lt 5) { throw 'Generator progression requires at least five tiers.' }
if (@($Airframes.airframes).Count -ne 5) { throw 'VX-94 requires exactly five airframe tiers.' }
if (@($Supports.supports).Count -ne 7) { throw 'Tactical catalogue requires exactly seven systems.' }
if (@($Missions.missions).Count -ne 12) { throw 'Campaign requires exactly twelve missions.' }
if ([int]$Mounts.schema_version -lt 2 -or [string]$Mounts.craft_id -ne 'vx_94_strikewing' -or @($Mounts.mounts).Count -lt 11) { throw 'VX-94 mount catalogue is incomplete.' }
foreach ($MountId in @('nose_rotary','wing_root_left','wing_root_right','centerline_emitter','inner_pylon_left','inner_pylon_right','outer_pylon_left','outer_pylon_right','ventral_strike_bay','ventral_strategic_bay','dorsal_module')) {
    if (@($Mounts.mounts | ForEach-Object { $_.id }) -notcontains $MountId) { throw "Missing VX-94 mount: $MountId" }
}

$Plasma = @($Primaries | Where-Object { $_.id -eq 'plasma_lance' })[0]
if ([string]$Plasma.unlock_tech_era -ne 'strategic_orbital') { throw 'Plasma Lance must remain strategic-orbital hardware.' }
$Micro = @($Supports.supports | Where-Object { $_.id -eq 'micro_warhead_rack' })[0]
if (-not [bool]$Micro.strategic -or [double]$Micro.cooldown -lt 900) { throw 'Micro-Warhead must remain scarce strategic hardware.' }

$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
$CampaignIds = @($Campaign.campaign.missions)
if ($CampaignIds.Count -ne 12 -or @($CampaignIds | Sort-Object -Unique).Count -ne 12) { throw 'Campaign order must contain twelve unique missions.' }
foreach ($Id in $CampaignIds) { if ($MissionIds -notcontains $Id) { throw "Unknown campaign mission: $Id" } }

$AllowedConditionTypes = @('accuracy_at_least','score_at_least','bombs_at_least','altitude_is','form_is','altitude_form')
$RouteBeatIds = @('low_attack_window','high_intercept_route','low_bomber_route','high_hunter_route')
$SeenRouteBeatIds = @{}
$ChoiceWindows = 0
foreach ($Mission in $Missions.missions) {
    $Context = Mission-Context $World ([string]$Mission.id)
    if ($null -eq $Context) { throw "Missing campaign context: $($Mission.id)" }
    # PowerShell wraps a missing JSON property as a one-item array containing
    # $null. Missions with authored transitions but no free-choice window are
    # valid, so only validate actual window objects.
    foreach ($Window in @($Context.altitude_choice_windows | Where-Object { $null -ne $_ })) {
        $ChoiceWindows++
        if ([double]$Window.end_seconds -le [double]$Window.start_seconds) { throw "Invalid altitude window: $($Mission.id)" }
        if (@($Window.bands).Count -lt 2) { throw "Altitude window needs at least two bands: $($Mission.id)" }
    }
    foreach ($Beat in @($Mission.encounter_beats)) {
        if ($Beat.condition) {
            $Type = [string]$Beat.condition.type
            if ($AllowedConditionTypes -notcontains $Type) { throw "Unsupported encounter condition: $($Mission.id)/$($Beat.id) -> $Type" }
        }
        if ($RouteBeatIds -contains [string]$Beat.id) {
            $SeenRouteBeatIds[[string]$Beat.id] = $true
            if ([string]$Beat.condition.type -ne 'altitude_form') { throw "Route beat must use altitude_form: $($Beat.id)" }
        }
    }
}
if ($ChoiceWindows -lt 7) { throw 'Campaign should retain multiple tactical altitude-lane windows.' }
foreach ($Id in $RouteBeatIds) { if (-not $SeenRouteBeatIds.ContainsKey($Id)) { throw "Missing route bonus beat: $Id" } }

$Machine = Mission-Context $World 'm12_machine_ark'
if ([string]$Machine.altitude -ne 'high' -or [string]$Machine.tech_era -ne 'strategic_orbital') { throw 'Machine Ark must start HIGH in strategic-orbital era.' }
if ([int]$Machine.altitude_transitions[0].at_seconds -ne 156 -or [string]$Machine.altitude_transitions[0].altitude -ne 'orbital') { throw 'Machine Ark must perform final orbital burn at 156 seconds.' }

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id })
$BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave -or @($Profile.enemy_ids).Count -lt 1) { throw "Invalid spawn profile: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) {
        if ($EnemyIds -notcontains $EnemyId -or $BossIds -contains $EnemyId) { throw "Invalid spawn enemy: $($Profile.id) -> $EnemyId" }
    }
}

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @(
    'ProductIdentity="*res://scripts/product_identity.gd"',
    'StartupSequenceDirector="*res://scripts/startup_sequence_director.gd"',
    'PlayerMountDirector="*res://scripts/player_mount_director.gd"',
    'CraftFormDirector="*res://scripts/craft_form_director.gd"',
    'EncounterDirector="*res://scripts/encounter_director.gd"',
    'SupportDirector="*res://scripts/support_director.gd"',
    'CombatArtDirector="*res://scripts/combat_art_director.gd"',
    'AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"',
    'WeaponMountCueDirector="*res://scripts/weapon_mount_cue_director.gd"',
    'DamageStateDirector="*res://scripts/damage_state_director.gd"',
    'CombatFxDirector="*res://scripts/combat_fx_director.gd"',
    'InterceptRouteDirector="*res://scripts/intercept_route_director.gd"',
    'EnvironmentDirector="*res://scripts/environment_director.gd"',
    'StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"',
    'MissionIntelDirector="*res://scripts/mission_intel_director.gd"',
    'LoadoutSchematicDirector="*res://scripts/loadout_schematic_director.gd"',
    'RetroSfxDirector="*res://scripts/retro_sfx_director.gd"',
    'PixelUiDirector="*res://scripts/pixel_ui_director.gd"'
)) {
    if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" }
}

$MountRulesText = Get-Content -Raw (Join-Path $Root 'scripts/player_mount_rules.gd')
Assert-Contains $MountRulesText @('primary_offsets','support_offsets','strategic_store','ballistic_primary','precision_kinetic') 'Canonical mount rules'
$MountDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/player_mount_director.gd')
Assert-Contains $MountDirectorText @('res://data/player_mounts.json','primary_offsets','support_offsets','bomber_rotary_deployed') 'Canonical mount owner'
$MountCueText = Get-Content -Raw (Join-Path $Root 'scripts/weapon_mount_cue_director.gd')
Assert-Contains $MountCueText @('get_node_or_null("/root/PlayerMountDirector")','mounts.call("primary_offsets"','mounts.call("bomber_rotary_deployed"') 'Mount-aware muzzle cues'
$SchematicText = Get-Content -Raw (Join-Path $Root 'scripts/loadout_schematic_director.gd')
Assert-Contains $SchematicText @('res://data/player_mounts.json','VX-94 STORES / VARIABLE GEOMETRY','fighter','bomber') 'Stores schematic'

$CraftText = Get-Content -Raw (Join-Path $Root 'scripts/craft_form_director.gd')
Assert-Contains $CraftText @('process_priority = -30','_publish_altitude_spawn_profiles(scene)','AltitudeRules.allows_enemy_archetype','KEY_PAGEUP','KEY_PAGEDOWN','primary_mount_offsets','bomber_rotary_deployed') 'Craft/altitude runtime'
$EncounterText = Get-Content -Raw (Join-Path $Root 'scripts/encounter_director.gd')
Assert-Contains $EncounterText @('process_priority = -20','AltitudeRules.allows_enemy_archetype','ALTITUDE FILTER','EncounterRules.is_low_bomber_route(beat)','enemy["strike_priority"] = true','EncounterRules.is_high_fighter_route(beat)','enemy["intercept_priority"] = true','HIGH_INTERCEPT_VALUE_BONUS') 'Encounter route/altitude filtering'
$EncounterRulesText = Get-Content -Raw (Join-Path $Root 'scripts/encounter_rules.gd')
Assert-Contains $EncounterRulesText @('"altitude_is"','"form_is"','"altitude_form"','is_low_bomber_route','is_high_fighter_route','HIGH_INTERCEPT_VALUE_BONUS := 450') 'Encounter route conditions'
$InterceptRulesText = Get-Content -Raw (Join-Path $Root 'scripts/intercept_route_rules.gd')
Assert-Contains $InterceptRulesText @('CHAIN_SECONDS := 2.4','MAX_CHAIN := 6','likely_destroyed','INTERCEPT CHAIN X%d') 'Intercept route rules'
$InterceptText = Get-Content -Raw (Join-Path $Root 'scripts/intercept_route_director.gd')
Assert-Contains $InterceptText @('intercept_priority','HIGH INTERCEPT  SHIFT AB','InterceptRouteRules.next_chain','_chain_timer','_last_score') 'High fighter route presentation'
if ($InterceptText.Contains('scene.set("score"')) { throw 'Intercept presentation must not mutate authoritative score.' }

$AltitudeText = Get-Content -Raw (Join-Path $Root 'scripts/altitude_rules.gd')
Assert-Contains $AltitudeText @('TRANSITION_SECONDS := 1.15','allows_enemy_class','allows_enemy_archetype','adjacent_band') 'Altitude rules'
$MainText = Get-Content -Raw (Join-Path $Root 'scripts/main.gd')
Assert-Contains $MainText @('_craft_primary_mount_offsets(weapon, count)','"position": player_position + mount_offsets[i]','mission_rng.seed = RunSeedRules.mission_seed(mission_index)') 'Main gameplay'
$StrikeRulesText = Get-Content -Raw (Join-Path $Root 'scripts/strike_ordnance_rules.gd')
Assert-Contains $StrikeRulesText @('ROUTE_PRECISION_SCORE := 450','assisted_target_index','strike_priority','STABILITY_SECONDS := 0.65','update_stability','stabilized_impact_delay','stabilized_aim_radius') 'Bombing computer rules'
$StrikeText = Get-Content -Raw (Join-Path $Root 'scripts/strike_ordnance_director.gd')
Assert-Contains $StrikeText @('ROUTE TARGET','PRECISION ROUTE HIT','_update_attack_run_stability','STB%03d','route_precision_score') 'Bombing route runtime'
$IntelText = Get-Content -Raw (Join-Path $Root 'scripts/mission_intel_rules.gd')
Assert-Contains $IntelText @('route_opportunity_summary','"ROUTES %s"','LOW','BMB','HIGH','FTR') 'Mission route intel'
$DamageText = Get-Content -Raw (Join-Path $Root 'scripts/damage_state_director.gd')
Assert-Contains $DamageText @('damage_ratio < 0.20','damage_ratio >= 0.45','damage_ratio >= 0.72','ratio >= 0.86','scene.call("_max_hull")') 'VX-94 damage state'
$FxText = Get-Content -Raw (Join-Path $Root 'scripts/combat_fx_director.gd')
Assert-Contains $FxText @('MAX_EVENTS := 48','boss_explosion','player_hit','play_event','_hit_audio_cooldown') 'Combat impact FX'
$SfxRulesText = Get-Content -Raw (Join-Path $Root 'scripts/retro_sfx_rules.gd')
Assert-Contains $SfxRulesText @('FIRE_ROTARY','ALTITUDE_CLIMB','ALTITUDE_DIVE','BOSS_EXPLOSION','PLAYER_HIT','"wave":"blast"') 'Procedural SFX rules'
$SfxDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/retro_sfx_director.gd')
Assert-Contains $SfxDirectorText @('const MIX_RATE := 22050.0','func play_event','"blast"','MAX_VOICES := 8') 'Procedural SFX runtime'
$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
Assert-Contains $SaveText @('SAVE_VERSION := 5','airframe_index','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural/data/altitude/routes/mounts/bombing/damage/impact validation passed; engine tests skipped.'
    exit 0
}

# Import newly added textures before script preloads are exercised. This makes
# validation reliable on a clean clone with no generated .godot cache.
Write-Host 'Running Godot editor import/smoke test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }

$Tests = @(
    'product_identity_self_test.gd','startup_sequence_self_test.gd','runtime_self_test.gd','reward_self_test.gd','service_self_test.gd','mission_flow_self_test.gd','save_recovery_self_test.gd',
    'encounter_self_test.gd','support_self_test.gd','craft_form_self_test.gd','battlefield_support_self_test.gd','environment_self_test.gd',
    'strike_ordnance_self_test.gd','tech_progression_self_test.gd','boss_signature_self_test.gd','combat_art_self_test.gd','afterburner_self_test.gd','player_mount_self_test.gd'
)
foreach ($Test in $Tests) {
    Write-Host "Running $Test..." -ForegroundColor DarkCyan
    & $Godot --headless --path $Root --script "res://tools/$Test"
    if ($LASTEXITCODE -ne 0) { throw "$Test failed with exit code $LASTEXITCODE" }
}

Write-Host 'HYPERSONIC validation passed.' -ForegroundColor Green
