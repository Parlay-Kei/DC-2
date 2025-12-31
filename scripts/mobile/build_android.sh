#!/bin/bash
#===============================================================================
# Direct Cuts - Android Production Build Script
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
#   ./build_android.sh [options]
#
# Options:
#   --apk-only      Build only APK (skip AAB)
#   --aab-only      Build only AAB (skip APK)
#   --skip-clean    Skip flutter clean step
#   --skip-tests    Skip running tests before build
#   --verbose       Enable verbose output
#   --help          Show this help message
#
# Environment Variables (REQUIRED):
#   ONESIGNAL_APP_ID      - OneSignal App ID for push notifications
#   MAPBOX_ACCESS_TOKEN   - Mapbox access token for maps
#
# Environment Variables (OPTIONAL):
#   ANDROID_KEYSTORE_PATH     - Path to release keystore (defaults to android/app/release.keystore)
#   ANDROID_KEYSTORE_PASSWORD - Keystore password
#   ANDROID_KEY_ALIAS         - Key alias in keystore
#   ANDROID_KEY_PASSWORD      - Key password
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
BUILD_APK=true
BUILD_AAB=true
SKIP_CLEAN=false
SKIP_TESTS=false
VERBOSE=false

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
    head -50 "$0" | grep -E "^#" | sed 's/^#//'
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
        --apk-only)
            BUILD_APK=true
            BUILD_AAB=false
            shift
            ;;
        --aab-only)
            BUILD_APK=false
            BUILD_AAB=true
            shift
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

print_header "Direct Cuts - Android Production Build"

print_step "Validating environment..."

# Change to project root
cd "$PROJECT_ROOT"
print_info "Project root: $PROJECT_ROOT"

# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
    fail_build "Flutter is not installed or not in PATH"
fi

FLUTTER_VERSION=$(flutter --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4 || flutter --version | head -1)
print_info "Flutter version: $FLUTTER_VERSION"

# Check Java is installed
if ! command -v java &> /dev/null; then
    fail_build "Java is not installed or not in PATH"
fi

JAVA_VERSION=$(java -version 2>&1 | head -1)
print_info "Java version: $JAVA_VERSION"

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
# Validate Signing Configuration
#===============================================================================

print_step "Checking signing configuration..."

KEYSTORE_PATH="${ANDROID_KEYSTORE_PATH:-$PROJECT_ROOT/android/app/release.keystore}"
KEY_PROPERTIES_PATH="$PROJECT_ROOT/android/key.properties"

if [[ -f "$KEYSTORE_PATH" ]]; then
    print_success "Keystore found: $KEYSTORE_PATH"

    # Check key.properties exists
    if [[ -f "$KEY_PROPERTIES_PATH" ]]; then
        print_success "key.properties found"
    else
        print_warning "key.properties not found at $KEY_PROPERTIES_PATH"
        print_info "Build will use debug signing (not suitable for Play Store)"
    fi
else
    print_warning "Release keystore not found at: $KEYSTORE_PATH"
    print_info "Build will use debug signing (not suitable for Play Store)"
    print_info ""
    print_info "To create a production keystore, run:"
    print_info "  ./scripts/mobile/create_keystore.sh"
fi

#===============================================================================
# Clean Build (Optional)
#===============================================================================

if [[ "$SKIP_CLEAN" == "false" ]]; then
    print_step "Cleaning previous build artifacts..."
    flutter clean
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

ARTIFACT_DIR="$PROJECT_ROOT/artifacts/mobile/$VERSION_NAME/android"
mkdir -p "$ARTIFACT_DIR"
print_info "Artifact directory: $ARTIFACT_DIR"

#===============================================================================
# Build Android APK
#===============================================================================

if [[ "$BUILD_APK" == "true" ]]; then
    print_header "Building Android APK"

    print_step "Building release APK with dart-define..."

    DART_DEFINES=(
        "--dart-define=ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}"
        "--dart-define=MAPBOX_ACCESS_TOKEN=${MAPBOX_ACCESS_TOKEN}"
        "--dart-define=DEBUG_MODE=false"
    )

    if [[ "$VERBOSE" == "true" ]]; then
        flutter build apk --release "${DART_DEFINES[@]}" --verbose
    else
        flutter build apk --release "${DART_DEFINES[@]}"
    fi

    # Copy APK to artifacts
    APK_SOURCE="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
    APK_DEST="$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.apk"

    if [[ -f "$APK_SOURCE" ]]; then
        cp "$APK_SOURCE" "$APK_DEST"
        APK_SIZE=$(du -h "$APK_DEST" | cut -f1)
        print_success "APK built: $APK_DEST ($APK_SIZE)"
    else
        print_error "APK not found at expected location: $APK_SOURCE"
    fi
fi

#===============================================================================
# Build Android App Bundle (AAB)
#===============================================================================

if [[ "$BUILD_AAB" == "true" ]]; then
    print_header "Building Android App Bundle (AAB)"

    print_step "Building release AAB with dart-define..."

    DART_DEFINES=(
        "--dart-define=ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}"
        "--dart-define=MAPBOX_ACCESS_TOKEN=${MAPBOX_ACCESS_TOKEN}"
        "--dart-define=DEBUG_MODE=false"
    )

    if [[ "$VERBOSE" == "true" ]]; then
        flutter build appbundle --release "${DART_DEFINES[@]}" --verbose
    else
        flutter build appbundle --release "${DART_DEFINES[@]}"
    fi

    # Copy AAB to artifacts
    AAB_SOURCE="$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
    AAB_DEST="$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.aab"

    if [[ -f "$AAB_SOURCE" ]]; then
        cp "$AAB_SOURCE" "$AAB_DEST"
        AAB_SIZE=$(du -h "$AAB_DEST" | cut -f1)
        print_success "AAB built: $AAB_DEST ($AAB_SIZE)"
    else
        print_error "AAB not found at expected location: $AAB_SOURCE"
    fi
fi

#===============================================================================
# Generate Checksums
#===============================================================================

print_step "Generating SHA-256 checksums..."

CHECKSUM_FILE="$ARTIFACT_DIR/checksums.sha256"
cd "$ARTIFACT_DIR"

# Generate checksums for all artifacts
> "$CHECKSUM_FILE"
for file in *.apk *.aab; do
    if [[ -f "$file" ]]; then
        if command -v sha256sum &> /dev/null; then
            sha256sum "$file" >> "$CHECKSUM_FILE"
        elif command -v shasum &> /dev/null; then
            shasum -a 256 "$file" >> "$CHECKSUM_FILE"
        fi
    fi
done

if [[ -s "$CHECKSUM_FILE" ]]; then
    print_success "Checksums generated: $CHECKSUM_FILE"
    cat "$CHECKSUM_FILE"
else
    print_warning "No checksums generated"
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
  "package_name": "com.directcuts.app",
  "version_name": "$VERSION_NAME",
  "build_number": "$BUILD_NUMBER",
  "platform": "android",
  "build_type": "release",
  "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_duration_seconds": $BUILD_DURATION,
  "git_commit": "$GIT_COMMIT",
  "git_branch": "$GIT_BRANCH",
  "flutter_version": "$FLUTTER_VERSION",
  "artifacts": {
    "apk": "$([[ -f "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.apk" ]] && echo "direct-cuts-$VERSION_NAME.apk" || echo "null")",
    "aab": "$([[ -f "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.aab" ]] && echo "direct-cuts-$VERSION_NAME.aab" || echo "null")"
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
echo ""
echo "Artifacts:"
echo "  Directory: $ARTIFACT_DIR"

if [[ -f "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.apk" ]]; then
    APK_SIZE=$(du -h "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.apk" | cut -f1)
    echo "  APK: direct-cuts-$VERSION_NAME.apk ($APK_SIZE)"
fi

if [[ -f "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.aab" ]]; then
    AAB_SIZE=$(du -h "$ARTIFACT_DIR/direct-cuts-$VERSION_NAME.aab" | cut -f1)
    echo "  AAB: direct-cuts-$VERSION_NAME.aab ($AAB_SIZE)"
fi

echo ""
echo "Next Steps:"
echo "  1. Test APK: adb install $ARTIFACT_DIR/direct-cuts-$VERSION_NAME.apk"
echo "  2. Upload AAB to Google Play Console"
echo "  3. Verify checksums before distribution"
echo ""
