[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputDirectory = 'work/vulnerable_balance',
    [double]$SimulationSeconds = 72.0
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ResolveGodotScript = Join-Path $PSScriptRoot 'resolve_release_godot.ps1'

if ($SimulationSeconds -lt 24.0 -or $SimulationSeconds -gt 120.0) {
    throw 'SimulationSeconds must remain between 24 and 120 game seconds.'
}

$GodotBin = [string](& $ResolveGodotScript -Preferred $GodotBin)
$AbsoluteOutput = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $OutputDirectory))
}
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AbsoluteOutput.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Vulnerable balance evidence must remain inside $WorkRoot."
}
New-Item -ItemType Directory -Force -Path $AbsoluteOutput | Out-Null

# These are bounded pressure windows, not simulated campaign completions. The
# first mission is repeated across every campaign difficulty so gross pressure
# changes can be inspected without pretending an autopilot is a human player.
$Cases = @(
    @{ id='m01_cadet'; mission=0; difficulty='cadet'; altitude='mid'; form='fighter'; start_time=$null },
    @{ id='m01_combat'; mission=0; difficulty='combat'; altitude='mid'; form='fighter'; start_time=$null },
    @{ id='m01_veteran'; mission=0; difficulty='veteran'; altitude='mid'; form='fighter'; start_time=$null },
    @{ id='m01_ace'; mission=0; difficulty='ace'; altitude='mid'; form='fighter'; start_time=$null },
    @{ id='m02_combat_bomber'; mission=1; difficulty='combat'; altitude='low'; form='bomber'; start_time=$null },
    @{ id='m09_combat_high'; mission=8; difficulty='combat'; altitude='high'; form='fighter'; start_time=$null },
    @{ id='m12_combat_machine'; mission=11; difficulty='combat'; altitude='mid'; form='fighter'; start_time=$null },
    @{ id='m26_combat_orbital'; mission=25; difficulty='combat'; altitude='orbital'; form='fighter'; start_time=$null },
    @{ id='m30_combat_command_window'; mission=29; difficulty='combat'; altitude='orbital'; form='fighter'; start_time=190 }
)

function Dominant-DamageSource($DamageSources) {
    if ($null -eq $DamageSources) { return '' }
    $BestName = ''
    $BestValue = -1
    foreach ($Property in @($DamageSources.PSObject.Properties)) {
        $Value = 0
        try { $Value = [int]$Property.Value } catch { continue }
        if ($Value -gt $BestValue) {
            $BestValue = $Value
            $BestName = [string]$Property.Name
        }
    }
    return $BestName
}

$Runs = @()
foreach ($Case in $Cases) {
    $ReportPath = Join-Path $AbsoluteOutput "$($Case.id).json"
    Remove-Item -LiteralPath $ReportPath -Force -ErrorAction SilentlyContinue

    $Arguments = @(
        '--path', $Root,
        '--',
        '--capture-gameplay',
        '--playtest-telemetry',
        "--playtest-seconds=$SimulationSeconds",
        "--playtest-report=$ReportPath",
        "--capture-mission=$($Case.mission)",
        "--capture-difficulty=$($Case.difficulty)",
        "--capture-altitude=$($Case.altitude)",
        "--capture-form=$($Case.form)"
    )
    if ($null -ne $Case.start_time) { $Arguments += "--capture-time=$($Case.start_time)" }
    if ($Arguments -contains '--capture-invulnerable') {
        throw "Vulnerable balance case accidentally enabled invulnerability: $($Case.id)"
    }

    Write-Host "Running vulnerable pressure window: $($Case.id)..." -ForegroundColor DarkCyan
    $RunOutput = @()
    $ExitCode = 0
    $OutputText = ''
    for ($Attempt = 1; $Attempt -le 3; $Attempt++) {
        Remove-Item -LiteralPath $ReportPath -Force -ErrorAction SilentlyContinue
        $RunOutput = @(& $GodotBin @Arguments 2>&1)
        $ExitCode = $LASTEXITCODE
        $OutputText = ($RunOutput | Out-String)
        if ($ExitCode -eq 0) { break }
        $TransientShutdown = $ExitCode -in @(-1, -1073741819) -and $OutputText -notmatch '(?m)SCRIPT ERROR:|HYPERSONIC bounded playtest failed:'
        if (-not $TransientShutdown -or $Attempt -eq 3) { break }
        Write-Warning "$($Case.id) encountered a transient Godot shutdown fault; retrying ($Attempt/3)."
    }
    if ($ExitCode -ne 0) { throw "Vulnerable pressure window failed for $($Case.id) with exit code $ExitCode.`n$OutputText" }
    if ($OutputText -match '(?m)SCRIPT ERROR:|HYPERSONIC bounded playtest failed:') {
        throw "Vulnerable pressure window emitted a runtime script error: $($Case.id)`n$OutputText"
    }
    if (-not (Test-Path -LiteralPath $ReportPath)) { throw "Vulnerable report missing: $ReportPath" }

    $Report = Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
    if ([string]$Report.profile -ne 'HYPERSONIC_BOUNDED_AUTOPILOT') { throw "Unexpected telemetry profile: $($Case.id)" }
    $Elapsed = [double]$Report.simulation_seconds
    if ($Elapsed -le 0.0) { throw "Vulnerable report has no elapsed gameplay: $($Case.id)" }
    if ([int]$Report.shots_fired -le 0) { throw "Vulnerable report never exercised primary fire: $($Case.id)" }
    if ($Elapsed -ge 12.0 -and [int]$Report.maxima.enemies -le 0) { throw "Vulnerable report never reached hostile contact: $($Case.id)" }

    $Accuracy = if ([int]$Report.shots_fired -gt 0) { [double]$Report.shots_hit / [double]$Report.shots_fired } else { 0.0 }
    $Minutes = [math]::Max($Elapsed / 60.0, 1.0 / 60.0)
    $CompletedWindow = $Elapsed -ge ($SimulationSeconds - 0.5)
    $Runs += [ordered]@{
        id = [string]$Case.id
        mission_id = [string]$Report.mission_id
        mission_name = [string]$Report.mission_name
        difficulty = [string]$Case.difficulty
        requested_altitude = [string]$Case.altitude
        requested_form = [string]$Case.form
        synthetic_start_time = $Case.start_time
        vulnerable = $true
        requested_seconds = $SimulationSeconds
        elapsed_seconds = [math]::Round($Elapsed, 3)
        survival_ratio = [math]::Round([math]::Min(1.0, $Elapsed / $SimulationSeconds), 4)
        completed_window = $CompletedWindow
        ended_before_window = (-not $CompletedWindow)
        phase_at_end = [int]$Report.phase_at_end
        damage_taken = [int]$Report.damage_taken
        damage_per_minute = [math]::Round(([double]$Report.damage_taken / $Minutes), 2)
        dominant_damage_source = Dominant-DamageSource $Report.damage_sources
        shots_fired = [int]$Report.shots_fired
        shots_hit = [int]$Report.shots_hit
        accuracy = [math]::Round($Accuracy, 4)
        targets_destroyed = [int]$Report.targets_destroyed
        kills_per_minute = [math]::Round(([double]$Report.targets_destroyed / $Minutes), 2)
        score_earned = [int]$Report.score_earned
        score_per_minute = [math]::Round(([double]$Report.score_earned / $Minutes), 2)
        enemy_missiles_launched = [int]$Report.enemy_missiles_launched
        countermeasures_decoyed = [int]$Report.countermeasures_decoyed
        countermeasure_charges_spent = [int]$Report.countermeasure_charges_spent
        max_enemies = [int]$Report.maxima.enemies
        max_hostile_projectiles = [int]$Report.maxima.hostile_projectiles
        accepted_system_uses = $Report.accepted_system_uses
        damage_sources = $Report.damage_sources
    }
}

$FirstMission = @($Runs | Where-Object { $_.id -like 'm01_*' })
$Signals = @()
foreach ($Run in $Runs) {
    if ($Run.ended_before_window) {
        $Signals += "EARLY_END:$($Run.id):$($Run.elapsed_seconds)s"
    }
    if ($Run.damage_per_minute -ge 100.0) {
        $Signals += "HIGH_DAMAGE_RATE:$($Run.id):$($Run.damage_per_minute)"
    }
    if ($Run.max_hostile_projectiles -gt 64) {
        $Signals += "DENSITY_OVER_64:$($Run.id):$($Run.max_hostile_projectiles)"
    }
}

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
$GodotVersion = ((@(& $GodotBin --version 2>&1) | Select-Object -First 1) -as [string]).Trim()
$Summary = [ordered]@{
    schema_version = 1
    scope = 'deterministic vulnerable autoplay pressure evidence; not human balance certification and not a campaign-completion simulation'
    source = [ordered]@{
        head_sha = $HeadSha
        godot_version = $GodotVersion
        invulnerability = $false
    }
    matrix = [ordered]@{
        requested_seconds = $SimulationSeconds
        case_count = $Runs.Count
        first_mission_difficulty_count = $FirstMission.Count
    }
    review_signals = @($Signals | Sort-Object -Unique)
    runs = $Runs
}
$SummaryPath = Join-Path $AbsoluteOutput 'summary.json'
$Summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SummaryPath -Encoding UTF8

Write-Host "HYPERSONIC vulnerable balance telemetry completed: $($Runs.Count) pressure windows." -ForegroundColor Green
Write-Host "Evidence: $SummaryPath" -ForegroundColor DarkGray
if ($Signals.Count -gt 0) {
    Write-Warning ("Review signals were recorded; do not auto-tune from them: " + (($Signals | Sort-Object -Unique) -join ', '))
}
