[CmdletBinding()]
param([string]$SignoffPath = 'work/release_signoff.json')

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$AbsoluteSignoff = if ([System.IO.Path]::IsPathRooted($SignoffPath)) {
    [System.IO.Path]::GetFullPath($SignoffPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $SignoffPath))
}
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AbsoluteSignoff.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Human release signoff must remain inside $WorkRoot."
}
if (-not (Test-Path -LiteralPath $AbsoluteSignoff)) {
    throw "Human release signoff is missing: $AbsoluteSignoff. Start from docs/RELEASE_SIGNOFF_TEMPLATE.json after completing the human review."
}

$Signoff = Get-Content -Raw -LiteralPath $AbsoluteSignoff | ConvertFrom-Json
if ([int]$Signoff.schema_version -ne 1) { throw 'Human release signoff schema_version must be 1.' }
if ([string]$Signoff.product -ne 'HYPERSONIC') { throw 'Human release signoff product must be HYPERSONIC.' }

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $HeadSha) { throw 'Unable to resolve current Git HEAD.' }
if ([string]$Signoff.head_sha -ne $HeadSha) {
    throw "Human release signoff was reviewed against '$($Signoff.head_sha)' but current HEAD is '$HeadSha'."
}

if (-not ([string]$Signoff.reviewer).Trim()) { throw 'Human release signoff requires a reviewer.' }
$Reviewed = [DateTimeOffset]::MinValue
if (-not [DateTimeOffset]::TryParse([string]$Signoff.reviewed_utc, [ref]$Reviewed)) {
    throw 'Human release signoff reviewed_utc must be a valid ISO-8601 timestamp.'
}

$RequiredTrue = [ordered]@{
    'campaign.complete_end_to_end' = [bool]$Signoff.campaign.complete_end_to_end
    'campaign.keyboard_complete' = [bool]$Signoff.campaign.keyboard_complete
    'campaign.controller_complete' = [bool]$Signoff.campaign.controller_complete
    'onboarding.passed_without_readme_or_developer_help' = [bool]$Signoff.onboarding.passed_without_readme_or_developer_help
    'balance.passed' = [bool]$Signoff.balance.passed
    'balance.no_dominant_trivial_strategy' = [bool]$Signoff.balance.no_dominant_trivial_strategy
    'balance.no_progress_wall' = [bool]$Signoff.balance.no_progress_wall
    'visual.passed' = [bool]$Signoff.visual.passed
    'visual.native_1280x720' = [bool]$Signoff.visual.native_1280x720
    'visual.native_1920x1080_or_fullscreen' = [bool]$Signoff.visual.native_1920x1080_or_fullscreen
    'visual.hud_and_warning_readability' = [bool]$Signoff.visual.hud_and_warning_readability
    'visual.reduced_flash_and_accessibility_reviewed' = [bool]$Signoff.visual.reduced_flash_and_accessibility_reviewed
    'audio.passed' = [bool]$Signoff.audio.passed
    'audio.critical_cues_readable' = [bool]$Signoff.audio.critical_cues_readable
    'audio.no_clipping_or_masked_warnings' = [bool]$Signoff.audio.no_clipping_or_masked_warnings
}
foreach ($Item in $RequiredTrue.GetEnumerator()) {
    if (-not $Item.Value) { throw "Human release signoff is incomplete: $($Item.Key) is not true." }
}

if ([int]$Signoff.blockers.p0 -ne 0 -or [int]$Signoff.blockers.p1 -ne 0) {
    throw "Human release signoff still has blockers: P0=$($Signoff.blockers.p0), P1=$($Signoff.blockers.p1)."
}

Write-Host "HYPERSONIC human release signoff passed for $HeadSha ($($Signoff.reviewer))." -ForegroundColor Green
