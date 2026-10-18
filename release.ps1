# release.ps1 - Durus release build: ONE published APK per release.
#
# WHY ONE APK
#   Users cannot tell `app-arm64-v8a` / `app-armeabi-v7a` / `app-x86_64`
#   apart and pick the wrong file. v1.1.18 shipped all three; two of them had
#   zero downloads (they serve pre-2017 32-bit phones and PC emulators, and an
#   x86_64 APK cannot install on a phone at all). Every release now publishes
#   exactly one asset: the arm64 build.
#
# WHY THE BUILD STILL PRODUCES THREE FILES LOCALLY
#   The arm64 artifact of a `--split-per-abi` build carries
#   versionCode = 2000 + build number, which is the space installed phones are
#   already in (v1.1.18 + 3 => 2003). A single `--target-platform android-arm64`
#   build instead emits versionCode = build number (e.g. 4), which is LOWER
#   than 2003, and Android rejects it as a downgrade. So: build split,
#   PUBLISH ONE. Never switch to a single-target build unless the pubspec
#   build number is first moved into the 2000s.
#
# USAGE
#   .\release.ps1 -Version 1.1.19 -Notes "<Arabic release notes>"
#       bumps pubspec + AppConfig.appVersion, runs tests, builds, verifies
#       versionName/versionCode with aapt2, stages dist/durus-<v>-arm64.apk
#
#   .\release.ps1 -Version 1.1.19 -Notes "..." -Upload
#       the above, then commits, pushes, creates the GitHub release and
#       asserts the release has exactly ONE asset
#
#   .\release.ps1 -Version 1.1.18 -VerifyApk <path\to\app-arm64-v8a-release.apk>
#       verification only (no build); use to check an existing artifact
#
# NOT automated (do these too - see README "Releases"):
#   * app_meta migration (curated `latest_release` row) + `supabase db push`
#   * web portal: flutter build web --release --base-href /durus/ -> gh-pages
#   * memory/events.md entry

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Notes = '',
    [switch]$Upload,
    [string]$VerifyApk = ''
)

$ErrorActionPreference = 'Stop'

# VersionCode space: arm64-v8a of a split build = 2000 + build number.
$AbiVersionCodeOffset = 2000
# Highest versionCode ever published (v1.1.18 arm64). A release at or below
# this is a downgrade and Android will refuse to install it.
$HighestShippedVersionCode = 2003

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root 'src'
$pubspec = Join-Path $src 'pubspec.yaml'
$config = Join-Path $src 'lib\core\config.dart'
$apkDir = Join-Path $src 'build\app\outputs\flutter-apk'
$arm64Apk = Join-Path $apkDir 'app-arm64-v8a-release.apk'
$dist = Join-Path $root 'dist'

function Get-Aapt2 {
    $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools'
    $hit = Get-ChildItem $sdk -Recurse -Filter aapt2.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $hit) { throw "aapt2.exe not found under $sdk" }
    return $hit.FullName
}

function Get-ApkBadging([string]$Apk) {
    if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }
    $line = & (Get-Aapt2) dump badging $Apk 2>&1 |
        Select-String -Pattern '^package:' | Select-Object -First 1
    if (-not $line) { throw "aapt2 produced no package line for $Apk" }
    $code = [regex]::Match($line.Line, "versionCode='(\d+)'").Groups[1].Value
    $name = [regex]::Match($line.Line, "versionName='([^']+)'").Groups[1].Value
    return [pscustomobject]@{ VersionCode = [int]$code; VersionName = $name }
}

function Assert-Apk([string]$Apk, [string]$Version, [int]$BuildNumber, [switch]$AllowShipped) {
    $info = Get-ApkBadging $Apk
    $expectedCode = $AbiVersionCodeOffset + $BuildNumber
    Write-Host "  versionName : $($info.VersionName)   (expected $Version)"
    Write-Host "  versionCode : $($info.VersionCode)   (expected $expectedCode = 2000 + $BuildNumber)"

    if ($info.VersionName -ne $Version) {
        throw "versionName mismatch: APK says '$($info.VersionName)', expected '$Version'. Bump AppConfig.appVersion / pubspec."
    }
    if ($info.VersionCode -ne $expectedCode) {
        throw "versionCode mismatch: APK says $($info.VersionCode), expected $expectedCode. If the Flutter split offset changed, fix AbiVersionCodeOffset before shipping."
    }
    if (-not $AllowShipped -and $info.VersionCode -le $HighestShippedVersionCode) {
        throw "versionCode $($info.VersionCode) is not above the last shipped $HighestShippedVersionCode, so Android would refuse it as a downgrade. Bump the pubspec build number."
    }
    return $info
}

# ---------- verify-only mode ----------
if ($VerifyApk) {
    $m = [regex]::Match((Get-Content $pubspec -Raw), 'version:\s*[\d.]+\+(\d+)')
    if (-not $m.Success) { throw "cannot read build number from $pubspec" }
    "verifying $VerifyApk"
    # -AllowShipped: auditing an artifact that is already live is legitimate;
    # the downgrade floor only guards what we are about to publish.
    $null = Assert-Apk $VerifyApk $Version ([int]$m.Groups[1].Value) -AllowShipped
    "OK - artifact verifies."
    exit 0
}

# ---------- read + bump the version ----------
$raw = Get-Content $pubspec -Raw
$m = [regex]::Match($raw, 'version:\s*([\d.]+)\+(\d+)')
if (-not $m.Success) { throw "cannot read version from $pubspec" }
$oldVersion = $m.Groups[1].Value
$oldBuild = [int]$m.Groups[2].Value
$newBuild = $oldBuild + 1

if (($newBuild + $AbiVersionCodeOffset) -le $HighestShippedVersionCode) {
    throw "new versionCode $($newBuild + $AbiVersionCodeOffset) would not exceed the last shipped $HighestShippedVersionCode"
}

"bumping $oldVersion+$oldBuild -> $Version+$newBuild (arm64 versionCode $($AbiVersionCodeOffset + $newBuild))"
$raw -replace "version:\s*[\d.]+\+\d+", "version: $Version+$newBuild" | Set-Content $pubspec -NoNewline

$cfg = Get-Content $config -Raw
if ($cfg -notmatch "appVersion = '[\d.]+'") { throw "cannot find appVersion in $config" }
$cfg -replace "appVersion = '[\d.]+'", "appVersion = '$Version'" | Set-Content $config -NoNewline

# ---------- tests, then build ----------
"running tests..."
Push-Location $src
try {
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "tests failed - release aborted" }

    "building split APKs (only the arm64 one is published)..."
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }
}
finally {
    Pop-Location
}

# ---------- verify + stage exactly one artifact ----------
"verifying $arm64Apk"
$size = [Math]::Round((Get-Item $arm64Apk).Length / 1MB, 1)
$null = Assert-Apk $arm64Apk $Version $newBuild

New-Item -ItemType Directory -Force -Path $dist | Out-Null
$staged = Join-Path $dist "durus-$Version-arm64.apk"
Copy-Item $arm64Apk $staged -Force
"staged: $staged ($size MB)"

if (-not $Upload) {
    ""
    "Built and verified. Publish with:"
    "  gh release create v$Version `"$staged`" --title `"Durus v$Version`" --notes `"$Notes`""
    "then confirm the release has exactly ONE asset."
    exit 0
}

# ---------- publish ----------
Push-Location $root
try {
    git add src/pubspec.yaml src/lib/core/config.dart
    git commit -m "release: v$Version (version bump)"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    git push
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }

    # Push BEFORE tagging: `gh release create` tags the remote default-branch
    # tip, which once tagged a stale commit (v1.1.8 lesson).
    gh release create "v$Version" $staged --title "Durus v$Version" --notes $Notes
    if ($LASTEXITCODE -ne 0) { throw "gh release create failed" }
}
finally {
    Pop-Location
}

$assets = gh release view "v$Version" --json assets --jq '.assets | length'
if ([int]$assets -ne 1) {
    throw "release v$Version has $assets assets, expected exactly 1 (the arm64 APK)"
}
"published v$Version with exactly 1 asset."
"still to do: app_meta migration + db push, web -> gh-pages, memory entry."
