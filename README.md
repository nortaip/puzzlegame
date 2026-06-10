# Flow & Park Puzzle 🚗🧩

A hyper-casual, **fully-offline** car-parking unblock puzzle built with Flutter,
with an optional liquid-sort expansion mode. Levels are **procedurally generated
and provably solvable**, the UI is glassmorphic and animated at 60 FPS, and the
whole economy (coins, power-ups, cosmetics) works without a network connection.
Supabase is used only for optional cloud save, analytics and leaderboards.

> **Heads-up:** this repository contains the full Dart/Flutter source and tests.
> The native platform folders (`android/`, `ios/`) are generated locally with
> `flutter create .` — see [Getting started](#getting-started).

---

## Highlights

- ✅ **Always-solvable generator.** Every level is verified with a BFS solver
  before it ships to the player — there is no code path that emits an
  unsolvable or soft-locked board. Proven by `test/level_generator_test.dart`.
- ⚡ **Instant restart & level transitions.** Levels are cached and the next one
  is prefetched off the critical path, so there are no loading delays.
- 📦 **Offline-first.** Isar is the source of truth; Supabase sync is best-effort
  and never blocks gameplay.
- 🎨 **Premium feel.** Five environment themes, glassmorphism HUD, smooth
  easing, confetti win celebration, haptics.
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
│   ├── storage/              # Isar DB + collections (offline source of truth)
│   ├── supabase/             # Cloud save, analytics, sync, leaderboard
│   ├── ads/                  # AdMob rewarded ads
│   ├── iap/                  # In-app purchases
│   └── analytics/            # Event facade
├── state/                    # Riverpod controllers (player, game, loader)
├── widgets/                  # Reusable UI (glass panel, gradient bg, coins)
└── features/                 # Screens: splash, menu, level select, game, shop
```

State management is **Riverpod**. The game logic in `game/models` and
`game/logic` is pure Dart (no Flutter imports), which is what makes it unit
testable and fast.

### How "always solvable" is guaranteed

`LevelGenerator` builds a candidate board (a horizontal target vehicle on the
exit row, a forced blocker, and random obstacles), then **proves** it with
`PuzzleSolver` (breadth-first search over the position-encoded state space).
A candidate is accepted only if the solver finds a solution *and* the optimal
move count lands inside the level's difficulty band. Because acceptance requires
a solver-verified solution, an unsolvable board can never escape the loop. The
difficulty band relaxes if needed, but solvability never does. See
`lib/game/logic/level_generator.dart`.

The liquid-sort generator uses the same principle: random balanced fill +
`isSolvable` verification (`lib/liquid/liquid_sort_engine.dart`).

---

## Getting started

```bash
# 1. Generate native platform folders (android/, ios/) for this package.
flutter create .

# 2. Fetch dependencies.
flutter pub get

# 3. Generate Isar + Riverpod code (creates the *.g.dart files).
dart run build_runner build --delete-conflicting-outputs

# 4. Run.
flutter run
```

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
  the difficulty curve, plus a 100-level stress sweep.
- `test/board_test.dart` — board mechanics (occupancy, blocking, win, bounds).
- `test/liquid_sort_test.dart` — liquid-sort generator solvability.

---

## Gameplay & progression

| Levels   | Grid | New mechanics            |
|----------|------|--------------------------|
| 1–10     | 5×5  | basics                   |
| 11–50    | 6×6  | trucks (length 3)        |
| 51–120   | 7×7  | locked cars (Police)     |
| 121+     | 8×8  | denser packing           |

**Power-ups:** 🚓 Police (remove a blocker) · 🔄 Shuffle (re-randomise, stays
solvable) · 💡 Hint (optimal next move from the solver). Each is free while you
have charges, then payable with coins or a rewarded ad.

---

## License

Proprietary — sample project.
