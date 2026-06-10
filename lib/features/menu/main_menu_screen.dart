import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../widgets/coin_display.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_background.dart';
import '../game/game_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
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
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _editName(context, ref, profile.username),
                  child: GlassPanel(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          profile.username.isEmpty ? 'Player' : profile.username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
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
                const SizedBox(height: 14),
                _MenuButton(
                  icon: Icons.leaderboard_rounded,
                  label: 'Leaderboard',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  ),
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

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1830),
        title: const Text('Change name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().length >= 2) {
      await ref.read(playerControllerProvider.notifier).setUsername(name);
    }
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
