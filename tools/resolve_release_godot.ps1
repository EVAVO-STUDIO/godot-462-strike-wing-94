[CmdletBinding()]
param([string]$Preferred = $env:GODOT_BIN)

$ErrorActionPreference = 'Stop'
$RequiredVersionPrefix = '4.6.2'

function Resolve-Executable([string]$Candidate) {
    if (-not $Candidate) { return $null }
    if (Test-Path -LiteralPath $Candidate) {
        return (Resolve-Path -LiteralPath $Candidate).Path
    }
    $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
    if ($Command) { return $Command.Source }
    return $null
}

$Candidates = @()
if ($Preferred) { $Candidates += $Preferred }
$Candidates += @(
    'Godot_v4.6.2-stable_win64_console.exe',
    'godot_console',
    'godot',
    'godot4',
    'Godot_v4.6.2-stable_win64.exe'
)

$Resolved = $null
foreach ($Candidate in $Candidates) {
    $Executable = Resolve-Executable $Candidate
    if (-not $Executable) { continue }

    if ($Executable -notmatch '_console\.exe$') {
        $ConsoleExecutable = $Executable -replace '\.exe$', '_console.exe'
        if (Test-Path -LiteralPath $ConsoleExecutable) { $Executable = $ConsoleExecutable }
    }

    $Resolved = $Executable
    break
}

if (-not $Resolved) {
    throw 'Godot executable was not found. Set GODOT_BIN to the Godot 4.6.2 console executable.'
}

$VersionOutput = @(& $Resolved --version 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to query Godot version from $Resolved."
}
$Version = (($VersionOutput | Select-Object -First 1) -as [string]).Trim()
if (-not $Version.StartsWith($RequiredVersionPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "HYPERSONIC release validation requires Godot $RequiredVersionPrefix; resolved '$Version' at $Resolved."
}

Write-Output $Resolved
