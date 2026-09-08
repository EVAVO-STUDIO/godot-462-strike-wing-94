[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Resolver = Join-Path $PSScriptRoot 'resolve_release_godot.ps1'
if (-not (Test-Path -LiteralPath $Resolver)) { throw "Missing governed release-engine resolver: $Resolver" }
$GodotBin = [string](& $Resolver -Preferred $GodotBin)
if (-not $GodotBin) { throw 'Unable to resolve governed Godot 4.6.2 executable.' }

$AbsoluteOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $OutputPath))
}
$BuildRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'build'))
if (-not $AbsoluteOutput.StartsWith($BuildRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Windows export must remain inside $BuildRoot."
}

$OutputDirectory = Split-Path -Parent $AbsoluteOutput
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Write-Host "Exporting HYPERSONIC for Windows Desktop with $GodotBin..." -ForegroundColor Cyan
& $GodotBin --headless --path $Root --export-release 'Windows Desktop' $AbsoluteOutput
if ($LASTEXITCODE -ne 0) {
    throw "HYPERSONIC Windows export failed with exit code $LASTEXITCODE. Confirm that the Godot 4.6.2 export templates are installed."
}
if (-not (Test-Path -LiteralPath $AbsoluteOutput)) {
    throw "Godot reported success but did not create $AbsoluteOutput."
}
Write-Host "HYPERSONIC Windows export created: $AbsoluteOutput" -ForegroundColor Green
