# Direct Cuts - Build and Deploy Script
# Run this script in PowerShell from C:\Dev\DC-2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Direct Cuts - Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean
Write-Host "[1/7] Cleaning project..." -ForegroundColor Yellow
flutter clean
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "[2/7] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

# Step 3: Generate app icons (requires assets in place)
Write-Host "[3/7] Generating app icons..." -ForegroundColor Yellow
if (Test-Path "assets/images/app_icon.png") {
    dart run flutter_launcher_icons
    Write-Host "Done!" -ForegroundColor Green
} else {
    Write-Host "SKIPPED: app_icon.png not found in assets/images/" -ForegroundColor Red
    Write-Host "Download icons from Claude and place them in assets/images/" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Generate splash screen
Write-Host "[4/7] Generating splash screen..." -ForegroundColor Yellow
if (Test-Path "assets/images/splash_logo.png") {
    dart run flutter_native_splash:create
    Write-Host "Done!" -ForegroundColor Green
} else {
    Write-Host "SKIPPED: splash_logo.png not found in assets/images/" -ForegroundColor Red
}
Write-Host ""

# Step 5: Analyze code
Write-Host "[5/7] Analyzing code..." -ForegroundColor Yellow
flutter analyze
Write-Host ""

# Step 6: Build Android APK
Write-Host "[6/7] Building Android APK..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "APK built successfully!" -ForegroundColor Green
    Write-Host "Location: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Cyan
} else {
    Write-Host "APK build failed!" -ForegroundColor Red
}
Write-Host ""

# Step 7: Build Android App Bundle
Write-Host "[7/7] Building Android App Bundle..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "App Bundle built successfully!" -ForegroundColor Green
    Write-Host "Location: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Cyan
} else {
    Write-Host "App Bundle build failed!" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test APK: adb install build/app/outputs/flutter-apk/app-release.apk"
Write-Host "2. Upload AAB to Play Console for release"
Write-Host "3. For iOS: flutter build ios --release (requires Mac)"
Write-Host ""
