[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputDirectory = 'work/visual_qa',
    [switch]$Resume
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if (-not $GodotBin) {
    $Command = Get-Command godot_console -ErrorAction SilentlyContinue
    if (-not $Command) { throw 'Godot console executable was not found.' }
    $GodotBin = $Command.Source
}
if (-not (Test-Path -LiteralPath $GodotBin)) { throw "Godot executable does not exist: $GodotBin" }

$AbsoluteOutput = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $OutputDirectory))
}
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AbsoluteOutput.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Visual QA output must remain inside $WorkRoot."
}
New-Item -ItemType Directory -Force -Path $AbsoluteOutput | Out-Null

$Cases = @(
    @{ id='startup_evavo_ident'; args=@('--capture-startup=evavo_ident','--visual-capture-delay=0.25') },
    @{ id='startup_vx94_transform'; args=@('--capture-startup=vx94_transform','--visual-capture-delay=0.25') },
    @{ id='startup_title_prompt'; args=@('--capture-startup=title_prompt','--visual-capture-delay=0.25') },
    @{ id='front_main_menu'; args=@('--capture-gameplay','--capture-front-end=main_menu') },
    @{ id='front_main_menu_modes_selected'; args=@('--capture-gameplay','--capture-front-end=main_menu','--capture-menu-selection=1') },
    @{ id='front_main_menu_exit_selected'; args=@('--capture-gameplay','--capture-front-end=main_menu','--capture-menu-selection=6') },
    @{ id='front_sortie_bay'; args=@('--capture-gameplay','--capture-front-end=sortie') },
	@{ id='front_stores_schematic'; args=@('--capture-gameplay','--capture-front-end=sortie','--capture-stores-schematic') },
    @{ id='front_modes'; args=@('--capture-gameplay','--capture-front-end=modes','--capture-campaign-clear','--capture-mode-records') },
    @{ id='mode_arcade_assault'; args=@('--capture-gameplay','--capture-game-mode=arcade_assault','--capture-time=48') },
    @{ id='mode_boss_rush'; args=@('--capture-gameplay','--capture-game-mode=boss_rush','--capture-time=48','--capture-hud=boss') },
    @{ id='mode_hypersonic_trial'; args=@('--capture-gameplay','--capture-game-mode=hypersonic_trial','--capture-time=48','--capture-flight=hypersonic','--capture-altitude=high') },
    @{ id='hypersonic_entry_burst'; args=@('--capture-gameplay','--capture-mission=0','--capture-flight=hypersonic','--capture-altitude=high','--visual-capture-delay=0.10') },
	@{ id='hypersonic_engine_ring'; args=@('--capture-gameplay','--capture-mission=0','--capture-flight=hypersonic','--capture-altitude=high','--visual-capture-delay=0.40') },
	@{ id='hypersonic_wing_fold_03'; args=@('--capture-gameplay','--capture-mission=0','--capture-craft=hypersonic-sweep','--capture-transform-exposure=3','--visual-capture-delay=0.10') },
	@{ id='hypersonic_wing_fold_06'; args=@('--capture-gameplay','--capture-mission=0','--capture-craft=hypersonic-sweep','--capture-transform-exposure=6','--visual-capture-delay=0.10') },
	@{ id='hypersonic_wing_fold_09'; args=@('--capture-gameplay','--capture-mission=0','--capture-craft=hypersonic-sweep','--capture-transform-exposure=9','--visual-capture-delay=0.10') },
	@{ id='bomber_wing_deploy_03'; args=@('--capture-gameplay','--capture-mission=1','--capture-form=fighter','--capture-craft=layered-sweep','--capture-transform-exposure=3','--capture-weapon=ballistic','--visual-capture-delay=0.10') },
	@{ id='bomber_wing_deploy_06'; args=@('--capture-gameplay','--capture-mission=1','--capture-form=fighter','--capture-craft=layered-sweep','--capture-transform-exposure=6','--capture-weapon=ballistic','--visual-capture-delay=0.10') },
	@{ id='bomber_wing_deploy_09'; args=@('--capture-gameplay','--capture-mission=1','--capture-form=fighter','--capture-craft=layered-sweep','--capture-transform-exposure=9','--capture-weapon=ballistic','--visual-capture-delay=0.10') },
    @{ id='hypersonic_entry_reduced'; args=@('--capture-gameplay','--capture-mission=0','--capture-flight=hypersonic','--capture-altitude=high','--capture-reduced-flashes','--visual-capture-delay=0.10') },
    @{ id='mode_strike_mastery'; args=@('--capture-gameplay','--capture-game-mode=strike_mastery','--capture-time=48','--capture-form=bomber','--capture-altitude=low') },
    @{ id='front_options_access'; args=@('--capture-gameplay','--capture-front-end=options','--capture-option-category=3','--capture-option-selection=1') },
    @{ id='front_flight_controls'; args=@('--capture-gameplay','--capture-front-end=controls') },
    @{ id='front_flight_controls_advanced'; args=@('--capture-gameplay','--capture-front-end=controls','--capture-control-selection=13') },
    @{ id='front_intelligence'; args=@('--capture-gameplay','--capture-front-end=dossier','--capture-campaign-clear') },
    @{ id='front_secret_operations'; args=@('--capture-gameplay','--capture-front-end=secret_sorties','--capture-campaign-clear') },
    @{ id='front_branch_decision'; args=@('--capture-gameplay','--capture-front-end=branch','--capture-branch') },
    @{ id='weather_drizzle'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=24','--capture-altitude=low') },
    @{ id='weather_rain'; args=@('--capture-gameplay','--capture-mission=2','--capture-time=24','--capture-altitude=low') },
    @{ id='weather_storm'; args=@('--capture-gameplay','--capture-mission=5','--capture-time=24','--capture-altitude=low') },
	@{ id='weather_storm_lightning'; args=@('--capture-gameplay','--capture-mission=5','--capture-time=24','--capture-altitude=low','--capture-weather-lightning') },
    @{ id='weather_snow'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=24','--capture-altitude=low') },
	@{ id='cloud_family_low'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=low') },
	@{ id='cloud_family_mid'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=mid') },
	@{ id='cloud_family_high'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=high') },
	@{ id='roster_human_air'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=mid','--capture-air=human') },
	@{ id='roster_machine_air'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-air=machine') },
	@{ id='roster_orbital_air'; args=@('--capture-gameplay','--capture-mission=25','--capture-time=42','--capture-altitude=orbital','--capture-air=orbital') },
	@{ id='roster_mobile_ground'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=low','--capture-ground=mobile') },
	@{ id='hud_tactical_radar'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=low','--capture-air=human','--capture-ground=mobile','--capture-radar') },
	@{ id='roster_ground_mechs'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=low','--capture-ground=mechs') },
	@{ id='roster_naval'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=low','--capture-ground=naval') },
	@{ id='roster_infantry'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=42','--capture-altitude=low','--capture-ground=infantry') },
	@{ id='support_tanker_contact'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=tanker') },
	@{ id='support_fighter_sweep'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=fighter') },
	@{ id='support_bomber_run'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=bomber') },
	@{ id='support_gunship_fire'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=gunship') },
	@{ id='support_missile_strike'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=missile') },
	@{ id='support_missile_impact'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=missile_impact') },
	@{ id='support_rail_strike'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=rail') },
	@{ id='support_orbital_strike'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=42','--capture-altitude=mid','--capture-support=orbital') },
	@{ id='flight_minimum_power'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-throttle=0') },
	@{ id='flight_cruise_power'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-throttle=50') },
	@{ id='flight_military_power'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-throttle=100') },
	@{ id='flight_hypersonic_forward'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-flight=hypersonic','--capture-altitude=high') },
	@{ id='altitude_climb_cloud_boundary'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-altitude=mid','--capture-altitude-transition=climb','--visual-capture-delay=0.52') },
	@{ id='altitude_dive_cloud_boundary'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=42','--capture-altitude=high','--capture-altitude-transition=dive','--visual-capture-delay=0.52') },
	@{ id='vx94_fighter_roll_mounted'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=0.20','--capture-craft=evasive-roll','--capture-weapon=storm_cannon','--visual-capture-delay=0.10') },
	@{ id='vx94_fighter_roll_damaged'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=0.80','--capture-craft=evasive-roll','--capture-weapon=storm_cannon','--capture-hull-ratio=0.28','--visual-capture-delay=0.10') },
	@{ id='vx94_bomber_roll_mounted'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=0.20','--capture-craft=evasive-roll-bomber','--capture-weapon=ballistic','--visual-capture-delay=0.10') },
	@{ id='vx94_bomber_roll_underside'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=0.58','--capture-craft=evasive-roll-bomber','--capture-weapon=ballistic','--capture-hull-ratio=0.42','--visual-capture-delay=0.10') },
	@{ id='vx94_loss_initial_rupture'; args=@('--capture-gameplay','--capture-form=fighter','--capture-mission=1','--capture-player-loss=0.12','--visual-capture-delay=0.10') },
	@{ id='vx94_loss_breakup'; args=@('--capture-gameplay','--capture-form=fighter','--capture-mission=1','--capture-player-loss=0.48','--visual-capture-delay=0.10') },
	@{ id='vx94_loss_ejection'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-player-loss=0.78','--visual-capture-delay=0.10') },
	@{ id='boss_family_mercenary_phase3'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=4.25','--capture-boss=mercenary','--capture-altitude=mid') },
	@{ id='boss_family_machine_phase3'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=4.25','--capture-boss=machine','--capture-altitude=mid') },
	@{ id='boss_family_orbital_phase3'; args=@('--capture-gameplay','--capture-mission=25','--capture-time=4.25','--capture-boss=orbital','--capture-altitude=orbital') },
    @{ id='mission_01_coastal'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--visual-capture-delay=2.5') },
	@{ id='hud_mission_ingress'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=0.8','--capture-hud=ingress') },
    @{ id='hud_radio_receive'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=2.4','--capture-radio') },
    @{ id='hud_radio_priority'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=2.4','--capture-radio','--capture-radio-alert') },
    @{ id='hud_objective_compact'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-hud=objective') },
    @{ id='mission_01_hypersonic_egress'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=149','--capture-egress','--capture-flight=hypersonic','--capture-altitude=high','--visual-capture-delay=0.18') },
    @{ id='mission_01_egress_clear'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=149','--capture-egress','--capture-egress-complete','--capture-flight=hypersonic','--capture-altitude=high','--visual-capture-delay=0.18') },
    @{ id='mission_01_low_hypersonic_warning'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=70','--capture-flight=hypersonic','--capture-altitude=low','--capture-flight-warning','--visual-capture-delay=0.18') },
    @{ id='mission_02_bomber'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=68','--capture-altitude=low','--visual-capture-delay=1.2') },
	@{ id='vx94_bomber_bay_closed'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=46','--capture-altitude=low','--capture-ventral-bay=closed') },
	@{ id='vx94_bomber_bay_opening'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=46','--capture-altitude=low','--capture-ventral-bay=opening') },
	@{ id='vx94_bomber_bay_open'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=46','--capture-altitude=low','--capture-ventral-bay=open') },
	@{ id='vx94_fighter_strategic_bay_open'; args=@('--capture-gameplay','--capture-form=fighter','--capture-mission=25','--capture-time=118','--capture-altitude=orbital','--capture-strategic-bay=open') },
	@{ id='vx94_bomber_strategic_bay_open'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=25','--capture-time=118','--capture-altitude=orbital','--capture-strategic-bay=open') },
    @{ id='mission_09_air'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-altitude=high') },
    @{ id='mission_12_machine_reveal'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=96') },
    @{ id='mission_26_orbital'; args=@('--capture-gameplay','--capture-mission=25','--capture-time=118','--capture-altitude=orbital') },
    @{ id='mission_30_final_boss'; args=@('--capture-gameplay','--capture-mission=29','--capture-time=180','--capture-hud=boss') },
    @{ id='ending_ark_fall'; args=@('--capture-gameplay','--capture-cinematic=ending_after_machine_ark','--capture-cinematic-shot=0') },
    @{ id='ending_reentry'; args=@('--capture-gameplay','--capture-cinematic=ending_after_machine_ark','--capture-cinematic-shot=1') },
    @{ id='ending_city_silence'; args=@('--capture-gameplay','--capture-cinematic=ending_after_machine_ark','--capture-cinematic-shot=2') },
    @{ id='ending_watch'; args=@('--capture-gameplay','--capture-cinematic=ending_after_machine_ark','--capture-cinematic-shot=3') },
    @{ id='ending_title'; args=@('--capture-gameplay','--capture-cinematic=ending_after_machine_ark','--capture-cinematic-shot=4') },
    @{ id='secret_dead_frequency'; args=@('--capture-gameplay','--capture-secret-mission=sm03_dead_frequency','--capture-time=52','--capture-secret') },
    @{ id='hud_missile_warning'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-hud=warning') },
    @{ id='hud_countermeasure_break'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-altitude=high','--capture-hud=warning','--capture-countermeasure','--visual-capture-delay=0.34') },
	@{ id='hud_countermeasure_ignition'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-altitude=high','--capture-hud=warning','--capture-countermeasure','--visual-capture-delay=0.08') },
	@{ id='weapon_explosion_families'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-weapon-explosions','--visual-capture-delay=0.32') },
    @{ id='hud_player_missile_lock'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=44','--capture-altitude=mid','--capture-hud=objective','--capture-air=human','--capture-player-lock','--visual-capture-delay=0.18') },
    @{ id='pause_command'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=menu') },
    @{ id='pause_options'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=options') },
    @{ id='pause_restart_confirmation'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=confirm_restart') },
    @{ id='debrief_success'; args=@('--capture-gameplay','--capture-result=success') },
    @{ id='debrief_failure'; args=@('--capture-gameplay','--capture-result=failure') },
    @{ id='campaign_credits'; args=@('--capture-gameplay','--capture-credits') }
)

$Results = @()
foreach ($Case in $Cases) {
    $FileName = "$($Case.id).png"
    $AbsoluteFile = Join-Path $AbsoluteOutput $FileName
	if ($Resume -and (Test-Path -LiteralPath $AbsoluteFile)) {
		$Existing = Get-Item -LiteralPath $AbsoluteFile
		Add-Type -AssemblyName System.Drawing
		$ExistingImage = [System.Drawing.Image]::FromFile($AbsoluteFile)
		try {
			if ($Existing.Length -ge 8KB -and $ExistingImage.Width -eq 640 -and $ExistingImage.Height -eq 360) {
				$Results += [ordered]@{ id=$Case.id; file=$FileName; bytes=$Existing.Length; sha256=(Get-FileHash -LiteralPath $AbsoluteFile -Algorithm SHA256).Hash; arguments=@($Case.args) }
				Write-Host "Retaining verified $($Case.id)..." -ForegroundColor DarkGray
				continue
			}
		} finally {
			$ExistingImage.Dispose()
		}
	}
    $Arguments = @('--path', $Root, '--') + @($Case.args) + @('--capture-invulnerable', "--visual-capture=$AbsoluteFile")
    Write-Host "Capturing $($Case.id)..." -ForegroundColor DarkCyan
    $ExitCode = 0
    for ($Attempt = 1; $Attempt -le 3; $Attempt++) {
        & $GodotBin @Arguments
        $ExitCode = $LASTEXITCODE
        if ($ExitCode -eq 0) { break }
        if ($ExitCode -ne -1073741819 -or $Attempt -eq 3) { break }
        Write-Warning "$($Case.id) encountered a transient Godot shutdown fault; retrying ($Attempt/3)."
    }
    if ($ExitCode -ne 0) { throw "Visual QA capture failed for $($Case.id) with exit code $ExitCode." }
    if (-not (Test-Path -LiteralPath $AbsoluteFile)) { throw "Visual QA capture was not created: $AbsoluteFile" }
    $Item = Get-Item -LiteralPath $AbsoluteFile
    if ($Item.Length -lt 8KB) { throw "Visual QA capture is suspiciously small: $AbsoluteFile ($($Item.Length) bytes)." }
    Add-Type -AssemblyName System.Drawing
    $Image = [System.Drawing.Image]::FromFile($AbsoluteFile)
    try {
        if ($Image.Width -ne 640 -or $Image.Height -ne 360) { throw "Visual QA capture has wrong geometry: $AbsoluteFile ($($Image.Width)x$($Image.Height))." }
    } finally {
        $Image.Dispose()
    }
    $Results += [ordered]@{ id=$Case.id; file=$FileName; bytes=$Item.Length; sha256=(Get-FileHash -LiteralPath $AbsoluteFile -Algorithm SHA256).Hash; arguments=@($Case.args) }
}

$ManifestPath = Join-Path $AbsoluteOutput 'manifest.json'
$UniqueHashes = @($Results | ForEach-Object { $_.sha256 } | Sort-Object -Unique)
if ($UniqueHashes.Count -ne $Results.Count) { throw 'Visual QA matrix contains duplicate captures; one or more fixture arguments did not take effect.' }
[ordered]@{ schema_version=1; logical_size='640x360'; captures=$Results } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
Write-Host "HYPERSONIC visual QA matrix captured: $($Results.Count) states at $AbsoluteOutput" -ForegroundColor Green
