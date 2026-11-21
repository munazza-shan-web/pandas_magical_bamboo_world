$ErrorActionPreference = "Stop"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter was not found on PATH. Add Flutter to PATH, reopen VS Code, and try again." -ForegroundColor Red
  exit 1
}
if (-not (Test-Path ".\pubspec.yaml")) {
  Write-Host "Open this script from the project root folder." -ForegroundColor Red
  exit 1
}
if (-not (Test-Path ".\windows") -or -not (Test-Path ".\web") -or -not (Test-Path ".\android")) {
  flutter create --platforms=android,web,windows --org com.munazza --project-name pandas_magical_bamboo_world .
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
dart run flutter_launcher_icons
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter run
