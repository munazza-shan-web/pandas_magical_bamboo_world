# Optional: add flutter_launcher_icons, then generate native launcher icons.
flutter pub add --dev flutter_launcher_icons
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
@"
flutter_launcher_icons:
  android: true
  image_path: "assets/branding/panda_icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/branding/panda_icon.png"
    background_color: "#173D31"
    theme_color: "#173D31"
  windows:
    generate: true
    image_path: "assets/branding/panda_icon.png"
"@ | Add-Content .\pubspec.yaml
flutter pub get
dart run flutter_launcher_icons
