#===============================================================================
# Direct Cuts - Version Bumping Script (PowerShell)
#===============================================================================
# This script manages semantic versioning for the Flutter application.
# It updates pubspec.yaml and optionally creates a git tag.
#
# Usage:
#   .\bump_version.ps1 -BumpType <major|minor|patch>
#   .\bump_version.ps1 -SetVersion 2.1.0
#
# Examples:
#   .\bump_version.ps1 -BumpType patch           # 2.0.0 -> 2.0.1
#   .\bump_version.ps1 -BumpType minor           # 2.0.1 -> 2.1.0
#   .\bump_version.ps1 -BumpType major           # 2.1.0 -> 3.0.0
#   .\bump_version.ps1 -SetVersion 2.5.0         # Set specific version
#   .\bump_version.ps1 -BumpType patch -Tag      # Bump and create git tag
#
#===============================================================================

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$BumpType,
    [string]$SetVersion,
    [int]$BuildNumber = 0,
    [switch]$Tag,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Script configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..").FullName

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

function Exit-Script {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

if ($Help) {
    Write-Host @"
Direct Cuts - Version Bump Script

USAGE:
    .\bump_version.ps1 -BumpType <major|minor|patch> [options]
    .\bump_version.ps1 -SetVersion <version> [options]

OPTIONS:
    -BumpType       Type of version bump: major, minor, or patch
    -SetVersion     Set a specific version (e.g., 2.1.0)
    -BuildNumber    Set specific build number (default: auto from git)
    -Tag            Create and push git tag
    -DryRun         Show what would change without modifying files
    -Help           Show this help message

EXAMPLES:
    .\bump_version.ps1 -BumpType patch           # 2.0.0 -> 2.0.1
    .\bump_version.ps1 -BumpType minor           # 2.0.1 -> 2.1.0
    .\bump_version.ps1 -BumpType major           # 2.1.0 -> 3.0.0
    .\bump_version.ps1 -SetVersion 2.5.0         # Set to 2.5.0
    .\bump_version.ps1 -BumpType patch -Tag      # Bump and create git tag
"@
    exit 0
}

# Validate arguments
if ([string]::IsNullOrEmpty($BumpType) -and [string]::IsNullOrEmpty($SetVersion)) {
    Write-Error "Usage: .\bump_version.ps1 -BumpType <major|minor|patch>"
    Write-Error "       .\bump_version.ps1 -SetVersion <version>"
    Write-Host ""
    Write-Host "Run '.\bump_version.ps1 -Help' for more information."
    exit 1
}

#===============================================================================
# Read Current Version
#===============================================================================

Write-Header "Direct Cuts - Version Bump"

Set-Location $ProjectRoot

$PubspecPath = "$ProjectRoot\pubspec.yaml"

if (-not (Test-Path $PubspecPath)) {
    Exit-Script "pubspec.yaml not found at: $PubspecPath"
}

# Extract current version
$pubspecContent = Get-Content $PubspecPath -Raw
if ($pubspecContent -match "version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)") {
    $CurrentMajor = [int]$Matches[1]
    $CurrentMinor = [int]$Matches[2]
    $CurrentPatch = [int]$Matches[3]
    $CurrentBuild = [int]$Matches[4]
    $CurrentVersionName = "$CurrentMajor.$CurrentMinor.$CurrentPatch"
    $CurrentVersion = "$CurrentVersionName+$CurrentBuild"
} else {
    Exit-Script "Could not parse version from pubspec.yaml"
}

Write-Info "Current version: $CurrentVersionName+$CurrentBuild"
Write-Info "  Major: $CurrentMajor"
Write-Info "  Minor: $CurrentMinor"
Write-Info "  Patch: $CurrentPatch"
Write-Info "  Build: $CurrentBuild"

#===============================================================================
# Calculate New Version
#===============================================================================

Write-Step "Calculating new version..."

if (-not [string]::IsNullOrEmpty($SetVersion)) {
    # Validate version format
    if ($SetVersion -notmatch "^\d+\.\d+\.\d+$") {
        Exit-Script "Invalid version format. Use: MAJOR.MINOR.PATCH (e.g., 2.1.0)"
    }

    $parts = $SetVersion.Split(".")
    $NewMajor = [int]$parts[0]
    $NewMinor = [int]$parts[1]
    $NewPatch = [int]$parts[2]
    $NewVersionName = $SetVersion
} else {
    # Bump version based on type
    $NewMajor = $CurrentMajor
    $NewMinor = $CurrentMinor
    $NewPatch = $CurrentPatch

    switch ($BumpType) {
        "major" {
            $NewMajor = $CurrentMajor + 1
            $NewMinor = 0
            $NewPatch = 0
        }
        "minor" {
            $NewMinor = $CurrentMinor + 1
            $NewPatch = 0
        }
        "patch" {
            $NewPatch = $CurrentPatch + 1
        }
    }

    $NewVersionName = "$NewMajor.$NewMinor.$NewPatch"
}

# Calculate build number
if ($BuildNumber -gt 0) {
    $NewBuild = $BuildNumber
} else {
    # Use git commit count for reproducible builds
    try {
        $NewBuild = [int](git rev-list --count HEAD 2>$null)
    } catch {
        $NewBuild = $CurrentBuild + 1
    }
}

$NewVersion = "$NewVersionName+$NewBuild"

Write-Host ""
Write-Host "Version change: " -NoNewline
Write-Host "$CurrentVersion" -ForegroundColor Yellow -NoNewline
Write-Host " -> " -NoNewline
Write-Host "$NewVersion" -ForegroundColor Green
Write-Host ""

#===============================================================================
# Dry Run Check
#===============================================================================

if ($DryRun) {
    Write-Warning "DRY RUN - No changes will be made"
    Write-Host ""
    Write-Host "Would update:"
    Write-Host "  pubspec.yaml: version: $NewVersion"
    Write-Host "  lib\config\app_config.dart: appVersion = '$NewVersionName'"

    if ($Tag) {
        Write-Host "  Git tag: v$NewVersionName"
    }

    exit 0
}

#===============================================================================
# Update pubspec.yaml
#===============================================================================

Write-Step "Updating pubspec.yaml..."

$pubspecContent = $pubspecContent -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $NewVersion"
$pubspecContent | Set-Content $PubspecPath -NoNewline

# Verify the change
$verifyContent = Get-Content $PubspecPath -Raw
if ($verifyContent -match "version:\s*$([regex]::Escape($NewVersion))") {
    Write-Success "pubspec.yaml updated"
} else {
    Exit-Script "Failed to update pubspec.yaml"
}

#===============================================================================
# Update app_config.dart
#===============================================================================

Write-Step "Updating app_config.dart..."

$AppConfigPath = "$ProjectRoot\lib\config\app_config.dart"

if (Test-Path $AppConfigPath) {
    $configContent = Get-Content $AppConfigPath -Raw
    $configContent = $configContent -replace "static const String appVersion = '[^']*'", "static const String appVersion = '$NewVersionName'"
    $configContent | Set-Content $AppConfigPath -NoNewline
    Write-Success "app_config.dart updated"
} else {
    Write-Warning "app_config.dart not found - skipping"
}

#===============================================================================
# Create Git Tag
#===============================================================================

if ($Tag) {
    Write-Step "Creating git tag..."

    try {
        git rev-parse --git-dir 2>$null | Out-Null
    } catch {
        Write-Warning "Not a git repository - skipping tag creation"
        $Tag = $false
    }

    if ($Tag) {
        $TagName = "v$NewVersionName"

        # Check if tag already exists
        $existingTag = git rev-parse $TagName 2>$null
        if ($existingTag) {
            Write-Warning "Tag $TagName already exists"
            $confirm = Read-Host "Delete and recreate? [y/N]"
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                git tag -d $TagName
                Write-Info "Deleted existing tag"
            } else {
                Write-Info "Skipping tag creation"
                $Tag = $false
            }
        }

        if ($Tag) {
            # Stage and commit changes
            git add $PubspecPath
            if (Test-Path $AppConfigPath) {
                git add $AppConfigPath
            }

            try {
                git commit -m "chore: bump version to $NewVersionName"
            } catch {
                Write-Info "Nothing to commit"
            }

            # Create annotated tag
            $tagMessage = @"
Release $NewVersionName

Build: $NewBuild
Date: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
"@
            git tag -a $TagName -m $tagMessage

            Write-Success "Created tag: $TagName"

            $pushConfirm = Read-Host "Push tag to remote? [y/N]"
            if ($pushConfirm -eq "y" -or $pushConfirm -eq "Y") {
                git push origin $TagName
                Write-Success "Pushed tag to remote"
            }
        }
    }
}

#===============================================================================
# Summary
#===============================================================================

Write-Header "Version Bump Complete"

Write-Host "SUCCESS! Version updated." -ForegroundColor Green
Write-Host ""
Write-Host "Previous: $CurrentVersion"
Write-Host "New:      $NewVersion"
Write-Host ""
Write-Host "Updated files:"
Write-Host "  - pubspec.yaml"
if (Test-Path $AppConfigPath) {
    Write-Host "  - lib\config\app_config.dart"
}

if ($Tag) {
    Write-Host "  - Git tag: v$NewVersionName"
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review changes: git diff"
Write-Host "  2. Commit: git add -A && git commit -m 'chore: bump version to $NewVersionName'"
Write-Host "  3. Build: .\scripts\mobile\build_android.ps1"
Write-Host ""
