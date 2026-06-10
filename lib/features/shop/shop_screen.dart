import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/haptics.dart';
import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';

/// Store with two tabs: power-ups (bought with earned coins) and coin packs
/// (real-money IAP). No pay-to-win, no cosmetics — only convenience boosts.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final theme = EnvironmentTheme.byIndex(profile.activeThemeIndex);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: GradientBackground(
          colors: theme.backgroundGradient,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text('Shop',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const CoinDisplay(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(5),
                    borderRadius: 18,
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle:
                          const TextStyle(fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(text: 'Power-ups'),
                        Tab(text: 'Coins'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PowerUpsTab(),
                      _CoinsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerUpsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final player = ref.read(playerControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PowerCard(
          accent: const Color(0xFF4FC3F7),
          icon: Icons.local_police_rounded,
          title: 'Police',
          subtitle: 'Escort stuck cars off the board',
          owned: profile.policeCharges,
          cost: AppConstants.policeUnlockCost * 2,
          amount: '×3',
          onBuy: () => _buy(context, ref, AppConstants.policeUnlockCost * 2,
              () => player.grantPolice(3)),
        ),
        _PowerCard(
          accent: const Color(0xFFB388FF),
          icon: Icons.shuffle_rounded,
          title: 'Shuffle',
          subtitle: 'Re-randomise into a fresh, solvable jam',
          owned: profile.shuffleCharges,
          cost: AppConstants.shuffleCost * 2,
          amount: '×3',
          onBuy: () => _buy(context, ref, AppConstants.shuffleCost * 2,
              () => player.grantShuffle(3)),
        ),
        _PowerCard(
          accent: const Color(0xFFFFD54F),
          icon: Icons.lightbulb_rounded,
          title: 'Hint',
          subtitle: 'Highlight the best car to send off',
          owned: profile.hintCharges,
          cost: AppConstants.hintCost * 3,
          amount: '×5',
          onBuy: () => _buy(context, ref, AppConstants.hintCost * 3,
              () => player.grantHint(5)),
        ),
      ],
    );
  }
}

class _CoinsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.read(iapServiceProvider);
    final packs = <_Pack>[
      _Pack('coins_small', '500', Icons.savings_rounded),
      _Pack('coins_medium', '1,500', Icons.account_balance_wallet_rounded,
          badge: 'POPULAR'),
      _Pack('coins_large', '5,000', Icons.diamond_rounded, badge: 'BEST VALUE'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (!iap.available)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Store unavailable on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
          ),
        for (final p in packs)
          _CoinCard(
            amount: p.amount,
            icon: p.icon,
            price: iap.productById(p.id)?.price ?? '—',
            badge: p.badge,
            onBuy: () => iap.buy(p.id),
          ),
        const SizedBox(height: 8),
        _PowerCard(
          accent: const Color(0xFFEF5350),
          icon: Icons.block_rounded,
          title: 'Remove Ads',
          subtitle: 'Play without rewarded-ad offers',
          owned: 0,
          cost: -1,
          amount: iap.productById('remove_ads')?.price ?? '',
          onBuy: () => iap.buy('remove_ads'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => iap.restore(),
            child: const Text('Restore Purchases',
                style: TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }
}

Future<void> _buy(
  BuildContext context,
  WidgetRef ref,
  int cost,
  Future<void> Function() grant,
) async {
  final player = ref.read(playerControllerProvider.notifier);
  if (await player.spendCoins(cost)) {
    Haptics.success();
    await grant();
  } else {
    Haptics.error();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Not enough coins')));
    }
  }
}

class _Pack {
  _Pack(this.id, this.amount, this.icon, {this.badge});
  final String id;
  final String amount;
  final IconData icon;
  final String? badge;
}

/// A power-up / entitlement card with an accent icon and a price button.
class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.owned,
    required this.cost,
    required this.amount,
    required this.onBuy,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final int owned;
  final int cost; // -1 => real-money (price shown in [amount])
  final String amount;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (cost >= 0) ...[
                        const SizedBox(width: 6),
                        Text(amount,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  if (cost >= 0) ...[
                    const SizedBox(height: 4),
                    Text('Owned: $owned',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onBuy,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: cost >= 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, size: 16),
                        const SizedBox(width: 4),
                        Text('$cost'),
                      ],
                    )
                  : Text(amount.isEmpty ? 'Buy' : amount),
            ),
          ],
        ),
      ),
    );
  }
}

/// A coin-pack card with an optional badge.
class _CoinCard extends StatelessWidget {
  const _CoinCard({
    required this.amount,
    required this.icon,
    required this.price,
    required this.onBuy,
    this.badge,
  });

  final String amount;
  final IconData icon;
  final String price;
  final String? badge;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFFFD54F), size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      Text(amount,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                      const SizedBox(width: 6),
                      const Text('coins',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  child: Text(price,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25), blurRadius: 6),
                  ],
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}
