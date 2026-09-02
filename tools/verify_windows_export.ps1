[CmdletBinding()]
param([string]$Executable = 'build/windows/HYPERSONIC.exe')

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$AbsoluteExecutable = if ([System.IO.Path]::IsPathRooted($Executable)) {
    [System.IO.Path]::GetFullPath($Executable)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $Executable))
}
$BuildRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'build'))
if (-not $AbsoluteExecutable.StartsWith($BuildRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Windows verification target must remain inside $BuildRoot."
}
if (-not (Test-Path -LiteralPath $AbsoluteExecutable)) {
    throw "Windows export does not exist: $AbsoluteExecutable"
}

$Item = Get-Item -LiteralPath $AbsoluteExecutable
$Version = $Item.VersionInfo
if ($Version.CompanyName -ne 'EVAVO Studio') { throw "Unexpected company metadata: $($Version.CompanyName)" }
if ($Version.ProductName -ne 'HYPERSONIC') { throw "Unexpected product metadata: $($Version.ProductName)" }
if ($Version.FileDescription -ne 'HYPERSONIC // VX-94 VARIABLE STRIKE FIGHTER') { throw "Unexpected file description: $($Version.FileDescription)" }
if ($Item.Length -lt 10MB) { throw "Windows export is suspiciously small: $($Item.Length) bytes." }

$SmokeId = [guid]::NewGuid().ToString('N')
$SmokeOutLog = Join-Path ([System.IO.Path]::GetTempPath()) ("hypersonic-export-smoke-{0}.out.log" -f $SmokeId)
$SmokeErrorLog = Join-Path ([System.IO.Path]::GetTempPath()) ("hypersonic-export-smoke-{0}.error.log" -f $SmokeId)
try {
    $Process = Start-Process -FilePath $AbsoluteExecutable -ArgumentList @('--headless','--quit-after','30','--','--capture-gameplay','--capture-front-end=main_menu') -WindowStyle Hidden -RedirectStandardOutput $SmokeOutLog -RedirectStandardError $SmokeErrorLog -Wait -PassThru
    $SmokeOutput = @(
        Get-Content -LiteralPath $SmokeOutLog -Raw -ErrorAction SilentlyContinue
        Get-Content -LiteralPath $SmokeErrorLog -Raw -ErrorAction SilentlyContinue
    ) -join "`n"
    if ($Process.ExitCode -ne 0) {
        throw "Exported HYPERSONIC smoke test failed with exit code $($Process.ExitCode).`n$SmokeOutput"
    }
    if ($SmokeOutput -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
        throw "Exported HYPERSONIC smoke test reported engine errors.`n$SmokeOutput"
    }
} finally {
    Remove-Item -LiteralPath $SmokeOutLog,$SmokeErrorLog -Force -ErrorAction SilentlyContinue
}

Write-Host "HYPERSONIC Windows export verified: $($Item.Length) bytes, $($Version.ProductVersion)." -ForegroundColor Green
