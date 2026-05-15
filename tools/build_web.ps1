# Clean previous web builds
Write-Host "Building Flutter Web for Transitly..."

$webDir = "C:\Users\k\Desktop\all\clase\nexto-stop-v2\web"

if (Test-Path -LiteralPath $webDir) {
    Write-Host "Cleaning old web build..."
    Remove-Item -LiteralPath $webDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Building Flutter Web (release)..."
flutter build web --release --base-href "/app/" --pwa-strategy none

if ($LASTEXITCODE -eq 0) {
    Write-Host "Flutter Web build complete."

    $astroPublic = "C:\Users\k\Desktop\all\clase\nexto-stop-v2\astro\public\flutter-web-build"
    if (Test-Path -LiteralPath $astroPublic) {
        Remove-Item -LiteralPath $astroPublic -Recurse -Force
    }
    New-Item -ItemType Directory -Path $astroPublic -Force | Out-Null

    Copy-Item -LiteralPath "C:\Users\k\Desktop\all\clase\nexto-stop-v2\build\web\*" -Destination $astroPublic -Recurse
    Write-Host "Copied Flutter Web build to astro/public/flutter-web-build/"
} else {
    Write-Host "ERROR: Flutter Web build failed." -ForegroundColor Red
    exit 1
}
