#!/bin/bash
#===============================================================================
# Direct Cuts - Version Bumping Script
#===============================================================================
# This script manages semantic versioning for the Flutter application.
# It updates pubspec.yaml and optionally creates a git tag.
#
# Version Format: MAJOR.MINOR.PATCH+BUILD
# Example: 2.1.0+42
#
# Semantic Versioning Guidelines:
#   MAJOR - Breaking changes, incompatible API changes
#   MINOR - New features, backward compatible
#   PATCH - Bug fixes, backward compatible
#   BUILD - Auto-incremented build number (git commit count or timestamp)
#
# Usage:
#   ./bump_version.sh <major|minor|patch> [options]
#   ./bump_version.sh --set 2.1.0 [options]
#
# Options:
#   --build NUMBER    Set specific build number (default: auto from git)
#   --no-git          Don't create git tag
#   --tag             Create and push git tag
#   --dry-run         Show what would change without modifying files
#   --help            Show this help message
#
# Examples:
#   ./bump_version.sh patch           # 2.0.0 -> 2.0.1
#   ./bump_version.sh minor           # 2.0.1 -> 2.1.0
#   ./bump_version.sh major           # 2.1.0 -> 3.0.0
#   ./bump_version.sh --set 2.5.0     # Set specific version
#   ./bump_version.sh patch --tag     # Bump and create git tag
#
#===============================================================================

set -e  # Exit on error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Options
BUMP_TYPE=""
SET_VERSION=""
CUSTOM_BUILD=""
CREATE_TAG=false
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
    head -50 "$0" | grep -E "^#" | sed 's/^#//'
    exit 0
}

fail() {
    print_error "$1"
    exit 1
}

#===============================================================================
# Parse Command Line Arguments
#===============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        major|minor|patch)
            BUMP_TYPE="$1"
            shift
            ;;
        --set)
            SET_VERSION="$2"
            shift 2
            ;;
        --build)
            CUSTOM_BUILD="$2"
            shift 2
            ;;
        --tag)
            CREATE_TAG=true
            shift
            ;;
        --no-git)
            CREATE_TAG=false
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

# Validate arguments
if [[ -z "$BUMP_TYPE" ]] && [[ -z "$SET_VERSION" ]]; then
    print_error "Usage: $0 <major|minor|patch> [options]"
    print_error "       $0 --set <version> [options]"
    echo ""
    echo "Run '$0 --help' for more information."
    exit 1
fi

#===============================================================================
# Read Current Version
#===============================================================================

print_header "Direct Cuts - Version Bump"

cd "$PROJECT_ROOT"

PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"

if [[ ! -f "$PUBSPEC_PATH" ]]; then
    fail "pubspec.yaml not found at: $PUBSPEC_PATH"
fi

# Extract current version
CURRENT_VERSION_LINE=$(grep -E "^version:" "$PUBSPEC_PATH")
CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | sed 's/version: //' | tr -d '[:space:]')

# Split into version name and build number
CURRENT_VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
CURRENT_BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Split version name into components
CURRENT_MAJOR=$(echo "$CURRENT_VERSION_NAME" | cut -d'.' -f1)
CURRENT_MINOR=$(echo "$CURRENT_VERSION_NAME" | cut -d'.' -f2)
CURRENT_PATCH=$(echo "$CURRENT_VERSION_NAME" | cut -d'.' -f3)

print_info "Current version: $CURRENT_VERSION_NAME+$CURRENT_BUILD_NUMBER"
print_info "  Major: $CURRENT_MAJOR"
print_info "  Minor: $CURRENT_MINOR"
print_info "  Patch: $CURRENT_PATCH"
print_info "  Build: $CURRENT_BUILD_NUMBER"

#===============================================================================
# Calculate New Version
#===============================================================================

print_step "Calculating new version..."

if [[ -n "$SET_VERSION" ]]; then
    # Validate version format
    if [[ ! "$SET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        fail "Invalid version format. Use: MAJOR.MINOR.PATCH (e.g., 2.1.0)"
    fi

    NEW_VERSION_NAME="$SET_VERSION"
    NEW_MAJOR=$(echo "$SET_VERSION" | cut -d'.' -f1)
    NEW_MINOR=$(echo "$SET_VERSION" | cut -d'.' -f2)
    NEW_PATCH=$(echo "$SET_VERSION" | cut -d'.' -f3)
else
    # Bump version based on type
    NEW_MAJOR=$CURRENT_MAJOR
    NEW_MINOR=$CURRENT_MINOR
    NEW_PATCH=$CURRENT_PATCH

    case $BUMP_TYPE in
        major)
            NEW_MAJOR=$((CURRENT_MAJOR + 1))
            NEW_MINOR=0
            NEW_PATCH=0
            ;;
        minor)
            NEW_MINOR=$((CURRENT_MINOR + 1))
            NEW_PATCH=0
            ;;
        patch)
            NEW_PATCH=$((CURRENT_PATCH + 1))
            ;;
    esac

    NEW_VERSION_NAME="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
fi

# Calculate build number
if [[ -n "$CUSTOM_BUILD" ]]; then
    NEW_BUILD_NUMBER="$CUSTOM_BUILD"
else
    # Use git commit count for reproducible builds
    if git rev-parse --git-dir > /dev/null 2>&1; then
        NEW_BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "$((CURRENT_BUILD_NUMBER + 1))")
    else
        # Fallback: increment current build number
        NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
    fi
fi

NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

echo ""
echo -e "Version change: ${YELLOW}$CURRENT_VERSION${NC} -> ${GREEN}$NEW_VERSION${NC}"
echo ""

#===============================================================================
# Dry Run Check
#===============================================================================

if [[ "$DRY_RUN" == "true" ]]; then
    print_warning "DRY RUN - No changes will be made"
    echo ""
    echo "Would update:"
    echo "  pubspec.yaml: version: $NEW_VERSION"
    echo "  lib/config/app_config.dart: appVersion = '$NEW_VERSION_NAME'"

    if [[ "$CREATE_TAG" == "true" ]]; then
        echo "  Git tag: v$NEW_VERSION_NAME"
    fi

    exit 0
fi

#===============================================================================
# Update pubspec.yaml
#===============================================================================

print_step "Updating pubspec.yaml..."

# Use sed to replace version line
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS sed requires backup extension
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_PATH"
else
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_PATH"
fi

# Verify the change
UPDATED_VERSION=$(grep -E "^version:" "$PUBSPEC_PATH" | sed 's/version: //' | tr -d '[:space:]')
if [[ "$UPDATED_VERSION" == "$NEW_VERSION" ]]; then
    print_success "pubspec.yaml updated"
else
    fail "Failed to update pubspec.yaml"
fi

#===============================================================================
# Update app_config.dart
#===============================================================================

print_step "Updating app_config.dart..."

APP_CONFIG_PATH="$PROJECT_ROOT/lib/config/app_config.dart"

if [[ -f "$APP_CONFIG_PATH" ]]; then
    # Update appVersion constant
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/static const String appVersion = '[^']*'/static const String appVersion = '$NEW_VERSION_NAME'/" "$APP_CONFIG_PATH"
    else
        sed -i "s/static const String appVersion = '[^']*'/static const String appVersion = '$NEW_VERSION_NAME'/" "$APP_CONFIG_PATH"
    fi
    print_success "app_config.dart updated"
else
    print_warning "app_config.dart not found - skipping"
fi

#===============================================================================
# Create Git Tag
#===============================================================================

if [[ "$CREATE_TAG" == "true" ]]; then
    print_step "Creating git tag..."

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "Not a git repository - skipping tag creation"
    else
        TAG_NAME="v$NEW_VERSION_NAME"

        # Check if tag already exists
        if git rev-parse "$TAG_NAME" > /dev/null 2>&1; then
            print_warning "Tag $TAG_NAME already exists"
            read -p "Delete and recreate? [y/N]: " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                git tag -d "$TAG_NAME"
                print_info "Deleted existing tag"
            else
                print_info "Skipping tag creation"
                CREATE_TAG=false
            fi
        fi

        if [[ "$CREATE_TAG" == "true" ]]; then
            # Create annotated tag
            git add "$PUBSPEC_PATH"
            [[ -f "$APP_CONFIG_PATH" ]] && git add "$APP_CONFIG_PATH"

            git commit -m "chore: bump version to $NEW_VERSION_NAME" || print_info "Nothing to commit"

            git tag -a "$TAG_NAME" -m "Release $NEW_VERSION_NAME

Build: $NEW_BUILD_NUMBER
Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

            print_success "Created tag: $TAG_NAME"

            echo ""
            read -p "Push tag to remote? [y/N]: " PUSH_CONFIRM
            if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
                git push origin "$TAG_NAME"
                print_success "Pushed tag to remote"
            fi
        fi
    fi
fi

#===============================================================================
# Summary
#===============================================================================

print_header "Version Bump Complete"

echo -e "${GREEN}SUCCESS!${NC} Version updated."
echo ""
echo "Previous: $CURRENT_VERSION"
echo "New:      $NEW_VERSION"
echo ""
echo "Updated files:"
echo "  - pubspec.yaml"
[[ -f "$APP_CONFIG_PATH" ]] && echo "  - lib/config/app_config.dart"

if [[ "$CREATE_TAG" == "true" ]]; then
    echo "  - Git tag: v$NEW_VERSION_NAME"
fi

echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add -A && git commit -m 'chore: bump version to $NEW_VERSION_NAME'"
echo "  3. Build: ./scripts/mobile/build_android.sh"
echo ""
