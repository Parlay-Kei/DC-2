# Direct Cuts - Icon Setup Script
# Run this script after downloading the icons from Claude

# Instructions:
# 1. Download these files from Claude's output:
#    - app_icon.png
#    - app_icon_foreground.png
#    - splash_logo.png
#
# 2. Place them in C:\Dev\DC-2\assets\images\
#
# 3. Run this script to generate all required icon sizes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Direct Cuts - Icon Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$assetsPath = "C:\Dev\DC-2\assets\images"

# Check if icons exist
$icons = @("app_icon.png", "app_icon_foreground.png", "splash_logo.png")
$missing = @()

foreach ($icon in $icons) {
    $path = Join-Path $assetsPath $icon
    if (-not (Test-Path $path)) {
        $missing += $icon
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`nMissing icons:" -ForegroundColor Red
    foreach ($icon in $missing) {
        Write-Host "  - $icon" -ForegroundColor Yellow
    }
    Write-Host "`nPlease download the icons from Claude and place them in:" -ForegroundColor Yellow
    Write-Host "  $assetsPath" -ForegroundColor Cyan
    exit 1
}

Write-Host "`nAll icons found!" -ForegroundColor Green

# Navigate to project
Set-Location "C:\Dev\DC-2"

# Run flutter_launcher_icons
Write-Host "`n[1/2] Generating app icons..." -ForegroundColor Yellow
dart run flutter_launcher_icons

# Run flutter_native_splash
Write-Host "`n[2/2] Generating splash screen..." -ForegroundColor Yellow
dart run flutter_native_splash:create

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Icon Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
