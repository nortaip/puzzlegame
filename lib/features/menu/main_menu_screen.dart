import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../widgets/brand_logo.dart';
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

    void play(int level) {
      final lvl = ref.read(levelLoaderProvider).load(level);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => GameScreen(level: lvl)));
    }

    void open(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Scaffold(
      body: GradientBackground(
        colors: theme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 6),
                // ── Top bar ─────────────────────────────────────────────
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _editName(context, ref, profile.username),
                        child: GlassPanel(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          borderRadius: 18,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                radius: 13,
                                backgroundColor: Color(0x33FFFFFF),
                                child: Icon(Icons.person_rounded,
                                    color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  profile.username.isEmpty
                                      ? 'Player'
                                      : profile.username,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  color: Colors.white54, size: 13),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const CoinDisplay(),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openSettings(context, ref),
                      child: const GlassPanel(
                        padding: EdgeInsets.all(10),
                        borderRadius: 16,
                        child: Icon(Icons.settings_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // ── Brand ────────────────────────────────────────────────
                const BrandLogo(height: 180),

                const Spacer(flex: 3),

                // ── Continue hero card ───────────────────────────────────
                _PlayHero(
                  level: profile.currentLevel,
                  onTap: () => play(profile.currentLevel),
                ),
                const SizedBox(height: 14),

                // ── Nav grid ─────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _NavCard(
                        icon: Icons.grid_view_rounded,
                        label: 'Levels',
                        onTap: () => open(const LevelSelectScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'Daily',
                        onTap: () {
                          final daily = ref
                              .read(levelLoaderProvider)
                              .daily(DateTime.now());
                          open(GameScreen(level: daily, isDaily: true));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NavCard(
                        icon: Icons.leaderboard_rounded,
                        label: 'Ranking',
                        onTap: () => open(const LeaderboardScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavCard(
                        icon: Icons.shopping_bag_rounded,
                        label: 'Shop',
                        onTap: () => open(const ShopScreen()),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Change-name dialog (with uniqueness check) ─────────────────────────────
  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1830),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(color: Colors.white38),
            counterStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final result =
        await ref.read(playerControllerProvider.notifier).trySetUsername(name);
    if (!context.mounted) return;
    final msg = switch (result) {
      UsernameResult.ok => null,
      UsernameResult.taken => 'That name is already taken.',
      UsernameResult.tooShort => 'Name must be at least 2 characters.',
    };
    if (msg != null) {
      Haptics.error();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── Settings sheet ─────────────────────────────────────────────────────────
  void _openSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Consumer(
          builder: (context, r, _) {
            final profile = r.watch(playerControllerProvider);
            final player = r.read(playerControllerProvider.notifier);
            return GlassPanel(
              opacity: 0.2,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('Settings',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  SwitchListTile(
                    value: profile.soundEnabled,
                    onChanged: player.setSound,
                    title: const Text('Sound',
                        style: TextStyle(color: Colors.white)),
                    secondary: const Icon(Icons.volume_up_rounded,
                        color: Colors.white),
                  ),
                  SwitchListTile(
                    value: profile.hapticsEnabled,
                    onChanged: player.setHaptics,
                    title: const Text('Haptics',
                        style: TextStyle(color: Colors.white)),
                    secondary: const Icon(Icons.vibration_rounded,
                        color: Colors.white),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.badge_rounded, color: Colors.white),
                    title: const Text('Change name',
                        style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _editName(context, ref, profile.username);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The big "Continue" card on the menu.
class _PlayHero extends StatelessWidget {
  const _PlayHero({required this.level, required this.onTap});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        opacity: 0.30,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONTINUE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Level $level',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const Spacer(),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF1B1830), size: 34),
            ),
          ],
        ),
      ),
    );
  }
}

/// A square-ish navigation card on the menu grid.
class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
