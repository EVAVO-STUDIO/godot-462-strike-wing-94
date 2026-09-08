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
if ([int]$Signoff.schema_version -ne 3) { throw 'Human release signoff schema_version must be 3.' }
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

function Resolve-EvidencePath([string]$Value, [string]$AllowedRelativeRoot, [string]$Label) {
    if (-not $Value.Trim()) { throw "$Label path is required." }
    $Path = if ([System.IO.Path]::IsPathRooted($Value)) {
        [System.IO.Path]::GetFullPath($Value)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $Root $Value))
    }
    $AllowedRoot = [System.IO.Path]::GetFullPath((Join-Path $Root $AllowedRelativeRoot))
    if (-not $Path.StartsWith($AllowedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label must remain inside $AllowedRoot."
    }
    if (-not (Test-Path -LiteralPath $Path)) { throw "$Label is missing: $Path" }
    return $Path
}

$LabLockPath = Join-Path $Root '.evavo/godot-lab-native.lock.json'
if (-not (Test-Path -LiteralPath $LabLockPath)) { throw 'Native Test Lab authority lock is missing.' }
$LabLock = Get-Content -Raw -LiteralPath $LabLockPath | ConvertFrom-Json
$ExpectedLabSha = ([string]$LabLock.lab_sha).Trim().ToLowerInvariant()

$HandoffPath = Resolve-EvidencePath ([string]$Signoff.native_test_lab.handoff_path) 'work/test_lab_native' 'Native Test Lab handoff'
$Handoff = Get-Content -Raw -LiteralPath $HandoffPath | ConvertFrom-Json
if ([int]$Handoff.schema_version -ne 1) { throw 'Native Test Lab handoff schema_version must be 1.' }
if ([string]$Handoff.target_sha -ne $HeadSha) { throw 'Native Test Lab handoff does not match the exact HYPERSONIC HEAD being signed.' }
if ([string]$Handoff.lab_sha -ne $ExpectedLabSha) { throw 'Native Test Lab handoff does not match the pinned Test Lab authority SHA.' }
if (-not ([string]$Handoff.godot_version).StartsWith('4.6.2')) { throw "Native Test Lab handoff was not produced with Godot 4.6.2: $($Handoff.godot_version)" }
if (-not [bool]$Handoff.interactive_windows_session) { throw 'Native Test Lab handoff was not produced in an authoritative interactive Windows session.' }

$VulnerablePath = Resolve-EvidencePath ([string]$Signoff.balance.vulnerable_summary_path) 'work/vulnerable_balance' 'Vulnerable balance summary'
$Vulnerable = Get-Content -Raw -LiteralPath $VulnerablePath | ConvertFrom-Json
if ([int]$Vulnerable.schema_version -ne 1) { throw 'Vulnerable balance summary schema_version must be 1.' }
if ([string]$Vulnerable.source.head_sha -ne $HeadSha) { throw 'Vulnerable balance summary does not match the exact HYPERSONIC HEAD being signed.' }
if (-not ([string]$Vulnerable.source.godot_version).StartsWith('4.6.2')) { throw 'Vulnerable balance summary was not produced with Godot 4.6.2.' }
if ([bool]$Vulnerable.source.invulnerability) { throw 'Human balance signoff cannot use an invulnerable pressure summary.' }
if ([int]$Vulnerable.matrix.case_count -lt 9 -or [int]$Vulnerable.matrix.first_mission_difficulty_count -ne 4) {
    throw 'Vulnerable balance summary does not contain the governed nine-case / four-difficulty matrix.'
}

$EconomyPath = Resolve-EvidencePath ([string]$Signoff.balance.economy_audit_path) 'work/economy' 'Economy progression audit'
$Economy = Get-Content -Raw -LiteralPath $EconomyPath | ConvertFrom-Json
if ([int]$Economy.schema_version -ne 2) { throw 'Economy progression audit schema_version must be 2.' }
if ([string]$Economy.source.head_sha -ne $HeadSha) { throw 'Economy progression audit does not match the exact HYPERSONIC HEAD being signed.' }
if (-not ([string]$Economy.source.godot_version).StartsWith('4.6.2')) { throw 'Economy progression audit was not produced with Godot 4.6.2.' }
if ([int]$Economy.campaign.mission_count -ne 30) { throw 'Economy progression audit does not cover all 30 campaign missions.' }
if (@($Economy.next_purchases_from_fresh).Count -ne 4) { throw 'Economy progression audit must expose exactly four actually-next-purchasable progression choices from a fresh campaign.' }
foreach ($Purchase in @($Economy.next_purchases_from_fresh)) {
    if (-not [bool]$Purchase.next_purchase_from_fresh -or [int]$Purchase.sticker_cost -le 0) {
        throw 'Economy progression audit contains an invalid fresh-campaign next-purchase row.'
    }
}
foreach ($FamilyName in @('primary_weapon','generator','airframe','support')) {
    $Family = $Economy.family_ladders.PSObject.Properties[$FamilyName]
    if ($null -eq $Family -or @($Family.Value).Count -lt 2) {
        throw "Economy progression audit lost sequential family ladder '$FamilyName'."
    }
    $PreviousCumulative = -1
    foreach ($Tier in @($Family.Value)) {
        $Cumulative = [int]$Tier.cumulative_acquisition_cost
        if ($Cumulative -lt $PreviousCumulative) { throw "Economy cumulative acquisition cost regressed inside '$FamilyName'." }
        $PreviousCumulative = $Cumulative
    }
}
foreach ($DifficultyId in @('cadet','combat','veteran','ace')) {
    $Evidence = $Economy.first_mission_conservative_affordability.PSObject.Properties[$DifficultyId]
    if ($null -eq $Evidence) { throw "Economy progression audit lost first-mission affordability evidence for $DifficultyId." }
    if (@($Evidence.Value.affordable_next_purchase_ids).Count -lt 1) {
        throw "Economy progression audit leaves no actually-next-purchasable upgrade after the conservative first-mission service reserve on $DifficultyId."
    }
}

$RequiredTrue = [ordered]@{
    'native_test_lab.passed' = [bool]$Signoff.native_test_lab.passed
    'native_test_lab.all_required_journeys_reviewed' = [bool]$Signoff.native_test_lab.all_required_journeys_reviewed
    'native_test_lab.checkpoint_media_reviewed' = [bool]$Signoff.native_test_lab.checkpoint_media_reviewed
    'native_test_lab.runtime_logs_reviewed' = [bool]$Signoff.native_test_lab.runtime_logs_reviewed
    'native_test_lab.audio_media_reviewed' = [bool]$Signoff.native_test_lab.audio_media_reviewed
    'campaign.complete_end_to_end' = [bool]$Signoff.campaign.complete_end_to_end
    'campaign.keyboard_complete' = [bool]$Signoff.campaign.keyboard_complete
    'campaign.controller_complete' = [bool]$Signoff.campaign.controller_complete
    'onboarding.passed_without_readme_or_developer_help' = [bool]$Signoff.onboarding.passed_without_readme_or_developer_help
    'balance.passed' = [bool]$Signoff.balance.passed
    'balance.no_dominant_trivial_strategy' = [bool]$Signoff.balance.no_dominant_trivial_strategy
    'balance.no_progress_wall' = [bool]$Signoff.balance.no_progress_wall
    'balance.difficulty_matrix_reviewed' = [bool]$Signoff.balance.difficulty_matrix_reviewed
    'balance.vulnerable_evidence_reviewed' = [bool]$Signoff.balance.vulnerable_evidence_reviewed
    'balance.economy_evidence_reviewed' = [bool]$Signoff.balance.economy_evidence_reviewed
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

Write-Host "HYPERSONIC human release signoff passed for $HeadSha ($($Signoff.reviewer)), including pinned native Test Lab, vulnerable pressure and sequential economy progression evidence." -ForegroundColor Green
