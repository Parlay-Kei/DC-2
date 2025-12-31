# Direct Cuts - Fastlane Configuration

Automated deployment for Direct Cuts iOS and Android apps.

## Quick Start

```bash
# Install dependencies
bundle install

# View available lanes
bundle exec fastlane lanes

# Deploy to TestFlight + Play Internal
bundle exec fastlane beta

# Deploy to production (App Store + Play Store)
bundle exec fastlane release
```

## Prerequisites

### Ruby Environment

```bash
# Install Ruby 2.6+ (recommend rbenv or rvm)
rbenv install 3.2.0
rbenv local 3.2.0

# Install bundler
gem install bundler

# Install Fastlane and plugins
bundle install
```

### iOS Requirements

1. **Apple Developer Account** ($99/year)
2. **App Store Connect API Key**
   - Go to: App Store Connect > Users and Access > Keys
   - Create key with "App Manager" role
   - Download .p8 file (save securely!)

3. **Environment Variables**
   ```bash
   export APPLE_ID="developer@direct-cuts.com"
   export APPLE_TEAM_ID="XXXXXXXXXX"
   export APP_STORE_CONNECT_API_KEY_ID="ABC123"
   export APP_STORE_CONNECT_API_ISSUER_ID="xxx-xxx-xxx"
   export APP_STORE_CONNECT_API_KEY_CONTENT="$(base64 -i AuthKey_ABC123.p8)"
   ```

4. **Code Signing** (using Match - recommended)
   ```bash
   export MATCH_GIT_URL="git@github.com:directcuts/ios-certificates.git"
   export MATCH_PASSWORD="your-encryption-password"
   ```

### Android Requirements

1. **Google Play Developer Account** ($25 one-time)
2. **Service Account JSON Key**
   - Create service account in Google Cloud Console
   - Enable Play Developer API
   - Download JSON key
   - Grant permissions in Play Console

3. **Environment Variables**
   ```bash
   export GOOGLE_PLAY_JSON_KEY="/path/to/service-account.json"
   ```

4. **Signing Key** (managed by build scripts)
   ```bash
   # Create keystore (if not exists)
   ./scripts/mobile/create_keystore.sh
   ```

### Common Environment Variables

```bash
# Build Configuration
export ONESIGNAL_APP_ID="your-onesignal-app-id"
export MAPBOX_ACCESS_TOKEN="pk.your-mapbox-token"
```

## Available Lanes

### Cross-Platform

| Lane | Description |
|------|-------------|
| `beta` | Deploy to TestFlight (iOS) + Play Internal (Android) |
| `release` | Submit to App Store + Play Store |
| `promote_internal` | Promote internal builds to production |
| `screenshots` | Capture app screenshots (placeholder) |
| `clean` | Clean build artifacts |
| `bump` | Increment version number |
| `version` | Display current version |

### iOS-Specific

| Lane | Description |
|------|-------------|
| `ios validate` | Validate iOS environment |
| `ios certificates` | Sync certificates with Match |
| `ios build` | Build release IPA |
| `ios beta` | Upload to TestFlight |
| `ios release` | Submit to App Store |

### Android-Specific

| Lane | Description |
|------|-------------|
| `android validate` | Validate Android environment |
| `android build` | Build release AAB |
| `android beta` | Upload to Play Internal Testing |
| `android release` | Submit to Play Store |
| `android promote_internal` | Promote internal to production |

## Usage Examples

### Deploy Beta Build

```bash
# Both platforms
bundle exec fastlane beta

# iOS only
bundle exec fastlane ios beta

# Android only
bundle exec fastlane android beta
```

### Production Release

```bash
# Both platforms (10% staged rollout on Android)
bundle exec fastlane release rollout:0.1

# With specific options
bundle exec fastlane release \
  skip_screenshots:true \
  submit_for_review:false \
  draft:true
```

### Promote to Production

```bash
# Promote Android internal build to production
bundle exec fastlane android promote_internal rollout:0.1

# Full rollout
bundle exec fastlane android promote_internal rollout:1.0
```

### Version Management

```bash
# Bump patch version (2.0.0 -> 2.0.1)
bundle exec fastlane bump type:patch

# Bump minor version (2.0.1 -> 2.1.0)
bundle exec fastlane bump type:minor

# Display current version
bundle exec fastlane version
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Beta
on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Deploy Beta
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
          GOOGLE_PLAY_JSON_KEY: ${{ secrets.GOOGLE_PLAY_JSON_KEY }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: bundle exec fastlane beta
```

## File Structure

```
fastlane/
  Appfile           # App identifiers and team IDs
  Fastfile          # Lane definitions
  Gemfile           # Ruby dependencies
  Matchfile         # iOS certificate management
  Pluginfile        # Fastlane plugins
  README.md         # This file
  metadata/
    android/
      en-US/
        title.txt
        short_description.txt
        full_description.txt
        changelogs/
          default.txt
    ios/
      en-US/
        name.txt
        subtitle.txt
        description.txt
        keywords.txt
        release_notes.txt
        ...
  screenshots/      # Generated screenshots (gitignored)
```

## Troubleshooting

### iOS Issues

**"Missing compliance information"**
- Answer export compliance questions in App Store Connect
- Or add `ITSAppUsesNonExemptEncryption` to Info.plist

**"No signing identity found"**
- Run: `bundle exec fastlane match appstore`
- Or: Configure manual signing in Xcode

**"App Store Connect API error"**
- Verify API key is valid and not expired
- Check key has required permissions

### Android Issues

**"Upload failed: APK/AAB already exists"**
- Version code must be higher than previous upload
- Run: `bundle exec fastlane bump type:patch`

**"Service account permission denied"**
- Verify service account has "Release" permissions in Play Console
- Wait 24 hours after granting permissions

**"Missing signing configuration"**
- Run: `./scripts/mobile/create_keystore.sh`
- Ensure `android/key.properties` exists

### General Issues

**"Command not found: fastlane"**
- Run: `bundle install`
- Use: `bundle exec fastlane` instead of just `fastlane`

**"Version mismatch"**
- Ensure pubspec.yaml version is correct
- Run: `flutter pub get`

## Documentation

- [Fastlane Docs](https://docs.fastlane.tools)
- [Match (iOS Signing)](https://docs.fastlane.tools/actions/match/)
- [Supply (Android Upload)](https://docs.fastlane.tools/actions/supply/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Google Play Developer API](https://developers.google.com/android-publisher)

## Support

For deployment issues:
- Check this README
- Review lane output for errors
- Contact: support@direct-cuts.com
