# Direct Cuts - Mobile CI/CD Pipeline Documentation

This document provides a comprehensive overview of the Mobile CI/CD pipelines for the Direct Cuts Flutter application.

## Table of Contents

1. [Pipeline Overview](#pipeline-overview)
2. [Pipeline Diagrams](#pipeline-diagrams)
3. [Pipeline Details](#pipeline-details)
4. [Usage Guide](#usage-guide)
5. [Troubleshooting](#troubleshooting)
6. [Cost Considerations](#cost-considerations)
7. [Manual Override Procedures](#manual-override-procedures)

---

## Pipeline Overview

The mobile CI/CD system consists of three main pipelines:

| Pipeline | Trigger | Purpose | Target Time |
|----------|---------|---------|-------------|
| `mobile_pr.yml` | Pull requests | Fast validation, block bad merges | < 10 min |
| `mobile_main.yml` | Push to main | Build artifacts for testing | < 20 min |
| `mobile_release.yml` | Version tags (v*.*.*) | Production release | < 30 min |

### Key Features

- **Fast Feedback**: PR checks complete in under 10 minutes
- **Idempotent Releases**: Re-running release pipeline won't create duplicates
- **Parallel Execution**: Independent jobs run concurrently
- **Artifact Retention**: Debug builds kept 7 days, releases kept 90 days
- **Graceful Degradation**: iOS builds skip if Apple credentials not configured
- **Comprehensive Summaries**: GitHub Actions summaries for every run

---

## Pipeline Diagrams

### PR Pipeline Flow

```
Pull Request to main/develop
          |
          v
    +------------+
    |    Lint    |
    | (format +  |
    |  analyze)  |
    +------------+
          |
          +-----------------+
          |                 |
          v                 v
    +----------+      +-----------+
    |   Test   |      |   Build   |
    |  (unit)  |      |  (debug)  |
    +----------+      +-----------+
          |                 |
          +-----------------+
                  |
                  v
           [Merge Allowed]
```

### Main Pipeline Flow

```
Push to main
     |
     v
+----------+
|   Test   |
+----------+
     |
     +------------------+
     |                  |
     v                  v
+---------+       +----------+
| Android |       |   iOS    |
|  Debug  |       | (no sign)|
+---------+       +----------+
     |                  |
     +------------------+
              |
              v
     [Artifacts Available]
     (7 day retention)
```

### Release Pipeline Flow

```
Tag: v*.*.*
      |
      v
+------------+
|  Validate  |
| (version)  |
+------------+
      |
      v
+----------+
|   Test   |
+----------+
      |
      +------------------+
      |                  |
      v                  v
+-----------+      +-----------+
|  Android  |      |    iOS    |
|  (signed) |      |  (signed) |
+-----------+      +-----------+
      |                  |
      +------------------+
      |                  |
      v                  v
+-------------+    +------------+
| Google Play |    | TestFlight |
|  (internal) |    |  (upload)  |
+-------------+    +------------+
      |                  |
      +------------------+
              |
              v
      +--------------+
      |    GitHub    |
      |   Release    |
      +--------------+
```

---

## Pipeline Details

### 1. PR Pipeline (`mobile_pr.yml`)

**Purpose**: Fast feedback on pull requests to catch issues before merge.

**Triggers**:
- Pull requests to `main` or `develop`
- Only runs on mobile-related file changes

**Jobs**:

| Job | Description | Timeout |
|-----|-------------|---------|
| `lint` | Format check + static analysis | 8 min |
| `test` | Unit tests with coverage | 10 min |
| `build-check` | Android debug build verification | 15 min |
| `pr-summary` | Generate status summary | 2 min |

**Outputs**:
- Blocks merge if any check fails
- Coverage report artifact
- Detailed step summaries

**Path Filters**:
```yaml
paths:
  - 'lib/**'
  - 'test/**'
  - 'pubspec.yaml'
  - 'android/**'
  - 'ios/**'
```

### 2. Main Pipeline (`mobile_main.yml`)

**Purpose**: Build debug artifacts for manual testing after merge.

**Triggers**:
- Push to `main` branch (with path filters)
- Manual workflow dispatch

**Jobs**:

| Job | Description | Timeout | Runner |
|-----|-------------|---------|--------|
| `test` | Full test suite | 15 min | ubuntu-latest |
| `build-android` | Debug APK | 20 min | ubuntu-latest |
| `build-ios` | iOS (no codesign) | 25 min | macos-latest |
| `notify` | Build summary | 5 min | ubuntu-latest |

**Outputs**:
- `android-debug-apk` artifact (7 day retention)
- `ios-build-info` artifact (7 day retention)
- Coverage uploaded to Codecov

**Manual Dispatch Options**:
```yaml
inputs:
  run_ios: 'Run iOS build (uses macOS runner minutes)'
  skip_tests: 'Skip tests (for faster iteration)'
```

### 3. Release Pipeline (`mobile_release.yml`)

**Purpose**: Production-grade releases with signing and store deployment.

**Triggers**:
- Push tags matching `v*.*.*` (e.g., `v2.0.1`)
- Manual workflow dispatch with version input

**Jobs**:

| Job | Description | Timeout | Conditions |
|-----|-------------|---------|------------|
| `validate` | Version validation | 5 min | Always |
| `test` | Test suite gate | 15 min | Always |
| `build-android` | Signed AAB + APK | 30 min | After test |
| `build-ios` | Signed IPA | 45 min | After test, if not skipped |
| `deploy-android` | Google Play Internal | 15 min | If secrets configured |
| `deploy-ios` | TestFlight upload | 20 min | If secrets configured |
| `github-release` | Create release | 10 min | After builds |
| `notify` | Release summary | 5 min | Always |

**Required Secrets**:
- See [SECRETS_SETUP.md](./SECRETS_SETUP.md) for complete list

**Manual Dispatch Options**:
```yaml
inputs:
  version: 'Version to release (e.g., 2.0.1)'
  skip_store_upload: 'Skip store uploads (build only)'
  skip_ios: 'Skip iOS build (save macOS minutes)'
```

---

## Usage Guide

### Creating a Release

1. **Update version in pubspec.yaml**:
   ```yaml
   version: 2.0.1+42
   ```

2. **Commit and push**:
   ```bash
   git add pubspec.yaml
   git commit -m "chore: bump version to 2.0.1"
   git push origin main
   ```

3. **Create and push tag**:
   ```bash
   git tag -a v2.0.1 -m "Release 2.0.1"
   git push origin v2.0.1
   ```

4. **Monitor the release**:
   - Go to Actions tab in GitHub
   - Watch "Mobile Release" workflow
   - Check summary for deployment status

### Using the Bump Version Script

The project includes a version bump script:

```bash
# Bump patch version (2.0.0 -> 2.0.1)
./scripts/mobile/bump_version.sh patch

# Bump minor version (2.0.1 -> 2.1.0)
./scripts/mobile/bump_version.sh minor

# Bump major version (2.1.0 -> 3.0.0)
./scripts/mobile/bump_version.sh major

# Set specific version
./scripts/mobile/bump_version.sh --set 2.5.0

# Bump and create tag
./scripts/mobile/bump_version.sh patch --tag
```

### Manual Release (Workflow Dispatch)

If you need to release without tagging:

1. Go to **Actions** > **Mobile Release**
2. Click **Run workflow**
3. Enter version (e.g., `2.0.1`)
4. Choose options:
   - `skip_store_upload`: Build only, no deployment
   - `skip_ios`: Skip iOS to save macOS minutes
5. Click **Run workflow**

---

## Troubleshooting

### Common Issues

#### 1. "Version mismatch" error in release

**Symptom**: Release pipeline fails with "Tag version does not match pubspec.yaml version"

**Fix**: Update `pubspec.yaml` version before tagging:
```bash
# Edit pubspec.yaml to match your intended tag
git add pubspec.yaml
git commit -m "chore: bump version to X.Y.Z"
git push
git tag vX.Y.Z
git push --tags
```

#### 2. Android build fails with signing error

**Symptom**: "Keystore was tampered with, or password was incorrect"

**Fix**:
1. Verify `ANDROID_KEYSTORE_BASE64` is correctly encoded
2. Check `ANDROID_KEYSTORE_PASSWORD` matches
3. Re-encode keystore if needed (see SECRETS_SETUP.md)

#### 3. iOS build skipped unexpectedly

**Symptom**: iOS job shows "skipped" in release

**Possible Causes**:
- `skip_ios` was set to true in workflow dispatch
- Apple credentials not configured in secrets
- Previous job failed

**Fix**: Configure Apple credentials or run with `skip_ios: false`

#### 4. Google Play upload fails

**Symptom**: "Authentication error" or "Package not found"

**Fix**:
1. Verify service account JSON is valid
2. Ensure app is set up in Google Play Console
3. Service account needs "Release to internal testing" permission

#### 5. Tests fail only in CI

**Symptom**: Tests pass locally but fail in GitHub Actions

**Fix**:
1. Ensure code generation runs: `dart run build_runner build`
2. Check for environment-specific code
3. Verify test isolation (no shared state)

### Reading Build Logs

Each workflow provides detailed summaries:

1. Go to the failed workflow run
2. Click on the failed job
3. Expand the failed step
4. Check "Summary" tab for formatted output
5. Download artifacts for detailed logs

### Re-running Failed Releases

The release pipeline is idempotent:

```bash
# Delete failed release (optional)
gh release delete v2.0.1 --yes

# Re-push tag
git push origin v2.0.1 --force
```

Or use workflow dispatch to re-run.

---

## Cost Considerations

### GitHub Actions Minutes Usage

| Runner | Rate | Multiplier |
|--------|------|------------|
| Ubuntu | 1x | 1 minute = 1 minute |
| macOS | 10x | 1 minute = 10 minutes |

### Estimated Usage Per Pipeline

| Pipeline | Ubuntu | macOS | Total (minutes) |
|----------|--------|-------|-----------------|
| PR Pipeline | ~10 | 0 | ~10 |
| Main Pipeline | ~20 | ~25 | ~270 |
| Release Pipeline | ~40 | ~45 | ~490 |

### Cost Optimization Tips

1. **Skip iOS on PRs**: PR pipeline only builds Android
2. **Use `skip_ios` for test releases**: Build Android only to verify
3. **Cache dependencies**: Flutter and Gradle caches reduce build time
4. **Path filters**: Pipelines only run on relevant file changes
5. **Concurrency limits**: Cancels duplicate runs automatically

### Free Tier Limits (GitHub Free)

- 2,000 minutes/month for private repos
- Unlimited for public repos

With the above estimates:
- ~20 PR runs/month
- ~10 main builds/month
- ~4 releases/month

= ~1,300 minutes (within free tier)

---

## Manual Override Procedures

### Building Locally

If CI is unavailable, build locally:

```bash
# Android
./scripts/mobile/build_android.sh

# iOS (macOS only)
./scripts/mobile/build_ios.sh
```

### Manual Store Upload

#### Google Play (via Fastlane)

```bash
cd fastlane

# Set credentials
export GOOGLE_PLAY_JSON_KEY=/path/to/key.json

# Upload to internal testing
bundle exec fastlane android beta
```

#### TestFlight (via Fastlane)

```bash
cd fastlane

# Set credentials
export APP_STORE_CONNECT_API_KEY_ID=...
export APP_STORE_CONNECT_API_ISSUER_ID=...
export APP_STORE_CONNECT_API_KEY_CONTENT=...

# Upload to TestFlight
bundle exec fastlane ios beta
```

### Emergency Rollback

#### Google Play

1. Go to Google Play Console
2. Navigate to Release > Production
3. Click "Manage release" on the problematic version
4. Click "Halt rollout"
5. Optionally, create a new release with the previous version

#### App Store

1. Go to App Store Connect
2. Navigate to the app > iOS App > Version
3. If still in review: "Remove from Review"
4. If live: Developer-initiated removal requires Apple support
5. Alternative: Submit new version with fix (expedited review available)

---

## File Reference

| File | Purpose |
|------|---------|
| `.github/workflows/mobile_pr.yml` | PR validation pipeline |
| `.github/workflows/mobile_main.yml` | Main branch builds |
| `.github/workflows/mobile_release.yml` | Production releases |
| `scripts/mobile/build_android.sh` | Local Android build |
| `scripts/mobile/build_ios.sh` | Local iOS build |
| `scripts/mobile/bump_version.sh` | Version management |
| `fastlane/Fastfile` | Fastlane deployment config |
| `docs/ci/SECRETS_SETUP.md` | Secrets configuration guide |

---

## Support

For issues with the CI/CD pipelines:

1. Check this documentation first
2. Review workflow logs and summaries
3. Check [SECRETS_SETUP.md](./SECRETS_SETUP.md) for credential issues
4. Open an issue with:
   - Workflow run URL
   - Error message
   - Steps to reproduce
