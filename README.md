# Flow & Park Puzzle 🚗🧩

A hyper-casual, **fully-offline** car-parking jam puzzle built with Flutter, with
an optional liquid-sort expansion mode. Every car has an **arrow**: tap it and it
drives forward off the board if the lane ahead is clear — **clear the whole road**
to win. Levels are **procedurally generated, get harder as you climb**, and are
**provably solvable**; the UI is glassmorphic and animated at 60 FPS, and the
whole economy (coins, power-ups) works without a network connection.
Supabase is used only for optional cloud save, analytics and leaderboards.

> **Heads-up:** this repository contains the full Dart/Flutter source and tests.
> The platform folders (`android/`, `ios/`, `web/`) are generated locally with
> `flutter create .` — see [Getting started](#getting-started).

---

## Highlights

- ✅ **Always-solvable generator.** Levels are built by *reverse construction*
  (cars are driven *in* from the edges), so driving them back out in reverse
  order is always a valid solution — there is no code path that emits an
  unclearable board. Re-verified by a greedy solver and proven by
  `test/level_generator_test.dart`.
- ⚡ **Instant restart & level transitions.** Levels are cached and the next one
  is prefetched off the critical path, so there are no loading delays.
- 📦 **Offline-first.** A local JSON store (shared_preferences) is the source of truth; Supabase sync is best-effort
  and never blocks gameplay.
- 🎨 **Premium feel.** Five environment themes, liquid-glass UI, smooth easing,
  confetti win celebration, haptics and sound effects (honk, drive-off, siren,
  win, coin). Cars drift off with a fishtail and leave tyre marks; tap a car
  right behind a departing one and it follows with high beams, a double honk and
  a horn icon. A blocked car blinks its amber hazards and honks; the Police
  power-up flashes the board blue/red with a siren and an officer on scene.
- 💰 **Ethical monetization.** Rewarded ads only, plus convenience boosts — no
  pay-to-win.

---

## Architecture

```
lib/
├── main.dart                 # Bootstrap: services + Riverpod overrides
├── app.dart                  # MaterialApp + theme
├── core/                     # Config, constants, theme, utils (haptics)
├── game/
│   ├── models/               # Vehicle, Board, Level, Direction (pure logic)
│   ├── logic/                # Solver (BFS), LevelGenerator, Difficulty curve
│   └── themes/               # Environment themes (City, Neon, Rainy, …)
├── liquid/                   # Optional liquid-sort mode (engine + models)
├── services/
│   ├── storage/              # LocalStore (shared_preferences JSON) — offline truth
│   ├── supabase/             # Cloud save, analytics, sync, leaderboard
│   ├── ads/                  # AdMob rewarded ads
│   ├── iap/                  # In-app purchases
│   └── analytics/            # Event facade
├── state/                    # Riverpod controllers (player, game, loader)
├── widgets/                  # Reusable UI (glass panel, gradient bg, coins)
└── features/                 # Screens: splash, menu, level select, game, shop
```

State management is **Riverpod** (hand-written providers, no codegen). The game logic in `game/models` and
`game/logic` is pure Dart (no Flutter imports), which is what makes it unit
testable and fast.

### How "always solvable" is guaranteed

The solved state is an *empty* board. `LevelGenerator` builds a puzzle by driving
cars **in** from the borders: each new car enters from one edge and parks at some
depth, and it is only placed if the whole lane it travelled through is currently
empty. Driving the cars back out in the reverse of their placement order is
therefore always a valid solution. On top of that, driving a car off only ever
*frees* cells, so it can never jam another car — which means a simple greedy
elimination (`PuzzleSolver.canClear`) is a complete solvability check, used here
as a defensive re-verification. See `lib/game/logic/level_generator.dart`.

The liquid-sort generator uses a complementary principle: random balanced fill +
`isSolvable` verification (`lib/liquid/liquid_sort_engine.dart`).

---

## Getting started

```bash
# 1. Generate the platform folders this package runs on (android/, ios/, web/).
flutter create .

# 2. Fetch dependencies.
flutter pub get

# 3. Run — no code generation required.
flutter run                 # mobile / desktop
flutter run -d chrome       # web
```

> Storage uses `shared_preferences` (JSON), so there are **no `*.g.dart` files
> and no `build_runner` step**. The mobile-only plugins (AdMob, in-app
> purchase) are isolated behind conditional imports, so the web build compiles
> and runs — ads/IAP simply report "unavailable" there and power-ups fall back
> to spending coins.

### Configuration (secrets via --dart-define)

Never hard-code keys. Supabase and AdMob unit ids are injected at build time
(see `lib/core/config/app_config.dart`). Google's **test** ad units are the
defaults, so the app runs safely out of the box.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXX/ZZZZ
```

### AdMob native setup

After `flutter create .`, add your AdMob **app id** (not unit id):

- **Android** — `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXX~XXXXXXXX"/>
  ```
- **iOS** — `ios/Runner/Info.plist`:
  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-XXXXXXXX~XXXXXXXX</string>
  ```

### Supabase setup

Run [`docs/supabase_schema.sql`](docs/supabase_schema.sql) in the Supabase SQL
editor, enable anonymous sign-in, and pass the URL + anon key via `--dart-define`.

---

## Tests

```bash
flutter test
```

- `test/level_generator_test.dart` — proves the always-solvable guarantee across
  the difficulty curve, plus a 40-level stress sweep.
- `test/board_test.dart` — drive-off mechanics (occupancy, open vs jammed lanes,
  clearing the board).
- `test/liquid_sort_test.dart` — liquid-sort generator solvability.

---

## Gameplay & progression

| Levels   | Grid  | Vehicles / mechanics                      |
|----------|-------|-------------------------------------------|
| 1–8      | 5×5   | cars + minivans (length 2–3)              |
| 9–40     | 6×6   | + buses (length 4)                        |
| 41–100   | 7×7   | + trucks, deeper jams, tighter packing    |
| 101–130  | 8×8   | densest jams, most big vehicles           |
| 131+     | 9×9 … | grid grows by one every 30 levels (→12)   |

From level 12, **roadside trees** are scattered (mostly along the borders) as
static obstacles that close off some exits. The generator places trees before
the cars and keeps every car's exit lane tree-free, so harder boards stay 100%
solvable while leaving plenty of open exits.

**Goal:** clear the road — drive every car off the board. Tap a car to send it
forward in its arrow direction; tap one whose lane is jammed and it lunges and
bumps. A clean clear with no blocked taps earns three stars. Each car's arrow is
fixed, so deeper levels (more cars, parked deeper) need longer un-jamming chains.

**Power-ups:** 🚓 Police (a police car drives to the centre and escorts up to
three stuck cars off, one by one) · 🔄 Shuffle (re-randomise into a fresh,
still-clearable layout) · 💡 Hint (highlights the most obvious car to send off).
Each is free while you have charges, then payable with coins or a rewarded ad.

The shop is intentionally minimal — **only power-ups and coin packs** (no
pay-to-win, no cosmetics).

---

## License

Proprietary — sample project.
