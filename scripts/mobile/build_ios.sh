#!/bin/bash
#===============================================================================
# Direct Cuts - iOS Production Build Script
#===============================================================================
# This script builds a production-ready iOS IPA for the Direct Cuts Flutter
# application, suitable for TestFlight and App Store distribution.
#
# Requirements:
#   - macOS with Xcode 15+ installed
#   - Flutter SDK installed and in PATH
#   - Valid Apple Developer account
#   - Provisioning profiles configured (automatic or manual)
#   - Required environment variables set
#
# Usage:
#   ./build_ios.sh [options]
#
# Options:
#   --no-codesign      Build without code signing (for CI)
#   --export-method    Export method: app-store, ad-hoc, development (default: app-store)
#   --skip-clean       Skip flutter clean step
#   --skip-tests       Skip running tests before build
#   --verbose          Enable verbose output
#   --help             Show this help message
#
# Environment Variables (REQUIRED):
#   ONESIGNAL_APP_ID      - OneSignal App ID for push notifications
#   MAPBOX_ACCESS_TOKEN   - Mapbox access token for maps
#
# Environment Variables (OPTIONAL - for CI/CD):
#   APPLE_TEAM_ID              - Apple Developer Team ID
#   IOS_DISTRIBUTION_CERT      - Path to distribution certificate (.p12)
#   IOS_PROVISIONING_PROFILE   - Path to provisioning profile
#
#===============================================================================

set -e  # Exit on error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_START_TIME=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build options (defaults)
NO_CODESIGN=false
EXPORT_METHOD="app-store"
SKIP_CLEAN=false
SKIP_TESTS=false
VERBOSE=false

# App configuration
BUNDLE_ID="com.directcuts.app"
APP_NAME="Direct Cuts"
SCHEME="Runner"

#===============================================================================
# Helper Functions
#===============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

show_help() {
    head -55 "$0" | grep -E "^#" | sed 's/^#//'
    exit 0
}

fail_build() {
    print_error "$1"
    echo ""
    print_error "BUILD FAILED"
    exit 1
}

#===============================================================================
# Parse Command Line Arguments
#===============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-codesign)
            NO_CODESIGN=true
            shift
            ;;
        --export-method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        --skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            print_warning "Unknown option: $1"
            shift
            ;;
    esac
done

#===============================================================================
# Pre-Build Validation
#===============================================================================

print_header "Direct Cuts - iOS Production Build"

print_step "Validating environment..."

# Check we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    fail_build "iOS builds require macOS. Current OS: $(uname)"
fi

# Change to project root
cd "$PROJECT_ROOT"
print_info "Project root: $PROJECT_ROOT"

# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
    fail_build "Flutter is not installed or not in PATH"
fi

FLUTTER_VERSION=$(flutter --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4 || flutter --version | head -1)
print_info "Flutter version: $FLUTTER_VERSION"

# Check Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    fail_build "Xcode is not installed or not in PATH"
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
print_info "Xcode version: $XCODE_VERSION"

# Validate Xcode version is 15+
XCODE_MAJOR=$(echo "$XCODE_VERSION" | grep -oE '[0-9]+' | head -1)
if [[ "$XCODE_MAJOR" -lt 15 ]]; then
    fail_build "Xcode 15 or later is required. Found: $XCODE_VERSION"
fi

# Check CocoaPods is installed
if ! command -v pod &> /dev/null; then
    print_warning "CocoaPods is not installed. Installing..."
    sudo gem install cocoapods
fi

POD_VERSION=$(pod --version)
print_info "CocoaPods version: $POD_VERSION"

# Validate pubspec.yaml exists
if [[ ! -f "pubspec.yaml" ]]; then
    fail_build "pubspec.yaml not found. Are you in the Flutter project root?"
fi

# Get version from pubspec.yaml
APP_VERSION=$(grep -E "^version:" pubspec.yaml | sed 's/version: //' | tr -d '[:space:]')
VERSION_NAME=$(echo "$APP_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$APP_VERSION" | cut -d'+' -f2)

print_info "App version: $VERSION_NAME (build $BUILD_NUMBER)"

#===============================================================================
# CRITICAL: Validate Required Environment Variables
#===============================================================================

print_step "Validating required environment variables..."

VALIDATION_FAILED=false

# Check ONESIGNAL_APP_ID - THIS IS CRITICAL
if [[ -z "${ONESIGNAL_APP_ID}" ]]; then
    print_error "ONESIGNAL_APP_ID is NOT SET"
    print_error "Push notifications will NOT work without this!"
    print_error ""
    print_error "Get your App ID from OneSignal Dashboard:"
    print_error "  Settings > Keys & IDs > OneSignal App ID"
    print_error ""
    print_error "Set it with:"
    print_error "  export ONESIGNAL_APP_ID=your-app-id"
    print_error ""
    VALIDATION_FAILED=true
else
    # Validate format (UUID-like)
    if [[ ! "${ONESIGNAL_APP_ID}" =~ ^[a-f0-9-]{36}$ ]]; then
        print_warning "ONESIGNAL_APP_ID format looks unusual: ${ONESIGNAL_APP_ID}"
        print_warning "Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    fi
    print_success "ONESIGNAL_APP_ID is set"
fi

# Check MAPBOX_ACCESS_TOKEN
if [[ -z "${MAPBOX_ACCESS_TOKEN}" ]]; then
    print_error "MAPBOX_ACCESS_TOKEN is NOT SET"
    print_error "Maps will NOT work without this!"
    print_error ""
    print_error "Get your token from Mapbox Dashboard:"
    print_error "  Account > Access Tokens"
    print_error ""
    print_error "Set it with:"
    print_error "  export MAPBOX_ACCESS_TOKEN=your-token"
    print_error ""
    VALIDATION_FAILED=true
else
    # Validate it starts with pk. or sk.
    if [[ ! "${MAPBOX_ACCESS_TOKEN}" =~ ^(pk|sk)\. ]]; then
        print_warning "MAPBOX_ACCESS_TOKEN should start with 'pk.' or 'sk.'"
    fi
    print_success "MAPBOX_ACCESS_TOKEN is set"
fi

# FAIL BUILD if required env vars are missing
if [[ "$VALIDATION_FAILED" == "true" ]]; then
    echo ""
    fail_build "Required environment variables are missing. Cannot proceed with production build."
fi

print_success "All required environment variables are set"

#===============================================================================
# Check Code Signing Configuration
#===============================================================================

if [[ "$NO_CODESIGN" == "false" ]]; then
    print_step "Checking code signing configuration..."

    # Check for development team
    if [[ -n "${APPLE_TEAM_ID}" ]]; then
        print_success "Apple Team ID set: $APPLE_TEAM_ID"
    else
        print_info "APPLE_TEAM_ID not set - will use automatic signing"
        print_info "Make sure you're signed into Xcode with your Apple ID"
    fi

    # Check for available signing identities
    SIGNING_IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "valid identities found" || echo "0")
    print_info "Available signing identities: $(security find-identity -v -p codesigning 2>/dev/null | tail -1 || echo "None found")"
else
    print_info "Code signing disabled (--no-codesign)"
fi

#===============================================================================
# Clean Build (Optional)
#===============================================================================

if [[ "$SKIP_CLEAN" == "false" ]]; then
    print_step "Cleaning previous build artifacts..."
    flutter clean

    # Clean iOS-specific build artifacts
    cd ios
    rm -rf Pods Podfile.lock .symlinks build
    cd ..

    print_success "Clean complete"
else
    print_info "Skipping clean step (--skip-clean)"
fi

#===============================================================================
# Get Dependencies
#===============================================================================

print_step "Getting Flutter dependencies..."
flutter pub get
print_success "Dependencies installed"

#===============================================================================
# Run Code Generation
#===============================================================================

print_step "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs
print_success "Code generation complete"

#===============================================================================
# Install CocoaPods Dependencies
#===============================================================================

print_step "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..
print_success "CocoaPods dependencies installed"

#===============================================================================
# Run Tests (Optional)
#===============================================================================

if [[ "$SKIP_TESTS" == "false" ]]; then
    print_step "Running tests..."
    if flutter test; then
        print_success "All tests passed"
    else
        print_warning "Some tests failed - continuing with build"
        print_warning "Consider fixing tests before releasing"
    fi
else
    print_info "Skipping tests (--skip-tests)"
fi

#===============================================================================
# Analyze Code
#===============================================================================

print_step "Analyzing code for issues..."
if flutter analyze --no-fatal-warnings; then
    print_success "Code analysis passed"
else
    print_warning "Code analysis found warnings - review before release"
fi

#===============================================================================
# Prepare Artifact Directory
#===============================================================================

ARTIFACT_DIR="$PROJECT_ROOT/artifacts/mobile/$VERSION_NAME/ios"
mkdir -p "$ARTIFACT_DIR"
print_info "Artifact directory: $ARTIFACT_DIR"

#===============================================================================
# Build iOS
#===============================================================================

print_header "Building iOS Release"

print_step "Building iOS release with dart-define..."

DART_DEFINES=(
    "--dart-define=ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}"
    "--dart-define=MAPBOX_ACCESS_TOKEN=${MAPBOX_ACCESS_TOKEN}"
    "--dart-define=DEBUG_MODE=false"
)

BUILD_ARGS=("--release" "${DART_DEFINES[@]}")

if [[ "$NO_CODESIGN" == "true" ]]; then
    BUILD_ARGS+=("--no-codesign")
fi

if [[ "$VERBOSE" == "true" ]]; then
    BUILD_ARGS+=("--verbose")
fi

flutter build ios "${BUILD_ARGS[@]}"

print_success "iOS build complete"

#===============================================================================
# Create IPA (Archive and Export)
#===============================================================================

if [[ "$NO_CODESIGN" == "false" ]]; then
    print_header "Creating IPA Archive"

    ARCHIVE_PATH="$PROJECT_ROOT/build/ios/archive/DirectCuts.xcarchive"
    EXPORT_PATH="$PROJECT_ROOT/build/ios/ipa"

    print_step "Creating Xcode archive..."

    cd ios

    # Create archive
    xcodebuild archive \
        -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}" \
        | xcpretty || xcodebuild archive \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -archivePath "$ARCHIVE_PATH" \
            -destination "generic/platform=iOS" \
            CODE_SIGN_STYLE=Automatic

    cd ..

    if [[ -d "$ARCHIVE_PATH" ]]; then
        print_success "Archive created: $ARCHIVE_PATH"

        # Export IPA
        print_step "Exporting IPA for $EXPORT_METHOD distribution..."

        # Create ExportOptions.plist if it doesn't exist
        EXPORT_OPTIONS_PATH="$PROJECT_ROOT/ios/ExportOptions.plist"

        if [[ ! -f "$EXPORT_OPTIONS_PATH" ]]; then
            print_warning "ExportOptions.plist not found, using defaults"
            cat > "$EXPORT_OPTIONS_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-TEAM_ID_PLACEHOLDER}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
        fi

        xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportPath "$EXPORT_PATH" \
            -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
            | xcpretty || xcodebuild -exportArchive \
                -archivePath "$ARCHIVE_PATH" \
                -exportPath "$EXPORT_PATH" \
                -exportOptionsPlist "$EXPORT_OPTIONS_PATH"

        # Copy IPA to artifacts
        IPA_SOURCE="$EXPORT_PATH/DirectCuts.ipa"
        if [[ ! -f "$IPA_SOURCE" ]]; then
            # Try alternative name
            IPA_SOURCE="$EXPORT_PATH/Runner.ipa"
        fi

        if [[ -f "$IPA_SOURCE" ]]; then
            IPA_DEST="$ARTIFACT_DIR/DirectCuts-$VERSION_NAME.ipa"
            cp "$IPA_SOURCE" "$IPA_DEST"
            IPA_SIZE=$(du -h "$IPA_DEST" | cut -f1)
            print_success "IPA created: $IPA_DEST ($IPA_SIZE)"
        else
            print_warning "IPA not found at expected location"
            print_info "Archive is available at: $ARCHIVE_PATH"
        fi
    else
        print_error "Archive creation failed"
    fi
else
    print_info "Skipping IPA creation (--no-codesign mode)"
    print_info "To create an IPA, run without --no-codesign on a Mac with valid signing"

    # Copy the unsigned app bundle as reference
    APP_BUNDLE="$PROJECT_ROOT/build/ios/iphoneos/Runner.app"
    if [[ -d "$APP_BUNDLE" ]]; then
        print_info "Unsigned app bundle available at: $APP_BUNDLE"
    fi
fi

#===============================================================================
# Generate Checksums
#===============================================================================

print_step "Generating SHA-256 checksums..."

CHECKSUM_FILE="$ARTIFACT_DIR/checksums.sha256"
cd "$ARTIFACT_DIR"

# Generate checksums for all artifacts
> "$CHECKSUM_FILE" 2>/dev/null || true
for file in *.ipa; do
    if [[ -f "$file" ]]; then
        shasum -a 256 "$file" >> "$CHECKSUM_FILE"
    fi
done

if [[ -s "$CHECKSUM_FILE" ]]; then
    print_success "Checksums generated: $CHECKSUM_FILE"
    cat "$CHECKSUM_FILE"
else
    print_info "No IPA artifacts to checksum"
fi

cd "$PROJECT_ROOT"

#===============================================================================
# Generate Build Manifest
#===============================================================================

print_step "Generating build manifest..."

BUILD_END_TIME=$(date +%s)
BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

MANIFEST_FILE="$ARTIFACT_DIR/build-manifest.json"

cat > "$MANIFEST_FILE" << EOF
{
  "app_name": "Direct Cuts",
  "bundle_id": "$BUNDLE_ID",
  "version_name": "$VERSION_NAME",
  "build_number": "$BUILD_NUMBER",
  "platform": "ios",
  "build_type": "release",
  "export_method": "$EXPORT_METHOD",
  "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_duration_seconds": $BUILD_DURATION,
  "git_commit": "$GIT_COMMIT",
  "git_branch": "$GIT_BRANCH",
  "flutter_version": "$FLUTTER_VERSION",
  "xcode_version": "$XCODE_VERSION",
  "codesigned": $([[ "$NO_CODESIGN" == "false" ]] && echo "true" || echo "false"),
  "artifacts": {
    "ipa": "$([[ -f "$ARTIFACT_DIR/DirectCuts-$VERSION_NAME.ipa" ]] && echo "DirectCuts-$VERSION_NAME.ipa" || echo "null")"
  },
  "environment": {
    "onesignal_configured": true,
    "mapbox_configured": true,
    "debug_mode": false
  }
}
EOF

print_success "Build manifest: $MANIFEST_FILE"

#===============================================================================
# Build Summary
#===============================================================================

print_header "Build Complete"

echo -e "${GREEN}BUILD SUCCESSFUL${NC}"
echo ""
echo "Version: $VERSION_NAME (build $BUILD_NUMBER)"
echo "Duration: ${BUILD_DURATION}s"
echo "Git commit: $GIT_COMMIT"
echo "Export method: $EXPORT_METHOD"
echo ""
echo "Artifacts:"
echo "  Directory: $ARTIFACT_DIR"

if [[ -f "$ARTIFACT_DIR/DirectCuts-$VERSION_NAME.ipa" ]]; then
    IPA_SIZE=$(du -h "$ARTIFACT_DIR/DirectCuts-$VERSION_NAME.ipa" | cut -f1)
    echo "  IPA: DirectCuts-$VERSION_NAME.ipa ($IPA_SIZE)"
fi

if [[ "$NO_CODESIGN" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}NOTE: Build completed without code signing${NC}"
    echo "To distribute via TestFlight or App Store, rebuild on macOS with signing"
fi

echo ""
echo "Next Steps:"
if [[ "$NO_CODESIGN" == "false" ]]; then
    echo "  1. Upload IPA to App Store Connect using Transporter or 'xcrun altool'"
    echo "  2. Submit for TestFlight review"
    echo "  3. Verify checksums before distribution"
else
    echo "  1. Configure code signing on a Mac with valid Apple Developer account"
    echo "  2. Rebuild with signing to create distributable IPA"
fi
echo ""
