param(
    [string]$Python = 'C:\Users\User\AppData\Local\Programs\Python\Python312\python.exe',
    [string]$SpriteStudioRoot = 'C:\GitRepos\evavo-sprite-studio',
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe',
    [switch]$Integrate
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $Root 'assets\source\craft\vx94\candidates'
$Source = Join-Path $SourceDir 'vx94_identity_motion_sheet_candidate_02_raw.png'
$Config = Join-Path $SourceDir 'vx94_identity_motion_candidate_02.sprite.json'
$Review = Join-Path $Root 'work\vx94_identity_candidate_02'
$CleanRoot = Join-Path $Review 'clean'
$FrameRoot = Join-Path $Review 'frames'
$StudioSource = Join-Path $SpriteStudioRoot 'src'

foreach ($Required in @($Python, $StudioSource, $Magick, $Source, $Config)) {
    if (-not (Test-Path -LiteralPath $Required)) { throw "Required VX-94 identity input missing: $Required" }
}
New-Item -ItemType Directory -Force -Path $FrameRoot | Out-Null

$PreviousPythonPath = $env:PYTHONPATH
try {
    $env:PYTHONPATH = $StudioSource
    & $Python -m sprite_studio.cli clean $Source --out $CleanRoot --config $Config
    if ($LASTEXITCODE -ne 0) { throw 'Sprite Studio failed to clean VX-94 identity candidate 02.' }
}
finally { $env:PYTHONPATH = $PreviousPythonPath }

$Clean = Join-Path $CleanRoot 'frames\vx94_identity_motion_sheet_candidate_02_raw.png'
if (-not (Test-Path -LiteralPath $Clean)) { throw 'Sprite Studio did not produce the cleaned identity sheet.' }

$Frames = @(
    @{ name='transform_00_bomber'; crop='390x440+0+20'; rotate=0 },
    @{ name='transform_01'; crop='300x440+390+20'; rotate=0 },
    @{ name='transform_02'; crop='280x440+690+20'; rotate=0 },
    @{ name='transform_03'; crop='260x440+970+20'; rotate=0 },
    @{ name='transform_04_fighter'; crop='280x440+1230+20'; rotate=0 },
    @{ name='bank_hard_left'; crop='330x470+0+510'; rotate=31 },
    @{ name='bank_left'; crop='300x470+320+510'; rotate=12 },
    @{ name='bank_neutral'; crop='290x470+615+510'; rotate=0 },
    @{ name='bank_right'; crop='300x470+900+510'; rotate=-12 },
    @{ name='bank_hard_right'; crop='330x470+1205+510'; rotate=-31 }
)

foreach ($Frame in $Frames) {
    $Destination = Join-Path $FrameRoot ($Frame.name + '.png')
    & $Magick $Clean -crop $Frame.crop +repage -background none -rotate $Frame.rotate -trim +repage -filter point -resize '88x104>' -gravity center -extent '96x112' -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish VX-94 frame $($Frame.name)." }
    $Channels = & $Magick $Destination -format '%[channels]' info:
    if ($Channels -notmatch 'a') { throw "VX-94 frame $($Frame.name) lost transparency." }
}

$MontageInputs = $Frames | ForEach-Object { Join-Path $FrameRoot ($_.name + '.png') }
$ContactSheet = Join-Path $Review 'vx94_identity_candidate_02_contact.png'
& $Magick montage @MontageInputs -tile '5x2' -geometry '96x112+8+8' -background '#10171c' $ContactSheet
if ($LASTEXITCODE -ne 0) { throw 'Failed to assemble VX-94 candidate contact sheet.' }

Write-Host "Built review-only VX-94 identity candidate 02: $ContactSheet"

if (-not $Integrate) { return }

$RuntimeRoot = Join-Path $Root 'assets\runtime\craft\vx94'
$GameplayRoot = Join-Path $RuntimeRoot 'gameplay'
$GameplayBankRoot = Join-Path $GameplayRoot 'bank'
$FormMap = @{
    # The deepest sweep is reserved for the articulated hypersonic state.
    # Ordinary fighter combat retains enough wing area to read at 640x360.
    'vx94_fighter_v1.png' = 'transform_03.png'
    'vx94_transform_01.png' = 'transform_02.png'
    'vx94_transform_02.png' = 'transform_01.png'
    'vx94_transform_03.png' = 'transform_00_bomber.png'
    'vx94_bomber_v1.png' = 'transform_00_bomber.png'
}
foreach ($DestinationName in $FormMap.Keys) {
    $FrameSource = Join-Path $FrameRoot $FormMap[$DestinationName]
    foreach ($DestinationRoot in @($RuntimeRoot, $GameplayRoot)) {
        $Destination = Join-Path $DestinationRoot $DestinationName
        & $Magick $FrameSource -filter point -resize '56x64>' -gravity center -background none -extent '64x72' -colors 48 -depth 8 $Destination
        if ($LASTEXITCODE -ne 0) { throw "Failed to integrate VX-94 form $DestinationName." }
    }
}

$BankMap = @{
    'fighter_hard_left.png' = 'bank_hard_left.png'
    'fighter_left.png' = 'bank_left.png'
    'fighter_neutral.png' = 'transform_03.png'
    'fighter_right.png' = 'bank_right.png'
    'fighter_hard_right.png' = 'bank_hard_right.png'
}
foreach ($DestinationName in $BankMap.Keys) {
    $FrameSource = Join-Path $FrameRoot $BankMap[$DestinationName]
    $Destination = Join-Path $GameplayBankRoot $DestinationName
    & $Magick $FrameSource -filter point -resize '56x64>' -gravity center -background none -extent '64x72' -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to integrate VX-94 bank frame $DestinationName." }
}

# Preserve existing bomber-bank, thrust, damage and breakup artwork while
# registering it to the larger v2 canvas. These assets remain centered on the
# gameplay pivot and can be replaced independently by later reviewed art.
$RegisteredPatterns = @(
    (Join-Path $GameplayBankRoot 'bomber_*.png'),
    (Join-Path $GameplayRoot 'fx\exhaust_*.png'),
    (Join-Path $GameplayRoot 'damage\*.png'),
    (Join-Path $GameplayRoot 'airframe\*.png'),
    (Join-Path $GameplayRoot 'destruction\*_breakup_*.png')
)
foreach ($Pattern in $RegisteredPatterns) {
    foreach ($Asset in Get-ChildItem -Path $Pattern -File) {
        & $Magick $Asset.FullName -gravity center -background none -extent '64x72' -depth 8 $Asset.FullName
        if ($LASTEXITCODE -ne 0) { throw "Failed to register dependent VX-94 art $($Asset.Name)." }
    }
}

Write-Host 'Integrated reviewed VX-94 candidate 02 forms and fighter-bank poses on a registered 64x72 gameplay canvas.'
