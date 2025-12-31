#===============================================================================
# Direct Cuts - Android Production Build Script (PowerShell)
#===============================================================================
# This script builds a production-ready Android APK and AAB (App Bundle)
# for the Direct Cuts Flutter application.
#
# Requirements:
#   - Flutter SDK installed and in PATH
#   - Java 17+ installed
#   - Android SDK with build-tools
#   - Required environment variables set
#
# Usage:
#   .\build_android.ps1 [options]
#
# Options:
#   -ApkOnly       Build only APK (skip AAB)
#   -AabOnly       Build only AAB (skip APK)
#   -SkipClean     Skip flutter clean step
#   -SkipTests     Skip running tests before build
#   -Verbose       Enable verbose output
#   -Help          Show this help message
#
# Environment Variables (REQUIRED):
#   ONESIGNAL_APP_ID      - OneSignal App ID for push notifications
#   MAPBOX_ACCESS_TOKEN   - Mapbox access token for maps
#
#===============================================================================

param(
    [switch]$ApkOnly,
    [switch]$AabOnly,
    [switch]$SkipClean,
    [switch]$SkipTests,
    [switch]$Verbose,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Script configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..").FullName
$BuildStartTime = Get-Date

# Build options
$BuildApk = -not $AabOnly
$BuildAab = -not $ApkOnly

#===============================================================================
# Helper Functions
#===============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Exit-Build {
    param([string]$Message)
    Write-Error $Message
    Write-Host ""
    Write-Error "BUILD FAILED"
    exit 1
}

function Show-Help {
    Get-Help $MyInvocation.ScriptName -Detailed
    exit 0
}

if ($Help) {
    Write-Host @"
Direct Cuts - Android Production Build Script

USAGE:
    .\build_android.ps1 [options]

OPTIONS:
    -ApkOnly       Build only APK (skip AAB)
    -AabOnly       Build only AAB (skip APK)
    -SkipClean     Skip flutter clean step
    -SkipTests     Skip running tests before build
    -Verbose       Enable verbose output
    -Help          Show this help message

ENVIRONMENT VARIABLES (REQUIRED):
    ONESIGNAL_APP_ID      - OneSignal App ID for push notifications
    MAPBOX_ACCESS_TOKEN   - Mapbox access token for maps

EXAMPLES:
    .\build_android.ps1                    # Full build (APK + AAB)
    .\build_android.ps1 -ApkOnly           # APK only
    .\build_android.ps1 -AabOnly           # AAB only for Play Store
    .\build_android.ps1 -SkipClean -SkipTests  # Quick build
"@
    exit 0
}

#===============================================================================
# Pre-Build Validation
#===============================================================================

Write-Header "Direct Cuts - Android Production Build"

Write-Step "Validating environment..."

# Change to project root
Set-Location $ProjectRoot
Write-Info "Project root: $ProjectRoot"

# Check Flutter is installed
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Info "Flutter: $flutterVersion"
} catch {
    Exit-Build "Flutter is not installed or not in PATH"
}

# Check Java is installed
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Info "Java: $javaVersion"
} catch {
    Exit-Build "Java is not installed or not in PATH"
}

# Validate pubspec.yaml exists
if (-not (Test-Path "pubspec.yaml")) {
    Exit-Build "pubspec.yaml not found. Are you in the Flutter project root?"
}

# Get version from pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
    $VersionName = $Matches[1]
    $BuildNumber = $Matches[2]
} else {
    Exit-Build "Could not parse version from pubspec.yaml"
}

Write-Info "App version: $VersionName (build $BuildNumber)"

#===============================================================================
# CRITICAL: Validate Required Environment Variables
#===============================================================================

Write-Step "Validating required environment variables..."

$ValidationFailed = $false

# Check ONESIGNAL_APP_ID
if ([string]::IsNullOrEmpty($env:ONESIGNAL_APP_ID)) {
    Write-Error "ONESIGNAL_APP_ID is NOT SET"
    Write-Error "Push notifications will NOT work without this!"
    Write-Error ""
    Write-Error "Get your App ID from OneSignal Dashboard:"
    Write-Error "  Settings > Keys & IDs > OneSignal App ID"
    Write-Error ""
    Write-Error "Set it with:"
    Write-Error '  $env:ONESIGNAL_APP_ID = "your-app-id"'
    Write-Error ""
    $ValidationFailed = $true
} else {
    Write-Success "ONESIGNAL_APP_ID is set"
}

# Check MAPBOX_ACCESS_TOKEN
if ([string]::IsNullOrEmpty($env:MAPBOX_ACCESS_TOKEN)) {
    Write-Error "MAPBOX_ACCESS_TOKEN is NOT SET"
    Write-Error "Maps will NOT work without this!"
    Write-Error ""
    Write-Error "Get your token from Mapbox Dashboard:"
    Write-Error "  Account > Access Tokens"
    Write-Error ""
    Write-Error "Set it with:"
    Write-Error '  $env:MAPBOX_ACCESS_TOKEN = "your-token"'
    Write-Error ""
    $ValidationFailed = $true
} else {
    Write-Success "MAPBOX_ACCESS_TOKEN is set"
}

# FAIL BUILD if required env vars are missing
if ($ValidationFailed) {
    Write-Host ""
    Exit-Build "Required environment variables are missing. Cannot proceed with production build."
}

Write-Success "All required environment variables are set"

#===============================================================================
# Validate Signing Configuration
#===============================================================================

Write-Step "Checking signing configuration..."

$KeystorePath = "$ProjectRoot\android\app\release.keystore"
$KeyPropertiesPath = "$ProjectRoot\android\key.properties"

if (Test-Path $KeystorePath) {
    Write-Success "Keystore found: $KeystorePath"

    if (Test-Path $KeyPropertiesPath) {
        Write-Success "key.properties found"
    } else {
        Write-Warning "key.properties not found at $KeyPropertiesPath"
        Write-Info "Build will use debug signing (not suitable for Play Store)"
    }
} else {
    Write-Warning "Release keystore not found at: $KeystorePath"
    Write-Info "Build will use debug signing (not suitable for Play Store)"
    Write-Info ""
    Write-Info "To create a production keystore, run:"
    Write-Info "  .\scripts\mobile\create_keystore.sh (bash)"
}

#===============================================================================
# Clean Build (Optional)
#===============================================================================

if (-not $SkipClean) {
    Write-Step "Cleaning previous build artifacts..."
    flutter clean
    Write-Success "Clean complete"
} else {
    Write-Info "Skipping clean step (-SkipClean)"
}

#===============================================================================
# Get Dependencies
#===============================================================================

Write-Step "Getting Flutter dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) { Exit-Build "Failed to get dependencies" }
Write-Success "Dependencies installed"

#===============================================================================
# Run Code Generation
#===============================================================================

Write-Step "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Warning "Code generation had issues" }
Write-Success "Code generation complete"

#===============================================================================
# Run Tests (Optional)
#===============================================================================

if (-not $SkipTests) {
    Write-Step "Running tests..."
    flutter test
    if ($LASTEXITCODE -eq 0) {
        Write-Success "All tests passed"
    } else {
        Write-Warning "Some tests failed - continuing with build"
    }
} else {
    Write-Info "Skipping tests (-SkipTests)"
}

#===============================================================================
# Analyze Code
#===============================================================================

Write-Step "Analyzing code for issues..."
flutter analyze --no-fatal-warnings
if ($LASTEXITCODE -eq 0) {
    Write-Success "Code analysis passed"
} else {
    Write-Warning "Code analysis found warnings - review before release"
}

#===============================================================================
# Prepare Artifact Directory
#===============================================================================

$ArtifactDir = "$ProjectRoot\artifacts\mobile\$VersionName\android"
if (-not (Test-Path $ArtifactDir)) {
    New-Item -ItemType Directory -Path $ArtifactDir -Force | Out-Null
}
Write-Info "Artifact directory: $ArtifactDir"

#===============================================================================
# Build Android APK
#===============================================================================

if ($BuildApk) {
    Write-Header "Building Android APK"

    Write-Step "Building release APK with dart-define..."

    $dartDefines = @(
        "--dart-define=ONESIGNAL_APP_ID=$env:ONESIGNAL_APP_ID",
        "--dart-define=MAPBOX_ACCESS_TOKEN=$env:MAPBOX_ACCESS_TOKEN",
        "--dart-define=DEBUG_MODE=false"
    )

    if ($Verbose) {
        flutter build apk --release @dartDefines --verbose
    } else {
        flutter build apk --release @dartDefines
    }

    if ($LASTEXITCODE -ne 0) { Exit-Build "APK build failed" }

    # Copy APK to artifacts
    $ApkSource = "$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"
    $ApkDest = "$ArtifactDir\direct-cuts-$VersionName.apk"

    if (Test-Path $ApkSource) {
        Copy-Item $ApkSource $ApkDest -Force
        $ApkSize = (Get-Item $ApkDest).Length / 1MB
        Write-Success "APK built: $ApkDest ($([math]::Round($ApkSize, 2)) MB)"
    } else {
        Write-Error "APK not found at expected location: $ApkSource"
    }
}

#===============================================================================
# Build Android App Bundle (AAB)
#===============================================================================

if ($BuildAab) {
    Write-Header "Building Android App Bundle (AAB)"

    Write-Step "Building release AAB with dart-define..."

    $dartDefines = @(
        "--dart-define=ONESIGNAL_APP_ID=$env:ONESIGNAL_APP_ID",
        "--dart-define=MAPBOX_ACCESS_TOKEN=$env:MAPBOX_ACCESS_TOKEN",
        "--dart-define=DEBUG_MODE=false"
    )

    if ($Verbose) {
        flutter build appbundle --release @dartDefines --verbose
    } else {
        flutter build appbundle --release @dartDefines
    }

    if ($LASTEXITCODE -ne 0) { Exit-Build "AAB build failed" }

    # Copy AAB to artifacts
    $AabSource = "$ProjectRoot\build\app\outputs\bundle\release\app-release.aab"
    $AabDest = "$ArtifactDir\direct-cuts-$VersionName.aab"

    if (Test-Path $AabSource) {
        Copy-Item $AabSource $AabDest -Force
        $AabSize = (Get-Item $AabDest).Length / 1MB
        Write-Success "AAB built: $AabDest ($([math]::Round($AabSize, 2)) MB)"
    } else {
        Write-Error "AAB not found at expected location: $AabSource"
    }
}

#===============================================================================
# Generate Checksums
#===============================================================================

Write-Step "Generating SHA-256 checksums..."

$ChecksumFile = "$ArtifactDir\checksums.sha256"
$checksums = @()

Get-ChildItem "$ArtifactDir\*.apk", "$ArtifactDir\*.aab" -ErrorAction SilentlyContinue | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    $checksums += "$hash  $($_.Name)"
}

if ($checksums.Count -gt 0) {
    $checksums | Out-File $ChecksumFile -Encoding utf8
    Write-Success "Checksums generated: $ChecksumFile"
    $checksums | ForEach-Object { Write-Host $_ }
} else {
    Write-Warning "No artifacts to checksum"
}

#===============================================================================
# Generate Build Manifest
#===============================================================================

Write-Step "Generating build manifest..."

$BuildEndTime = Get-Date
$BuildDuration = ($BuildEndTime - $BuildStartTime).TotalSeconds

try {
    $GitCommit = git rev-parse HEAD 2>$null
    $GitBranch = git rev-parse --abbrev-ref HEAD 2>$null
} catch {
    $GitCommit = "unknown"
    $GitBranch = "unknown"
}

$ApkFile = if (Test-Path "$ArtifactDir\direct-cuts-$VersionName.apk") { "direct-cuts-$VersionName.apk" } else { "null" }
$AabFile = if (Test-Path "$ArtifactDir\direct-cuts-$VersionName.aab") { "direct-cuts-$VersionName.aab" } else { "null" }

$manifest = @{
    app_name = "Direct Cuts"
    package_name = "com.directcuts.app"
    version_name = $VersionName
    build_number = $BuildNumber
    platform = "android"
    build_type = "release"
    build_timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    build_duration_seconds = [math]::Round($BuildDuration, 0)
    git_commit = $GitCommit
    git_branch = $GitBranch
    artifacts = @{
        apk = $ApkFile
        aab = $AabFile
    }
    environment = @{
        onesignal_configured = $true
        mapbox_configured = $true
        debug_mode = $false
    }
}

$manifest | ConvertTo-Json -Depth 3 | Out-File "$ArtifactDir\build-manifest.json" -Encoding utf8
Write-Success "Build manifest: $ArtifactDir\build-manifest.json"

#===============================================================================
# Build Summary
#===============================================================================

Write-Header "Build Complete"

Write-Host "BUILD SUCCESSFUL" -ForegroundColor Green
Write-Host ""
Write-Host "Version: $VersionName (build $BuildNumber)"
Write-Host "Duration: $([math]::Round($BuildDuration, 0))s"
Write-Host "Git commit: $GitCommit"
Write-Host ""
Write-Host "Artifacts:"
Write-Host "  Directory: $ArtifactDir"

if (Test-Path "$ArtifactDir\direct-cuts-$VersionName.apk") {
    $ApkSize = [math]::Round((Get-Item "$ArtifactDir\direct-cuts-$VersionName.apk").Length / 1MB, 2)
    Write-Host "  APK: direct-cuts-$VersionName.apk ($ApkSize MB)"
}

if (Test-Path "$ArtifactDir\direct-cuts-$VersionName.aab") {
    $AabSize = [math]::Round((Get-Item "$ArtifactDir\direct-cuts-$VersionName.aab").Length / 1MB, 2)
    Write-Host "  AAB: direct-cuts-$VersionName.aab ($AabSize MB)"
}

Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Test APK: adb install $ArtifactDir\direct-cuts-$VersionName.apk"
Write-Host "  2. Upload AAB to Google Play Console"
Write-Host "  3. Verify checksums before distribution"
Write-Host ""
