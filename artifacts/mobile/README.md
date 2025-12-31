# Mobile Build Artifacts

This directory contains mobile build artifacts organized by version.

## Directory Structure

```
artifacts/mobile/
└── <version>/
    ├── android/
    │   ├── direct-cuts-<version>.aab    # App Bundle for Google Play
    │   ├── direct-cuts-<version>.apk    # APK for direct installation
    │   ├── checksums.sha256             # SHA-256 checksums
    │   └── build-manifest.json          # Build metadata
    └── ios/
        ├── DirectCuts-<version>.ipa     # IPA for App Store/TestFlight
        ├── checksums.sha256             # SHA-256 checksums
        └── build-manifest.json          # Build metadata
```

## Generated Files

### Android

- **AAB (Android App Bundle)**: Upload to Google Play Console for distribution
- **APK**: Direct installation for testing (`adb install <file>.apk`)

### iOS

- **IPA**: Upload to App Store Connect using Transporter or `xcrun altool`

### Metadata

- **checksums.sha256**: SHA-256 hashes to verify file integrity
- **build-manifest.json**: Build details including version, timestamp, git commit

## Usage

### Build Android
```bash
# Bash
./scripts/mobile/build_android.sh

# PowerShell
.\scripts\mobile\build_android.ps1
```

### Build iOS (macOS only)
```bash
./scripts/mobile/build_ios.sh
```

### Verify Checksums
```bash
# Linux/macOS
sha256sum -c checksums.sha256

# PowerShell
Get-Content checksums.sha256 | ForEach-Object {
    $parts = $_ -split "  "
    $computed = (Get-FileHash $parts[1] -Algorithm SHA256).Hash.ToLower()
    if ($computed -eq $parts[0]) { "OK: $($parts[1])" } else { "FAIL: $($parts[1])" }
}
```

## Important Notes

- Build artifacts should NOT be committed to git (add to .gitignore)
- Always verify checksums before distributing builds
- Keep artifacts until confirmed uploaded to stores
- Archive important releases externally (cloud storage, etc.)

## See Also

- [BUILD_RELEASE.md](../../docs/mobile/BUILD_RELEASE.md) - Complete build guide
