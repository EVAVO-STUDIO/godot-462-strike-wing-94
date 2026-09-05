[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputDirectory = 'work/visual_qa'
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
    @{ id='front_sortie_bay'; args=@('--capture-gameplay','--capture-front-end=sortie') },
    @{ id='front_modes'; args=@('--capture-gameplay','--capture-front-end=modes','--capture-campaign-clear','--capture-mode-records') },
    @{ id='front_options_access'; args=@('--capture-gameplay','--capture-front-end=options','--capture-option-category=3','--capture-option-selection=1') },
    @{ id='front_flight_controls'; args=@('--capture-gameplay','--capture-front-end=controls') },
    @{ id='front_flight_controls_advanced'; args=@('--capture-gameplay','--capture-front-end=controls','--capture-control-selection=13') },
    @{ id='front_intelligence'; args=@('--capture-gameplay','--capture-front-end=dossier','--capture-campaign-clear') },
    @{ id='front_secret_operations'; args=@('--capture-gameplay','--capture-front-end=secret_sorties','--capture-campaign-clear') },
    @{ id='front_branch_decision'; args=@('--capture-gameplay','--capture-front-end=branch','--capture-branch') },
    @{ id='mission_01_coastal'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--visual-capture-delay=2.5') },
	@{ id='hud_mission_ingress'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=0.8','--capture-hud=ingress') },
    @{ id='hud_objective_compact'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=42','--capture-hud=objective') },
    @{ id='mission_01_hypersonic_egress'; args=@('--capture-gameplay','--capture-mission=0','--capture-time=149','--capture-egress','--capture-flight=hypersonic','--capture-altitude=high','--visual-capture-delay=0.18') },
    @{ id='mission_02_bomber'; args=@('--capture-gameplay','--capture-form=bomber','--capture-mission=1','--capture-time=68','--capture-altitude=low','--visual-capture-delay=1.2') },
    @{ id='mission_09_air'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-altitude=high') },
    @{ id='mission_12_machine_reveal'; args=@('--capture-gameplay','--capture-mission=11','--capture-time=96') },
    @{ id='mission_26_orbital'; args=@('--capture-gameplay','--capture-mission=25','--capture-time=118','--capture-altitude=orbital') },
    @{ id='mission_30_final_boss'; args=@('--capture-gameplay','--capture-mission=29','--capture-time=180','--capture-hud=boss') },
    @{ id='secret_dead_frequency'; args=@('--capture-gameplay','--capture-secret-mission=sm03_dead_frequency','--capture-time=52','--capture-secret') },
    @{ id='hud_missile_warning'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-hud=warning') },
    @{ id='hud_countermeasure_break'; args=@('--capture-gameplay','--capture-mission=8','--capture-time=74','--capture-altitude=high','--capture-hud=warning','--capture-countermeasure','--visual-capture-delay=0.18') },
    @{ id='hud_player_missile_lock'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=44','--capture-altitude=mid','--capture-hud=objective','--capture-air=human','--capture-player-lock','--visual-capture-delay=0.18') },
    @{ id='pause_command'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=menu') },
    @{ id='pause_options'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=options') },
    @{ id='pause_restart_confirmation'; args=@('--capture-gameplay','--capture-mission=1','--capture-time=48','--capture-pause=confirm_restart') },
    @{ id='debrief_success'; args=@('--capture-gameplay','--capture-result=success') },
    @{ id='campaign_credits'; args=@('--capture-gameplay','--capture-credits') }
)

$Results = @()
foreach ($Case in $Cases) {
    $FileName = "$($Case.id).png"
    $AbsoluteFile = Join-Path $AbsoluteOutput $FileName
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
