# Branding: app icon, logo & bundle id

## App icon (the PARK FLOW logo)
1. Save the logo as a **square, opaque PNG** (1024×1024 recommended) at:
   `assets/icon/app_icon.png`
2. (Optional) Save the same logo for the splash/menu at:
   `assets/branding/logo.png`  ← shown in-app automatically when present
3. Generate the platform icons:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
   This writes the iOS/Android app icons. Config lives in `pubspec.yaml`
   (`flutter_launcher_icons:`).

> The in-app `BrandLogo` widget shows `assets/branding/logo.png` if it exists,
> otherwise a drawn fallback — so the app never breaks without the file.

## Bundle id → `asif.dev.flowParkPuzzle`

### If you haven't created the native folders yet
Create them with your organisation so the id is correct from the start:
```bash
flutter create --org asif.dev --project-name flow_park_puzzle .
```
→ iOS bundle id / Android applicationId become `asif.dev.flowParkPuzzle`.

### If you already ran `flutter create .` (id is com.example.…)
Easiest is to regenerate:
```bash
rm -rf ios android        # keep lib/ etc.
flutter create --org asif.dev --project-name flow_park_puzzle .
```
Or change it in place:
- **iOS:** Xcode → Runner target → *Signing & Capabilities* → **Bundle Identifier** =
  `asif.dev.flowParkPuzzle`
- **Android:** `android/app/build.gradle` → `applicationId "asif.dev.flowParkPuzzle"`,
  and update `namespace` + the `package` in `AndroidManifest.xml` / Kotlin folder
  (the `rename` or `change_app_package_name` pub packages automate this).

## App display name
The shown name is **Park Flow** (`AppConstants.appName`). To change the
home-screen label:
- iOS: `ios/Runner/Info.plist` → `CFBundleDisplayName` = `Park Flow`
- Android: `android/app/src/main/AndroidManifest.xml` → `android:label="Park Flow"`
