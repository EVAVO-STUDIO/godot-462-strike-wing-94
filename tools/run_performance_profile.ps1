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
Write-Host 'HYPERSONIC graphical performance profile passed.' -ForegroundColor Green
