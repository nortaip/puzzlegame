# iOS setup

Step-by-step to make the app App-Store ready on iOS. (Run on macOS with Xcode.)

## 1. Generate the iOS project
```bash
flutter create .            # creates ios/ (and android/, web/)
flutter pub get
cd ios && pod install && cd ..
```

## 2. Minimum iOS version (Podfile)
`google_mobile_ads` and `supabase_flutter` need iOS 13+. In `ios/Podfile`:
```ruby
platform :ios, '13.0'
```

## 3. Info.plist — AdMob, ATT & SKAdNetwork
Add to `ios/Runner/Info.plist` (inside the top-level `<dict>`):

```xml
<!-- AdMob application id (NOT a unit id) -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>

<!-- App Tracking Transparency prompt (iOS 14.5+) -->
<key>NSUserTrackingUsageDescription</key>
<string>We use your data to show you more relevant ads.</string>

<!-- SKAdNetwork ids for ad attribution. Paste Google's full current list:
     https://developers.google.com/admob/ios/quick-start#update_your_infoplist -->
<key>SKAdNetworkItems</key>
<array>
  <dict><key>SKAdNetworkIdentifier</key><string>cstr6suwn9.skadnetwork</string></dict>
  <!-- … add the remaining identifiers from Google's list … -->
</array>
```

> The default `GADApplicationIdentifier` can use Google's test app id
> `ca-app-pub-3940256099942544~1458002511` until you have your own.

### App Tracking Transparency
On first launch request the ATT prompt before loading personalized ads. Either
add the `app_tracking_transparency` package and call
`AppTrackingTransparency.requestTrackingAuthorization()` in `main()`, or rely on
non-personalized ads. AdMob still works if the user declines.

## 4. In-App Purchase capability
- Xcode → Runner target → **Signing & Capabilities** → **+ Capability** →
  **In-App Purchase**.
- In **App Store Connect**, create the products with the IDs and price tiers in
  [`monetization.md`](monetization.md):
  `coins_small`, `coins_medium`, `coins_large` (consumable), `remove_ads`
  (non-consumable).
- Test with a **Sandbox Apple ID** (Settings → App Store → Sandbox Account).

## 5. Signing
- Xcode → Runner → Signing & Capabilities → select your **Team**, set a unique
  **Bundle Identifier** (e.g. `com.yourco.flowpark`).

## 6. Supabase (cloud save / leaderboard)
- Enable **Anonymous sign-ins** (Authentication → Providers).
- Run [`supabase_schema.sql`](supabase_schema.sql) in the SQL editor.
- URL + anon key are baked in (see `AppConfig`) or overridden via `--dart-define`.

## 7. Build & ship
```bash
flutter build ipa \
  --dart-define=ADMOB_APP_ID_IOS=ca-app-pub-XXXX~XXXX \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXX/XXXX
```
Open `build/ios/archive/Runner.xcarchive` in Xcode Organizer → Distribute App →
App Store Connect.

## Checklist
- [ ] `GADApplicationIdentifier` + SKAdNetwork list in Info.plist
- [ ] `NSUserTrackingUsageDescription` set
- [ ] In-App Purchase capability + products created with prices
- [ ] Team + bundle id configured
- [ ] Anonymous auth enabled + schema run
- [ ] Real AdMob ids passed via `--dart-define`
- [ ] App icon (`flutter_launcher_icons`) and launch screen set
