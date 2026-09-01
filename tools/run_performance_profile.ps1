[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$Report = 'res://work/performance_profile.json',
    [ValidateSet('stress','baseline')][string]$Density = 'stress',
    [ValidateSet('none','environment','projectiles','combat_art','combat_fx','hud','presentation','core','auxiliary')][string]$Isolate = 'none'
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if (-not $GodotBin) {
    $Command = Get-Command godot_console -ErrorAction SilentlyContinue
    if (-not $Command) { throw 'Godot console executable was not found.' }
    $GodotBin = $Command.Source
}
Write-Host 'Profiling HYPERSONIC production combat stress at 1280x720...' -ForegroundColor Cyan
& $GodotBin --path $Root -- --capture-gameplay --capture-invulnerable --performance-profile "--performance-density=$Density" "--performance-isolate=$Isolate" "--performance-report=$Report"
if ($LASTEXITCODE -ne 0) { throw "HYPERSONIC performance profile failed with exit code $LASTEXITCODE." }
$ReportPath = if ($Report.StartsWith('res://', [System.StringComparison]::OrdinalIgnoreCase)) {
    Join-Path $Root $Report.Substring(6).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
} elseif ([System.IO.Path]::IsPathRooted($Report)) {
    [System.IO.Path]::GetFullPath($Report)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $Report))
}
if (-not (Test-Path -LiteralPath $ReportPath)) { throw "Performance report was not created: $ReportPath" }
$Profile = Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
if ([string]$Profile.profile -ne 'HYPERSONIC_NATIVE_PRODUCTION_RUNTIME' -or -not [bool]$Profile.production_layers) { throw 'Performance report did not exercise the production runtime.' }
if ([string]$Profile.density -ne $Density -or [string]$Profile.isolate -ne $Isolate) { throw 'Performance report does not match the requested workload.' }
if ($Density -eq 'stress') {
    if ([int]$Profile.max_enemies -lt 14 -or [int]$Profile.max_player_projectiles -lt 16 -or [int]$Profile.max_hostile_projectiles -lt 64) { throw 'Performance stress population was not sustained.' }
}
if ([double]$Profile.average_fps -lt 60.0 -or [double]$Profile.p95_frame_ms -gt 16.67) { throw 'Performance report missed the stable 60 Hz production threshold.' }
Write-Host ("HYPERSONIC graphical performance passed: {0:N1} FPS average, {1:N2} ms p95, {2:N0} p95 draw calls." -f [double]$Profile.average_fps, [double]$Profile.p95_frame_ms, [double]$Profile.p95_draw_calls) -ForegroundColor Green
