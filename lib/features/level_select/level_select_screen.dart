import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/gradient_background.dart';
import '../game/game_screen.dart';

/// A scrollable map of levels. Levels up to the player's current progress are
/// unlocked; each shows the stars earned on it.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  static const int _visibleLevels = 120;

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  /// Maps level number → stars earned (0..3).
  Map<int, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  Future<void> _loadStars() async {
    final progress = await ref.read(localStoreProvider).allProgress();
    if (!mounted) return;
    setState(() {
      _stars = {for (final p in progress) p.levelNumber: p.stars};
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    childAspectRatio: 0.82,
                  ),
                  itemCount: LevelSelectScreen._visibleLevels,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final isUnlocked = number <= unlocked;
                    return _LevelTile(
                      number: number,
                      unlocked: isUnlocked,
                      stars: _stars[number] ?? 0,
                      onTap: isUnlocked ? () => _play(number) : null,
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

  Future<void> _play(int number) async {
    final lvl = ref.read(levelLoaderProvider).load(number);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameScreen(level: lvl)));
    // Refresh stars after returning from a play session.
    await _loadStars();
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    required this.stars,
    this.onTap,
  });

  final int number;
  final bool unlocked;
  final int stars;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked) ...[
              Text('$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _StarRow(stars: stars),
            ] else
              const Icon(Icons.lock, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: earned ? const Color(0xFFFFD54F) : Colors.white30,
        );
      }),
    );
  }
}
