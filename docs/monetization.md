# Monetization

## Ad placements — *when* ads show

### Rewarded ads (opt-in — the player always taps to watch)
| Where | Reward |
|-------|--------|
| **Out of hearts** overlay | +1 heart (resume the level) |
| **Power-up** with no free charges *and* not enough coins (Hint / Police / Shuffle) | use the power-up once |

Rewarded ads never interrupt play — they're always a button the player chooses.

### Interstitial ads (forced — full-screen between levels)
- Shown on **Next**, after completing a level.
- **Every 3rd completed level** (`AppConstants.interstitialEveryNLevels`).
- **Never before level 4** (`AppConstants.interstitialMinLevel`) so new players settle in.
- **Skipped entirely** if the player bought **Remove Ads**.

Cadence is handled by `AdGate` (`lib/services/ads/ad_gate.dart`); tune the two
constants to change frequency. There are no banner or app-open ads.

## In-app purchases — products & suggested prices

Prices are set in **App Store Connect** / **Google Play Console**; the app shows
the localized store price. Use the same product IDs as in
`AppConfig.iapProductIds`.

| Product ID     | Type            | Suggested price | Grants            |
|----------------|-----------------|-----------------|-------------------|
| `coins_small`  | Consumable      | **$0.99**       | 500 coins         |
| `coins_medium` | Consumable      | **$2.99**       | 1,500 coins · *POPULAR* |
| `coins_large`  | Consumable      | **$4.99**       | 5,000 coins · *BEST VALUE* |
| `remove_ads`   | Non-consumable  | **$2.99**       | disables interstitials |

(US tiers shown; the stores auto-convert to local currencies.)

> Production note: verify receipts server-side (e.g. a Supabase Edge Function)
> before granting `remove_ads`. Coin packs are low-risk consumables.

## Production keys (inject at build time)

```
flutter build ipa \
  --dart-define=ADMOB_APP_ID_IOS=ca-app-pub-XXXX~XXXX \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-XXXX/XXXX \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=...
```

Google's official **test** ad units are the defaults, so debug builds never
serve live ads.
