# Shipping to the App Store — full checklist

> Requires **macOS + Xcode** and an **Apple Developer Program** membership
> ($99/year). None of this can be done from Linux/Windows or by code alone.

## 0. One-time accounts
- [ ] Apple Developer Program enrolled → https://developer.apple.com/programs/
- [ ] App created in **App Store Connect** → https://appstoreconnect.apple.com
      (My Apps → + → New App; bundle id `asif.nesrullazade.flowParkPuzzle`)

## 1. Generate & configure the project (on the Mac)
```bash
flutter create --org asif.nesrullazade --project-name flow_park_puzzle .
flutter pub get
cd ios && pod install && cd ..
```
- [ ] `ios/Runner/Info.plist`: add `GADApplicationIdentifier`
      (`ca-app-pub-9956181196959200~3801211454`), `NSUserTrackingUsageDescription`,
      and the `SKAdNetworkItems` list — see `ios_setup.md`.
- [ ] App icon: put logo at `assets/icon/app_icon.png`, run
      `dart run flutter_launcher_icons`.
- [ ] Display name `Park Flow`: Info.plist `CFBundleDisplayName`.

## 2. Signing (Xcode)
```bash
open ios/Runner.xcworkspace
```
- [ ] Runner target → Signing & Capabilities → select your **Team**.
- [ ] Bundle Identifier = `asif.nesrullazade.flowParkPuzzle`.
- [ ] + Capability → **In-App Purchase**.

## 3. In-App Purchases (App Store Connect)
- [ ] Create products with the IDs + prices from `monetization.md`
      (`coins_small` $0.99, `coins_medium` $2.99, `coins_large` $4.99,
      `remove_ads` $2.99).
- [ ] Add a **Sandbox tester** (Users and Access → Sandbox) to test purchases.

## 4. AdMob
- [ ] App ID in Info.plist (done in step 1).
- [ ] Pass real unit ids at build time:
```bash
flutter build ipa \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-9956181196959200/1805064504 \
  --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-9956181196959200/7846066544
```

## 5. Build & upload
- **Option A (Xcode):** Xcode → Product → Archive → Distribute App → App Store
  Connect → Upload.
- **Option B (CLI):** `flutter build ipa …` then upload
  `build/ios/ipa/*.ipa` with **Transporter** (Mac App Store) or
  `xcrun altool --upload-app`.

## 6. App Store Connect — listing & submit
- [ ] Screenshots (6.7" + 6.5" iPhone; iPad if supported).
- [ ] App name, subtitle, description, keywords, category (Games › Puzzle).
- [ ] **Privacy policy URL** (required — also for ads).
- [ ] App Privacy questionnaire: declare data use (AdMob = ads/identifiers;
      Supabase = optional user content).
- [ ] Age rating.
- [ ] Attach the build (from step 5), the IAPs, then **Submit for Review**.

## No Mac? Use cloud macOS
- **Codemagic** (flutter-friendly, free tier) or **Xcode Cloud** or
  **GitHub Actions** (`macos-latest` runner). All can build the `.ipa` and
  upload to TestFlight using an **App Store Connect API key** stored as a secret.
- This still requires the Apple Developer membership and the API key from
  App Store Connect → Users and Access → Integrations → App Store Connect API.
