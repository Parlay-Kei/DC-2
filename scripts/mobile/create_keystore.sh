#!/bin/bash
#===============================================================================
# Direct Cuts - Android Keystore Generation Script
#===============================================================================
# This script generates a new production keystore for signing Android releases.
#
# IMPORTANT SECURITY NOTES:
#   - Store the keystore file securely (it's your app's identity)
#   - Never commit the keystore or passwords to version control
#   - Backup the keystore in multiple secure locations
#   - If you lose the keystore, you cannot update your app on Play Store
#
# Requirements:
#   - Java JDK installed (keytool command available)
#
# Usage:
#   ./create_keystore.sh [options]
#
# Options:
#   --output PATH     Output path for keystore (default: android/app/release.keystore)
#   --alias NAME      Key alias name (default: direct-cuts-release)
#   --validity DAYS   Validity period in days (default: 10000 = ~27 years)
#   --help            Show this help message
#
# Output:
#   - Keystore file at specified location
#   - key.properties template file for Gradle
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

# Default configuration
KEYSTORE_PATH="$PROJECT_ROOT/android/app/release.keystore"
KEY_ALIAS="direct-cuts-release"
KEY_VALIDITY=10000  # ~27 years

# App details for certificate
CN="Direct Cuts"
OU="Mobile Development"
O="Direct Cuts LLC"
L="New York"
ST="NY"
C="US"

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
    head -45 "$0" | grep -E "^#" | sed 's/^#//'
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
        --output)
            KEYSTORE_PATH="$2"
            shift 2
            ;;
        --alias)
            KEY_ALIAS="$2"
            shift 2
            ;;
        --validity)
            KEY_VALIDITY="$2"
            shift 2
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
# Pre-Flight Checks
#===============================================================================

print_header "Direct Cuts - Keystore Generator"

print_step "Validating environment..."

# Check keytool is available
if ! command -v keytool &> /dev/null; then
    fail "keytool not found. Please install Java JDK."
fi

print_info "keytool location: $(which keytool)"

# Check if keystore already exists
if [[ -f "$KEYSTORE_PATH" ]]; then
    print_warning "Keystore already exists at: $KEYSTORE_PATH"
    echo ""
    read -p "Do you want to overwrite it? This will invalidate any existing builds! (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        print_info "Aborted. Existing keystore preserved."
        exit 0
    fi
    print_warning "Overwriting existing keystore..."
    rm -f "$KEYSTORE_PATH"
fi

# Create parent directory if needed
KEYSTORE_DIR=$(dirname "$KEYSTORE_PATH")
if [[ ! -d "$KEYSTORE_DIR" ]]; then
    mkdir -p "$KEYSTORE_DIR"
fi

#===============================================================================
# Gather Information
#===============================================================================

print_header "Certificate Information"

echo "The following information will be embedded in your signing certificate."
echo "Press Enter to accept default values shown in brackets."
echo ""

read -p "Organization Name [$O]: " INPUT_O
O="${INPUT_O:-$O}"

read -p "Organization Unit [$OU]: " INPUT_OU
OU="${INPUT_OU:-$OU}"

read -p "City/Locality [$L]: " INPUT_L
L="${INPUT_L:-$L}"

read -p "State/Province [$ST]: " INPUT_ST
ST="${INPUT_ST:-$ST}"

read -p "Country Code [$C]: " INPUT_C
C="${INPUT_C:-$C}"

#===============================================================================
# Get Passwords
#===============================================================================

print_header "Password Setup"

echo -e "${YELLOW}IMPORTANT:${NC} Remember these passwords! You'll need them for every release."
echo "If you lose them, you won't be able to update your app on the Play Store."
echo ""

# Get keystore password
while true; do
    read -s -p "Enter keystore password (min 6 characters): " STORE_PASSWORD
    echo ""

    if [[ ${#STORE_PASSWORD} -lt 6 ]]; then
        print_error "Password must be at least 6 characters"
        continue
    fi

    read -s -p "Confirm keystore password: " STORE_PASSWORD_CONFIRM
    echo ""

    if [[ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]]; then
        print_error "Passwords don't match. Try again."
        continue
    fi

    break
done

# Get key password
echo ""
read -p "Use same password for key? (recommended) [Y/n]: " SAME_PASSWORD
SAME_PASSWORD=${SAME_PASSWORD:-Y}

if [[ "$SAME_PASSWORD" =~ ^[Yy]$ ]]; then
    KEY_PASSWORD="$STORE_PASSWORD"
else
    while true; do
        read -s -p "Enter key password (min 6 characters): " KEY_PASSWORD
        echo ""

        if [[ ${#KEY_PASSWORD} -lt 6 ]]; then
            print_error "Password must be at least 6 characters"
            continue
        fi

        read -s -p "Confirm key password: " KEY_PASSWORD_CONFIRM
        echo ""

        if [[ "$KEY_PASSWORD" != "$KEY_PASSWORD_CONFIRM" ]]; then
            print_error "Passwords don't match. Try again."
            continue
        fi

        break
    done
fi

#===============================================================================
# Generate Keystore
#===============================================================================

print_header "Generating Keystore"

DNAME="CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"
print_info "Distinguished Name: $DNAME"
print_info "Key Alias: $KEY_ALIAS"
print_info "Validity: $KEY_VALIDITY days"
print_info "Output: $KEYSTORE_PATH"
echo ""

print_step "Creating keystore..."

keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -sigalg SHA256withRSA \
    -validity "$KEY_VALIDITY" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "$DNAME"

if [[ -f "$KEYSTORE_PATH" ]]; then
    print_success "Keystore created successfully!"
else
    fail "Failed to create keystore"
fi

# Set restrictive permissions
chmod 600 "$KEYSTORE_PATH"
print_info "Set restrictive permissions (600) on keystore file"

#===============================================================================
# Display Keystore Info
#===============================================================================

print_step "Verifying keystore..."

echo ""
keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" | head -20

#===============================================================================
# Generate key.properties
#===============================================================================

print_header "Creating key.properties"

KEY_PROPERTIES_PATH="$PROJECT_ROOT/android/key.properties"

cat > "$KEY_PROPERTIES_PATH" << EOF
# Direct Cuts - Android Signing Configuration
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
#
# SECURITY WARNING: Do NOT commit this file to version control!
# Add to .gitignore: android/key.properties
#
# For CI/CD, use environment variables or secure secrets management.

storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=release.keystore
EOF

chmod 600 "$KEY_PROPERTIES_PATH"

print_success "key.properties created: $KEY_PROPERTIES_PATH"

#===============================================================================
# Update .gitignore
#===============================================================================

print_step "Updating .gitignore..."

GITIGNORE_PATH="$PROJECT_ROOT/.gitignore"

# Check if entries already exist
NEEDS_KEYSTORE=true
NEEDS_PROPERTIES=true

if [[ -f "$GITIGNORE_PATH" ]]; then
    if grep -q "release.keystore" "$GITIGNORE_PATH"; then
        NEEDS_KEYSTORE=false
    fi
    if grep -q "key.properties" "$GITIGNORE_PATH"; then
        NEEDS_PROPERTIES=false
    fi
fi

if [[ "$NEEDS_KEYSTORE" == "true" ]] || [[ "$NEEDS_PROPERTIES" == "true" ]]; then
    echo "" >> "$GITIGNORE_PATH"
    echo "# Android signing (DO NOT COMMIT)" >> "$GITIGNORE_PATH"

    if [[ "$NEEDS_KEYSTORE" == "true" ]]; then
        echo "*.keystore" >> "$GITIGNORE_PATH"
        echo "*.jks" >> "$GITIGNORE_PATH"
    fi

    if [[ "$NEEDS_PROPERTIES" == "true" ]]; then
        echo "android/key.properties" >> "$GITIGNORE_PATH"
    fi

    print_success "Updated .gitignore with keystore exclusions"
else
    print_info ".gitignore already has keystore exclusions"
fi

#===============================================================================
# Summary
#===============================================================================

print_header "Keystore Generation Complete"

echo -e "${GREEN}SUCCESS!${NC} Your production keystore has been created."
echo ""
echo "Files created:"
echo "  Keystore:       $KEYSTORE_PATH"
echo "  Key Properties: $KEY_PROPERTIES_PATH"
echo ""
echo "Key Alias: $KEY_ALIAS"
echo "Validity: $KEY_VALIDITY days (expires: $(date -d "+$KEY_VALIDITY days" +"%Y-%m-%d" 2>/dev/null || date -v+${KEY_VALIDITY}d +"%Y-%m-%d" 2>/dev/null || echo "~27 years from now"))"
echo ""
echo -e "${YELLOW}CRITICAL - BACKUP THESE FILES AND PASSWORDS:${NC}"
echo "  1. Copy keystore to secure backup location (encrypted cloud storage, etc.)"
echo "  2. Store passwords in a password manager"
echo "  3. If you lose the keystore, you CANNOT update your app on Google Play"
echo ""
echo -e "${RED}SECURITY REMINDERS:${NC}"
echo "  - Never commit keystore or key.properties to git"
echo "  - Don't share passwords via email or chat"
echo "  - For CI/CD, use encrypted secrets (GitHub Secrets, etc.)"
echo ""
echo "Next steps:"
echo "  1. Update android/app/build.gradle.kts to use the keystore"
echo "  2. Run: ./scripts/mobile/build_android.sh"
echo ""
