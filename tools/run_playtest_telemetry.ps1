[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputDirectory = 'work/playtest_telemetry',
    [double]$SimulationSeconds = 36.0
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if (-not $GodotBin) {
    $Command = Get-Command godot_console -ErrorAction SilentlyContinue
    if (-not $Command) { throw 'Godot console executable was not found.' }
    $GodotBin = $Command.Source
}
$AbsoluteOutput = [System.IO.Path]::GetFullPath((Join-Path $Root $OutputDirectory))
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AbsoluteOutput.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Playtest telemetry must remain inside $WorkRoot." }
New-Item -ItemType Directory -Force -Path $AbsoluteOutput | Out-Null

$Cases = @(
    @{ id='first_mission'; args=@('--capture-mission=0') },
    @{ id='bomber_strike'; args=@('--capture-mission=1','--capture-altitude=low') },
    @{ id='difficult_air'; args=@('--capture-mission=8','--capture-altitude=high') },
    @{ id='altitude_choice'; args=@('--capture-mission=7') },
    @{ id='machine_reveal'; args=@('--capture-mission=11') },
    @{ id='orbital_transition'; args=@('--capture-mission=24','--capture-altitude=orbital') },
    @{ id='secret_sortie'; args=@('--capture-secret-mission=sm03_dead_frequency','--capture-secret') },
    @{ id='final_mission'; args=@('--capture-mission=29') }
)

$Summaries = @()
foreach ($Case in $Cases) {
    $ReportPath = Join-Path $AbsoluteOutput "$($Case.id).json"
    $Arguments = @('--path',$Root,'--','--capture-gameplay','--capture-invulnerable','--playtest-telemetry',"--playtest-seconds=$SimulationSeconds","--playtest-report=$ReportPath") + @($Case.args)
    Write-Host "Running bounded playtest: $($Case.id)..." -ForegroundColor DarkCyan
    $RunOutput = @(& $GodotBin @Arguments 2>&1 | Tee-Object -Variable CapturedOutput)
    $ExitCode = $LASTEXITCODE
    $OutputText = ($RunOutput | Out-String)
    if ($ExitCode -ne 0) { throw "Bounded playtest failed for $($Case.id) with exit code $ExitCode." }
    if ($OutputText -match '(?m)SCRIPT ERROR:|HYPERSONIC bounded playtest failed:') { throw "Bounded playtest emitted a runtime script error: $($Case.id)" }
    if (-not (Test-Path -LiteralPath $ReportPath)) { throw "Playtest report missing: $ReportPath" }
    $Report = Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
    if ([string]$Report.profile -ne 'HYPERSONIC_BOUNDED_AUTOPILOT' -or [double]$Report.simulation_seconds -lt ($SimulationSeconds - 0.5)) { throw "Invalid playtest report: $($Case.id)" }
    if ([int]$Report.shots_fired -le 0 -or [int]$Report.maxima.enemies -le 0) { throw "Playtest did not reach active combat: $($Case.id)" }
    if (@($Report.altitude_seconds.PSObject.Properties).Count -lt 1 -or @($Report.form_seconds.PSObject.Properties).Count -lt 1) { throw "Playtest occupancy telemetry is missing: $($Case.id)" }
    if ($SimulationSeconds -ge 32.0) {
        foreach ($Command in @{ transform=3; altitude=3; roll=3; countermeasure=3; tactical_support=2; battlefield_support=2; ordnance=2; screen_bomb=1 }.GetEnumerator()) {
            if ([int]$Report.commands.($Command.Key) -lt [int]$Command.Value) { throw "Scheduled $($Command.Key) coverage is missing: $($Case.id)" }
        }
    }
    $Summaries += $Report
}
$TotalHits = [int](($Summaries | Measure-Object -Property shots_hit -Sum).Sum)
$TotalKills = [int](($Summaries | Measure-Object -Property targets_destroyed -Sum).Sum)
$AcceptedTactical = [int](($Summaries | ForEach-Object { $_.accepted_system_uses.tactical_support } | Measure-Object -Sum).Sum)
$AcceptedBattlefield = [int](($Summaries | ForEach-Object { $_.accepted_system_uses.battlefield_support } | Measure-Object -Sum).Sum)
$AcceptedOrdnance = [int](($Summaries | ForEach-Object { $_.accepted_system_uses.ordnance } | Measure-Object -Sum).Sum)
$CountermeasureChargesSpent = [int](($Summaries | Measure-Object -Property countermeasure_charges_spent -Sum).Sum)
$CollateralStrikes = [int](($Summaries | Measure-Object -Property collateral_strikes -Sum).Sum)
$MinimumCameraOffset = [double](($Summaries | ForEach-Object { $_.forward_flight.minimum_camera_offset_pixels } | Measure-Object -Minimum).Minimum)
$MaximumCameraOffset = [double](($Summaries | ForEach-Object { $_.forward_flight.maximum_camera_offset_pixels } | Measure-Object -Maximum).Maximum)
if ($TotalHits -le 0 -or $TotalKills -le 0) { throw 'Representative playtests did not produce confirmed hits and destruction.' }
if ($SimulationSeconds -ge 32.0 -and ($AcceptedTactical -le 0 -or $AcceptedBattlefield -le 0 -or $AcceptedOrdnance -le 0)) {
    throw 'Representative playtests did not confirm accepted tactical, battlefield and strike-ordnance usage.'
}
if ($SimulationSeconds -ge 32.0 -and $CountermeasureChargesSpent -lt $Summaries.Count) {
    throw 'Representative playtests did not confirm a live countermeasure cassette release in every sortie.'
}
if ($CollateralStrikes -gt 0) {
    throw "Representative playtests destroyed $CollateralStrikes protected surface contacts."
}
if ($SimulationSeconds -ge 32.0 -and ($MinimumCameraOffset -gt -70.0 -or $MaximumCameraOffset -lt 35.0 -or ($MaximumCameraOffset - $MinimumCameraOffset) -lt 120.0)) {
    throw "Representative playtests did not confirm the full speed-driven camera envelope: $MinimumCameraOffset to $MaximumCameraOffset pixels."
}
[ordered]@{ schema_version=1; scope='bounded deterministic automation; not a substitute for human feel review'; runs=$Summaries } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $AbsoluteOutput 'summary.json') -Encoding UTF8
Write-Host "HYPERSONIC bounded playtest telemetry passed: $($Summaries.Count) representative sorties." -ForegroundColor Green
