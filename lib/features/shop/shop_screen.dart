import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../game/themes/environment_theme.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';

/// Store for power-ups, themes, skins and coin packs. Cosmetic items are bought
/// with earned coins; coin packs use real-money IAP. No pay-to-win items —
/// only convenience boosts, per the design.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final theme = EnvironmentTheme.byIndex(profile.activeThemeIndex);

    return DefaultTabController(
      length: 4,
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
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: 'Power-ups'),
                    Tab(text: 'Themes'),
                    Tab(text: 'Skins'),
                    Tab(text: 'Coins'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PowerUpsTab(),
                      _ThemesTab(),
                      _SkinsTab(),
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
          title: 'Police Unlock ×3',
          subtitle: 'Remove a blocking car',
          cost: AppConstants.policeUnlockCost * 2,
          onBuy: () => _buy(ref, AppConstants.policeUnlockCost * 2,
              () => player.grantPolice(3)),
        ),
        _StoreRow(
          icon: Icons.shuffle_rounded,
          title: 'Shuffle ×3',
          subtitle: 'Re-randomise non-essential cars',
          cost: AppConstants.shuffleCost * 2,
          onBuy: () => _buy(ref, AppConstants.shuffleCost * 2,
              () => player.grantShuffle(3)),
        ),
        _StoreRow(
          icon: Icons.lightbulb_rounded,
          title: 'Hints ×5',
          subtitle: 'Reveal the best next move',
          cost: AppConstants.hintCost * 3,
          onBuy: () =>
              _buy(ref, AppConstants.hintCost * 3, () => player.grantHint(5)),
        ),
      ],
    );
  }
}

class _ThemesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final player = ref.read(playerControllerProvider.notifier);
    const themeCost = 800;
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        for (final t in EnvironmentTheme.all)
          _CosmeticTile(
            label: t.name,
            owned: profile.ownedThemes.contains(t.id),
            active: profile.activeThemeIndex == t.id,
            preview: t.backgroundGradient,
            cost: themeCost,
            onBuy: () => _buy(ref, themeCost, () => player.unlockTheme(t.id)),
            onSelect: () => player.selectTheme(t.id),
          ),
      ],
    );
  }
}

class _SkinsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final player = ref.read(playerControllerProvider.notifier);
    final palette = EnvironmentTheme.byIndex(profile.activeThemeIndex).vehiclePalette;
    const skinCost = 500;
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        for (var i = 0; i < palette.length; i++)
          _CosmeticTile(
            label: 'Skin ${i + 1}',
            owned: profile.ownedSkins.contains(i),
            active: profile.activeSkinIndex == i,
            preview: [palette[i], palette[i]],
            cost: skinCost,
            onBuy: () => _buy(ref, skinCost, () => player.unlockSkin(i)),
            onSelect: () => player.selectSkin(i),
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
            onBuy: () {
              final product = iap.productById(p.$1);
              if (product != null) iap.buy(product);
            },
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

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({
    required this.label,
    required this.owned,
    required this.active,
    required this.preview,
    required this.cost,
    required this.onBuy,
    required this.onSelect,
  });

  final String label;
  final bool owned;
  final bool active;
  final List<Color> preview;
  final int cost;
  final VoidCallback onBuy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: owned ? onSelect : onBuy,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: preview,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.white : Colors.white24,
            width: active ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: owned
                    ? Icon(active ? Icons.check_circle : Icons.check,
                        color: Colors.white)
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 12, color: Color(0xFFFFD54F)),
                            const SizedBox(width: 2),
                            Text('$cost',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
