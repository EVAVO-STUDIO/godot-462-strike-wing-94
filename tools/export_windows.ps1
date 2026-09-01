[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

if (-not $GodotBin) {
    foreach ($Candidate in @('godot_console', 'godot', 'godot4')) {
        $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($Command) {
            $GodotBin = $Command.Source
            break
        }
    }
}
if (-not $GodotBin -or -not (Test-Path -LiteralPath $GodotBin)) {
    throw 'Godot executable was not found. Set GODOT_BIN to a Godot 4.6.2 console executable.'
}

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

Write-Host 'Exporting HYPERSONIC for Windows Desktop...' -ForegroundColor Cyan
& $GodotBin --headless --path $Root --export-release 'Windows Desktop' $AbsoluteOutput
if ($LASTEXITCODE -ne 0) {
    throw "HYPERSONIC Windows export failed with exit code $LASTEXITCODE. Confirm that the matching Godot export templates are installed."
}
if (-not (Test-Path -LiteralPath $AbsoluteOutput)) {
    throw "Godot reported success but did not create $AbsoluteOutput."
}
Write-Host "HYPERSONIC Windows export created: $AbsoluteOutput" -ForegroundColor Green
