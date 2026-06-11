import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../game/models/level.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_controller.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';
import '../shop/shop_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/game_hud.dart';
import 'widgets/hearts_display.dart';
import 'widgets/out_of_hearts_overlay.dart';
import 'widgets/powerup_bar.dart';
import 'widgets/win_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.level, this.isDaily = false});

  final Level level;
  final bool isDaily;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Load the level into the controller after the first frame so providers are
    // ready and the transition stays smooth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).loadLevel(widget.level);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final profile = ref.watch(playerControllerProvider);

    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = game.theme;
    final won = game.status == GameStatus.won;

    return Scaffold(
      body: GradientBackground(
        colors: theme.backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GameHud(
                            levelNumber: game.level.number,
                            carsLeft: game.carsLeft,
                            totalCars: game.totalCars,
                            isDaily: widget.isDaily,
                            onBack: () => Navigator.of(context).pop(),
                            onRestart: () => ref
                                .read(gameControllerProvider.notifier)
                                .restart(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const HeartsDisplay(),
                        GameCoins(onTap: () => _openShop(context)),
                      ],
                    ),
                    const Spacer(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final side = constraints.maxWidth.clamp(0.0, 460.0);
                        return Center(child: BoardWidget(size: side));
                      },
                    ),
                    const Spacer(),
                    PowerUpBar(
                      powerUps: [
                        PowerUp(
                          icon: Icons.local_police_rounded,
                          label: 'Police',
                          charges: profile.policeCharges,
                          cost: AppConstants.policeUnlockCost,
                          onTap: _usePolice,
                        ),
                        PowerUp(
                          icon: Icons.shuffle_rounded,
                          label: 'Shuffle',
                          charges: profile.shuffleCharges,
                          cost: AppConstants.shuffleCost,
                          onTap: _useShuffle,
                        ),
                        PowerUp(
                          icon: Icons.lightbulb_rounded,
                          label: 'Hint',
                          charges: profile.hintCharges,
                          cost: AppConstants.hintCost,
                          onTap: _useHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (won)
                WinOverlay(
                  stars: game.stars,
                  moves: game.moveCount,
                  coinsEarned: AppConstants.baseLevelReward +
                      game.stars * AppConstants.perStarBonus,
                  onHome: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  onReplay: () =>
                      ref.read(gameControllerProvider.notifier).restart(),
                  onNext: _goNext,
                ),
              if (game.status == GameStatus.lost)
                OutOfHeartsOverlay(
                  onHome: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShop(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ShopScreen()));

  Future<void> _goNext() async {
    // Forced interstitial every few levels (skipped if "Remove Ads" bought).
    final profile = ref.read(playerControllerProvider);
    await ref.read(adGateProvider).onLevelCompleted(
          adsRemoved: profile.adsRemoved,
          level: widget.level.number,
        );
    if (!mounted) return;
    final next = ref.read(levelLoaderProvider).load(widget.level.number + 1);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(level: next)),
    );
  }

  // ── Power-up activation ─────────────────────────────────────────────────

  Future<void> _usePolice() => _activate(
        consume: () =>
            ref.read(playerControllerProvider.notifier).consumePolice(),
        cost: AppConstants.policeUnlockCost,
        placement: AdPlacement.unlockSkill,
        action: () {
          final ok =
              ref.read(gameControllerProvider.notifier).usePolice();
          if (!ok) _toast('No cars to escort');
          return ok;
        },
      );

  Future<void> _useShuffle() => _activate(
        consume: () =>
            ref.read(playerControllerProvider.notifier).consumeShuffle(),
        cost: AppConstants.shuffleCost,
        placement: AdPlacement.extraUndo,
        action: () {
          final ok =
              ref.read(gameControllerProvider.notifier).useShuffle();
          if (!ok) _toast('Could not shuffle');
          return ok;
        },
      );

  Future<void> _useHint() => _activate(
        consume: () =>
            ref.read(playerControllerProvider.notifier).consumeHint(),
        cost: AppConstants.hintCost,
        placement: AdPlacement.hint,
        action: () {
          ref.read(gameControllerProvider.notifier).showHint();
          return true;
        },
      );

  /// Spends a free charge if available; otherwise offers to pay with coins or a
  /// rewarded ad, then runs [action] if the cost is met.
  Future<void> _activate({
    required Future<bool> Function() consume,
    required int cost,
    required AdPlacement placement,
    required bool Function() action,
  }) async {
    final game = ref.read(gameControllerProvider);
    if (game == null || game.status != GameStatus.playing) return;

    if (await consume()) {
      action();
      return;
    }

    if (!mounted) return;
    final choice = await _showPayoffSheet(cost);
    if (choice == _Payoff.coins) {
      final paid =
          await ref.read(playerControllerProvider.notifier).spendCoins(cost);
      if (paid) {
        action();
      } else {
        _toast('Not enough coins');
      }
    } else if (choice == _Payoff.ad) {
      final earned =
          await ref.read(adsServiceProvider).showRewarded(placement);
      if (earned) {
        ref.read(analyticsServiceProvider).rewardedAdWatched(placement.name);
        action();
      } else {
        _toast('Ad not available');
      }
    }
  }

  Future<_Payoff?> _showPayoffSheet(int cost) {
    return showModalBottomSheet<_Payoff>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassPanel(
          opacity: 0.18,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Use power-up',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, _Payoff.coins),
                icon: const Icon(Icons.monetization_on),
                label: Text('Pay $cost coins'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(ctx, _Payoff.ad),
                icon: const Icon(Icons.ondemand_video_rounded),
                label: const Text('Watch ad'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }
}

enum _Payoff { coins, ad }
