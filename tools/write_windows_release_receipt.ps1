[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GodotBin,
    [string]$Executable = 'build/windows/HYPERSONIC.exe',
    [string]$ReceiptPath = 'build/windows/HYPERSONIC.release.json'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Resolve-RepoPath([string]$PathValue, [string]$Label) {
    $Absolute = if ([System.IO.Path]::IsPathRooted($PathValue)) {
        [System.IO.Path]::GetFullPath($PathValue)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $Root $PathValue))
    }
    $BuildRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'build'))
    if (-not $Absolute.StartsWith($BuildRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label must remain inside $BuildRoot."
    }
    return $Absolute
}

$AbsoluteExecutable = Resolve-RepoPath $Executable 'Release executable'
$AbsoluteReceipt = Resolve-RepoPath $ReceiptPath 'Release receipt'
if (-not (Test-Path -LiteralPath $AbsoluteExecutable)) {
    throw "Release executable does not exist: $AbsoluteExecutable"
}

$Branch = (& git -C $Root branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $Branch -ne 'main') {
    throw "Release receipt requires branch main; current branch is '$Branch'."
}

$Dirty = @(& git -C $Root status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Git worktree status.' }
if ($Dirty.Count -gt 0) {
    throw "Release receipt requires a clean worktree. First change: $($Dirty[0])"
}

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $HeadSha) { throw 'Unable to resolve release HEAD SHA.' }

$OriginMainSha = ''
& git -C $Root rev-parse --verify origin/main *> $null
if ($LASTEXITCODE -eq 0) {
    $OriginMainSha = (& git -C $Root rev-parse origin/main).Trim()
    if ($HeadSha -ne $OriginMainSha) {
        throw "Release HEAD $HeadSha does not match local origin/main $OriginMainSha. Fetch/publish main before recording candidate evidence."
    }
}

$GodotVersionOutput = @(& $GodotBin --version 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Unable to record Godot version.' }
$GodotVersion = (($GodotVersionOutput | Select-Object -First 1) -as [string]).Trim()
if (-not $GodotVersion.StartsWith('4.6.2', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Release receipt requires Godot 4.6.2; got '$GodotVersion'."
}

$IdentityPath = Join-Path $Root 'data/product_identity.json'
$Identity = Get-Content -Raw -LiteralPath $IdentityPath | ConvertFrom-Json
$Item = Get-Item -LiteralPath $AbsoluteExecutable
$Version = $Item.VersionInfo
$Hash = (Get-FileHash -LiteralPath $AbsoluteExecutable -Algorithm SHA256).Hash.ToLowerInvariant()

$ReceiptDirectory = Split-Path -Parent $AbsoluteReceipt
New-Item -ItemType Directory -Force -Path $ReceiptDirectory | Out-Null

$Receipt = [ordered]@{
    schema_version = 1
    product = 'HYPERSONIC'
    aircraft = 'VX-94 VARIABLE STRIKE FIGHTER'
    source = [ordered]@{
        repository = 'EVAVO-STUDIO/godot-462-strike-wing-94'
        branch = $Branch
        head_sha = $HeadSha
        origin_main_sha = $OriginMainSha
        worktree_clean = $true
    }
    engine = [ordered]@{
        godot_version = $GodotVersion
        executable = [System.IO.Path]::GetFileName($GodotBin)
    }
    package = [ordered]@{
        path = [System.IO.Path]::GetRelativePath($Root, $AbsoluteExecutable).Replace('\','/')
        bytes = [int64]$Item.Length
        sha256 = $Hash
        company_name = [string]$Version.CompanyName
        product_name = [string]$Version.ProductName
        product_version = [string]$Version.ProductVersion
        file_version = [string]$Version.FileVersion
        identity_version = [string]$Identity.version
    }
    evidence = [ordered]@{
        automated_windows_gate = 'passed_before_receipt'
        human_campaign_review = 'required_separately'
        human_visual_audio_review = 'required_separately'
    }
    recorded_utc = [DateTime]::UtcNow.ToString('o')
}

$Receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $AbsoluteReceipt -Encoding UTF8
Write-Host "HYPERSONIC exact-SHA release receipt: $AbsoluteReceipt" -ForegroundColor Green
