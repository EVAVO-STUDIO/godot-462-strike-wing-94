[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe'
)

$ErrorActionPreference = 'Stop'
$ValidateScript = Join-Path $PSScriptRoot 'validate.ps1'
$ExportScript = Join-Path $PSScriptRoot 'export_windows.ps1'
$VerifyScript = Join-Path $PSScriptRoot 'verify_windows_export.ps1'

foreach ($ScriptPath in @($ValidateScript, $ExportScript, $VerifyScript)) {
    $Tokens = $null
    $Errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$Tokens, [ref]$Errors) | Out-Null
    if ($Errors.Count -gt 0) {
        throw "Release dependency has PowerShell parser errors: $ScriptPath -> $($Errors[0].Message)"
    }
}

Write-Host 'Running HYPERSONIC source and engine validation...' -ForegroundColor Cyan
& $ValidateScript -GodotBin $GodotBin

Write-Host 'Building the canonical HYPERSONIC Windows package...' -ForegroundColor Cyan
& $ExportScript -GodotBin $GodotBin -OutputPath $OutputPath

Write-Host 'Launching and verifying the packaged HYPERSONIC runtime...' -ForegroundColor Cyan
& $VerifyScript -Executable $OutputPath

Write-Host 'HYPERSONIC Windows release gate passed.' -ForegroundColor Green
