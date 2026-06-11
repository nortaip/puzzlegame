# AdMob setup — what to do in the console

## 1. Account
- Sign in at **https://admob.google.com** with a Google account.
- Add your **payment info** (AdMob → Payments) — required to get paid.
- Have a **privacy policy URL** ready (required by both stores + AdMob).

## 2. Register the app (one entry per platform)
AdMob → **Apps → Add app**:
- Platform **iOS** → if not on the App Store yet, choose "No / not listed".
- Platform **Android** → same.

Each registered app gives you an **App ID** that looks like:
`ca-app-pub-0000000000000000~1111111111`  ← note the **`~`**

## 3. Create the ad units (4 total)
For **each** app (iOS and Android), AdMob → **Ad units → Add ad unit**:

| Ad unit            | Format        |
|--------------------|---------------|
| Rewarded           | **Rewarded**  |
| Interstitial       | **Interstitial** |

Each unit gives an **Ad unit ID** like:
`ca-app-pub-0000000000000000/2222222222`  ← note the **`/`**

So you end up with:
- iOS App ID, Android App ID
- iOS Rewarded, Android Rewarded
- iOS Interstitial, Android Interstitial

## 4. Where each ID goes in this project

**App ID** (the `~` one) → native config:
- iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier` (see `ios_setup.md`)
- Android: `android/app/src/main/AndroidManifest.xml` →
  `com.google.android.gms.ads.APPLICATION_ID` meta-data (see README)

**Ad unit IDs** (the `/` ones) → passed at build time:
```bash
flutter build ipa \   # or: flutter build appbundle
  --dart-define=ADMOB_APP_ID_IOS=ca-app-pub-XXXX~XXXX \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-YYYY~YYYY \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-YYYY/YYYY \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-YYYY/YYYY
```
(These map to `AppConfig`. Without them the app uses Google's **test** ids.)

## 5. app-ads.txt (recommended)
AdMob → **App settings** shows your `app-ads.txt` line. Host it at
`https://yourdomain.com/app-ads.txt` (the domain in your store listing) to
maximise fill and prevent ad fraud.

## 6. Test safely (important)
- **Never click your own live ads** — it can get your account banned.
- During development keep the **test ad unit ids** (the defaults), or register
  your phone as a **test device**:
  `MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: ['YOUR_DEVICE_ID']));`
  (the device id is printed in the console on first ad load).

## 7. Consent / ATT (personalized ads)
- iOS 14.5+: show the **App Tracking Transparency** prompt
  (`NSUserTrackingUsageDescription` is already documented in `ios_setup.md`).
- EU users: add Google's **UMP / consent** form (AdMob → Privacy & messaging →
  GDPR & US states) and the `google_mobile_ads` consent flow. Non-personalized
  ads still work if the user declines.

## 8. Go live
- New ad units can take a few hours to start serving real ads.
- Submit the app to the stores; AdMob auto-detects the listing and links it.

## Summary checklist
- [ ] AdMob account + payments + privacy policy
- [ ] iOS app + Android app registered → 2 App IDs
- [ ] Rewarded + Interstitial unit for each platform → 4 unit IDs
- [ ] App IDs in Info.plist / AndroidManifest
- [ ] Unit IDs passed via `--dart-define`
- [ ] app-ads.txt hosted
- [ ] Test device registered (don't click live ads)
- [ ] ATT + UMP consent configured
