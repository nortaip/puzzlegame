import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';

/// Store with just two tabs: power-ups (bought with earned coins) and coin packs
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const CoinDisplay(),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: 'Power-ups'),
                    Tab(text: 'Coins'),
                  ],
                ),
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
    final player = ref.read(playerControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StoreRow(
          icon: Icons.local_police_rounded,
          title: 'Police ×3',
          subtitle: 'Escort stuck cars off the board',
          cost: AppConstants.policeUnlockCost * 2,
          onBuy: () => _buy(ref, AppConstants.policeUnlockCost * 2,
              () => player.grantPolice(3)),
        ),
        _StoreRow(
          icon: Icons.shuffle_rounded,
          title: 'Shuffle ×3',
          subtitle: 'Re-randomise into a fresh, solvable jam',
          cost: AppConstants.shuffleCost * 2,
          onBuy: () => _buy(ref, AppConstants.shuffleCost * 2,
              () => player.grantShuffle(3)),
        ),
        _StoreRow(
          icon: Icons.lightbulb_rounded,
          title: 'Hints ×5',
          subtitle: 'Highlight the best car to send off',
          cost: AppConstants.hintCost * 3,
          onBuy: () =>
              _buy(ref, AppConstants.hintCost * 3, () => player.grantHint(5)),
        ),
      ],
    );
  }
}

class _CoinsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.read(iapServiceProvider);
    final packs = [
      ('coins_small', '500 Coins', Icons.savings_rounded),
      ('coins_medium', '1,500 Coins', Icons.account_balance_wallet_rounded),
      ('coins_large', '5,000 Coins', Icons.diamond_rounded),
      ('remove_ads', 'Remove Ads', Icons.block_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!iap.available)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Store unavailable on this device.',
                style: TextStyle(color: Colors.white70)),
          ),
        for (final p in packs)
          _StoreRow(
            icon: p.$3,
            title: p.$2,
            subtitle: iap.productById(p.$1)?.price ?? '—',
            cost: -1, // real-money item
            onBuy: () => iap.buy(p.$1),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => iap.restore(),
          child: const Text('Restore Purchases',
              style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

Future<void> _buy(WidgetRef ref, int cost, Future<void> Function() grant) async {
  final player = ref.read(playerControllerProvider.notifier);
  if (await player.spendCoins(cost)) {
    await grant();
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int cost; // -1 => real-money price shown in subtitle
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBuy,
              child: cost >= 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, size: 16),
                        const SizedBox(width: 4),
                        Text('$cost'),
                      ],
                    )
                  : const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}
