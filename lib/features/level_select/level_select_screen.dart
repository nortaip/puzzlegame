import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../widgets/gradient_background.dart';
import '../game/game_screen.dart';

/// A scrollable map of levels. Levels up to the player's current progress are
/// unlocked; the rest are locked until reached.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  static const int _visibleLevels = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerControllerProvider);
    final theme = EnvironmentTheme.byIndex(profile.activeThemeIndex);
    final unlocked = profile.currentLevel;

    return Scaffold(
      body: GradientBackground(
        colors: theme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text('Levels',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: _visibleLevels,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final isUnlocked = number <= unlocked;
                    return _LevelTile(
                      number: number,
                      unlocked: isUnlocked,
                      onTap: isUnlocked
                          ? () {
                              final lvl =
                                  ref.read(levelLoaderProvider).load(number);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => GameScreen(level: lvl)));
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    this.onTap,
  });

  final int number;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(unlocked ? 0.22 : 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: unlocked
              ? Text('$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700))
              : const Icon(Icons.lock, color: Colors.white38, size: 20),
        ),
      ),
    );
  }
}
