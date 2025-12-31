# Flutter Launch Script with Mapbox Token
# This script reads the Mapbox token from .env file and launches Flutter

$envFile = Join-Path $PSScriptRoot ".env"
$mapboxToken = ""

# Read token from .env file if it exists
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile
    foreach ($line in $envContent) {
        if ($line -match "^MAPBOX_ACCESS_TOKEN=(.+)") {
            $mapboxToken = $matches[1].Trim()
            break
        }
    }
}

# If not found in .env, try system environment variable
if ([string]::IsNullOrEmpty($mapboxToken)) {
    $mapboxToken = $env:MAPBOX_ACCESS_TOKEN
}

# If still not found, use the default token from Direct-Cuts project
if ([string]::IsNullOrEmpty($mapboxToken)) {
    $mapboxToken = "pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6cjl0czAxNTkzZXBycWlqYjd1a2MifQ.PjRxOw6ChXZ-aNsXIJIIgA"
    Write-Host "Using default Mapbox token. To use a custom token, create a .env file with MAPBOX_ACCESS_TOKEN=your-token" -ForegroundColor Yellow
}

# Set environment variable for this session
$env:MAPBOX_ACCESS_TOKEN = $mapboxToken

Write-Host "Mapbox token configured (length: $($mapboxToken.Length))" -ForegroundColor Green

# Launch Flutter with the token
Write-Host "Launching Flutter..." -ForegroundColor Cyan
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=$mapboxToken $args

