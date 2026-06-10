import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';
import '../game/game_screen.dart';
import '../level_select/level_select_screen.dart';
import '../shop/shop_screen.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final theme = EnvironmentTheme.byIndex(profile.activeThemeIndex);

    void play(int level, {int? seed}) {
      final lvl = ref.read(levelLoaderProvider).load(level, seed: seed);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameScreen(level: lvl)),
      );
    }

    return Scaffold(
      body: GradientBackground(
        colors: theme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CoinDisplay(),
                    IconButton.filledTonal(
                      onPressed: () => _openShop(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.local_parking_rounded,
                    size: 96, color: Colors.white.withOpacity(0.95)),
                const SizedBox(height: 12),
                const Text('Flow & Park',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Level ${profile.currentLevel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const Spacer(),
                _MenuButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Play  ·  Level ${profile.currentLevel}',
                  primary: true,
                  onTap: () => play(profile.currentLevel),
                ),
                const SizedBox(height: 14),
                _MenuButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Level Select',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Daily Challenge',
                  onTap: () {
                    final daily = ref.read(levelLoaderProvider).daily(DateTime.now());
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => GameScreen(level: daily, isDaily: true)),
                    );
                  },
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: GlassPanel(
          opacity: primary ? 0.30 : 0.16,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: primary ? 20 : 18,
                      fontWeight: primary ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
