#!/bin/bash
#===============================================================================
# Direct Cuts - Unified Deployment Script
#===============================================================================
# This script orchestrates the full deployment pipeline for Direct Cuts.
# It builds the app and deploys to TestFlight/Play Store using Fastlane.
#
# Prerequisites:
#   - Fastlane installed: bundle install (in project root)
#   - Environment variables set (see fastlane/.env.example)
#   - For iOS: Xcode, App Store Connect API key
#   - For Android: Android SDK, Google Play JSON key
#
# Usage:
#   ./deploy.sh <target> [options]
#
# Targets:
#   beta        - Deploy to TestFlight + Play Internal Testing
#   release     - Deploy to App Store + Play Store for review
#   promote     - Promote internal builds to production
#
# Options:
#   --platform <ios|android|all>  - Platform to deploy (default: all)
#   --skip-build                  - Skip build step (use existing artifacts)
#   --skip-tests                  - Skip tests during build
#   --dry-run                     - Show what would be done
#   --help                        - Show this help message
#
# Examples:
#   ./deploy.sh beta                      # Build and deploy to beta
#   ./deploy.sh beta --platform android   # Android only
#   ./deploy.sh release --skip-build      # Deploy existing builds
#   ./deploy.sh promote --platform android # Promote Android to production
#
#===============================================================================

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
TARGET=""
PLATFORM="all"
SKIP_BUILD=false
SKIP_TESTS=false
DRY_RUN=false

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
    head -40 "$0" | grep -E "^#" | sed 's/^#//'
    exit 0
}

fail() {
    print_error "$1"
    exit 1
}

#===============================================================================
# Parse Arguments
#===============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        beta|release|promote)
            TARGET="$1"
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate target
if [[ -z "$TARGET" ]]; then
    print_error "Target is required. Use: beta, release, or promote"
    echo "Run '$0 --help' for usage information."
    exit 1
fi

# Validate platform
if [[ ! "$PLATFORM" =~ ^(ios|android|all)$ ]]; then
    fail "Invalid platform: $PLATFORM. Use: ios, android, or all"
fi

#===============================================================================
# Environment Validation
#===============================================================================

print_header "Direct Cuts - Deployment: $TARGET"

print_step "Validating environment..."

cd "$PROJECT_ROOT"

# Check fastlane is installed
if ! command -v bundle &> /dev/null; then
    fail "Ruby bundler not found. Install Ruby and run: gem install bundler"
fi

# Check Gemfile exists
if [[ ! -f "Gemfile" ]] && [[ ! -f "fastlane/Gemfile" ]]; then
    fail "Gemfile not found. Run this from the project root."
fi

# Check fastlane is installed via bundler
if ! bundle exec fastlane --version &> /dev/null; then
    print_info "Installing Fastlane dependencies..."
    bundle install
fi

# Validate required environment variables
MISSING_VARS=()

# Common variables
[[ -z "$ONESIGNAL_APP_ID" ]] && MISSING_VARS+=("ONESIGNAL_APP_ID")
[[ -z "$MAPBOX_ACCESS_TOKEN" ]] && MISSING_VARS+=("MAPBOX_ACCESS_TOKEN")

# iOS variables (if deploying iOS)
if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
    [[ -z "$APP_STORE_CONNECT_API_KEY_ID" ]] && MISSING_VARS+=("APP_STORE_CONNECT_API_KEY_ID")
    [[ -z "$APP_STORE_CONNECT_API_ISSUER_ID" ]] && MISSING_VARS+=("APP_STORE_CONNECT_API_ISSUER_ID")
    [[ -z "$APP_STORE_CONNECT_API_KEY_CONTENT" ]] && MISSING_VARS+=("APP_STORE_CONNECT_API_KEY_CONTENT")
fi

# Android variables (if deploying Android)
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
    [[ -z "$GOOGLE_PLAY_JSON_KEY" ]] && MISSING_VARS+=("GOOGLE_PLAY_JSON_KEY")
fi

if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
    print_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        print_error "  - $var"
    done
    echo ""
    print_info "See fastlane/.env.example for configuration details."
    fail "Cannot proceed without required environment variables."
fi

print_success "Environment validated"

#===============================================================================
# Get Version Info
#===============================================================================

print_step "Reading version information..."

VERSION=$(grep -E "^version:" pubspec.yaml | sed 's/version: //' | tr -d '[:space:]')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)

print_info "Version: $VERSION_NAME (Build $BUILD_NUMBER)"

#===============================================================================
# Dry Run Check
#===============================================================================

if [[ "$DRY_RUN" == "true" ]]; then
    print_warning "DRY RUN MODE - No changes will be made"
    echo ""
    echo "Would execute:"
    echo "  Target: $TARGET"
    echo "  Platform: $PLATFORM"
    echo "  Version: $VERSION_NAME"
    echo ""

    if [[ "$SKIP_BUILD" == "false" ]]; then
        echo "  1. Build app artifacts"
    fi

    case $TARGET in
        beta)
            echo "  2. Upload to TestFlight (iOS) and/or Play Internal (Android)"
            ;;
        release)
            echo "  2. Submit to App Store and/or Play Store for review"
            ;;
        promote)
            echo "  2. Promote internal builds to production"
            ;;
    esac

    exit 0
fi

#===============================================================================
# Build Phase
#===============================================================================

if [[ "$SKIP_BUILD" == "false" ]]; then
    print_header "Building App"

    BUILD_OPTS=""
    [[ "$SKIP_TESTS" == "true" ]] && BUILD_OPTS="--skip-tests"

    if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
        print_step "Building Android AAB..."
        bash "$SCRIPT_DIR/build_android.sh" --aab-only $BUILD_OPTS
        print_success "Android build complete"
    fi

    if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
        print_step "Building iOS IPA..."
        # iOS build is handled by Fastlane
        print_info "iOS build will be handled by Fastlane"
    fi
else
    print_info "Skipping build (--skip-build)"
fi

#===============================================================================
# Deployment Phase
#===============================================================================

print_header "Deploying to $TARGET"

# Change to fastlane directory if Gemfile is there
if [[ -f "fastlane/Gemfile" ]]; then
    cd fastlane
fi

case $TARGET in
    beta)
        case $PLATFORM in
            ios)
                print_step "Deploying to TestFlight..."
                bundle exec fastlane ios beta skip_waiting:true
                ;;
            android)
                print_step "Deploying to Play Internal Testing..."
                bundle exec fastlane android beta
                ;;
            all)
                print_step "Deploying to TestFlight and Play Internal..."
                bundle exec fastlane beta
                ;;
        esac
        ;;

    release)
        case $PLATFORM in
            ios)
                print_step "Submitting to App Store..."
                bundle exec fastlane ios release submit_for_review:false
                ;;
            android)
                print_step "Submitting to Play Store (10% rollout)..."
                bundle exec fastlane android release rollout:0.1
                ;;
            all)
                print_step "Submitting to App Store and Play Store..."
                bundle exec fastlane release rollout:0.1
                ;;
        esac
        ;;

    promote)
        case $PLATFORM in
            ios)
                print_info "For iOS, submit TestFlight build via App Store Connect"
                print_info "Or run: bundle exec fastlane ios release"
                ;;
            android)
                print_step "Promoting Android internal build to production..."
                bundle exec fastlane android promote_internal rollout:0.1
                ;;
            all)
                print_info "For iOS, submit TestFlight build via App Store Connect"
                print_step "Promoting Android internal build to production..."
                bundle exec fastlane android promote_internal rollout:0.1
                ;;
        esac
        ;;
esac

#===============================================================================
# Summary
#===============================================================================

print_header "Deployment Complete"

echo -e "${GREEN}SUCCESS!${NC} Deployment finished."
echo ""
echo "Version: $VERSION_NAME (Build $BUILD_NUMBER)"
echo "Target: $TARGET"
echo "Platform: $PLATFORM"
echo ""

case $TARGET in
    beta)
        echo "Next Steps:"
        if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
            echo "  iOS: Check TestFlight for processing status"
            echo "       https://appstoreconnect.apple.com"
        fi
        if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
            echo "  Android: Share internal testing link with testers"
            echo "           https://play.google.com/console"
        fi
        ;;
    release)
        echo "Next Steps:"
        echo "  1. Monitor review status in stores"
        echo "  2. Prepare release notes for public announcement"
        echo "  3. Once approved, increase rollout percentage"
        ;;
    promote)
        echo "Next Steps:"
        echo "  1. Monitor crash reports and user feedback"
        echo "  2. Increase rollout percentage if stable"
        echo "  3. Run: fastlane android release rollout:1.0 for full rollout"
        ;;
esac

echo ""
