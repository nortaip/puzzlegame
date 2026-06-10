import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/themes/environment_theme.dart';
import '../../state/level_loader.dart';
import '../../state/player_controller.dart';
import '../../state/providers.dart';
import '../../widgets/gradient_background.dart';
import '../game/game_screen.dart';

/// A long winding road where each level is a billboard along the way. Locked
/// levels are dimmed; the view auto-scrolls to the player's current level.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  static const int _visibleLevels = 120;
  static const double _rowHeight = 138;
  static const double _topPad = 90;
  static const double _bottomPad = 90;

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  final ScrollController _scroll = ScrollController();
  Map<int, int> _stars = {};
  bool _jumped = false;

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadStars() async {
    final progress = await ref.read(localStoreProvider).allProgress();
    if (!mounted) return;
    setState(() {
      _stars = {for (final p in progress) p.levelNumber: p.stars};
    });
  }

  double _totalHeight() =>
      LevelSelectScreen._topPad +
      LevelSelectScreen._bottomPad +
      LevelSelectScreen._visibleLevels * LevelSelectScreen._rowHeight;

  double _yCenter(int index) =>
      _totalHeight() -
      LevelSelectScreen._bottomPad -
      (index + 0.5) * LevelSelectScreen._rowHeight;

  double _roadX(double width, double y) =>
      width / 2 + width * 0.13 * sin(y / 200);

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final total = _totalHeight();

                    // Auto-scroll to the current level once.
                    if (!_jumped) {
                      _jumped = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_scroll.hasClients) return;
                        final idx = (unlocked - 1)
                            .clamp(0, LevelSelectScreen._visibleLevels - 1);
                        final y = _yCenter(idx);
                        final target = (y - constraints.maxHeight / 2)
                            .clamp(0.0, _scroll.position.maxScrollExtent);
                        _scroll.jumpTo(target);
                      });
                    }

                    return SingleChildScrollView(
                      controller: _scroll,
                      child: SizedBox(
                        width: width,
                        height: total,
                        child: Stack(
                          children: [
                            // The road.
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _RoadPainter(theme: theme),
                              ),
                            ),
                            // Billboards.
                            for (var i = 0;
                                i < LevelSelectScreen._visibleLevels;
                                i++)
                              ..._billboard(width, i, unlocked, theme),
                          ],
                        ),
                      ),
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

  List<Widget> _billboard(
    double width,
    int index,
    int unlocked,
    EnvironmentTheme theme,
  ) {
    final number = index + 1;
    final isUnlocked = number <= unlocked;
    final isCurrent = number == unlocked;
    final y = _yCenter(index);
    final rx = _roadX(width, y);
    final leftSide = index.isEven;
    const bw = 128.0;
    const bh = 88.0;
    final bx = (leftSide ? rx - bw - 18 : rx + 18).clamp(6.0, width - bw - 6);

    return [
      // Road marker dot connecting the billboard to the road.
      Positioned(
        left: rx - 7,
        top: y - 7,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isUnlocked ? Colors.white : Colors.white38,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 2),
          ),
        ),
      ),
      Positioned(
        left: bx,
        top: y - bh / 2,
        width: bw,
        height: bh,
        child: _Billboard(
          number: number,
          unlocked: isUnlocked,
          current: isCurrent,
          stars: _stars[number] ?? 0,
          theme: theme,
          onTap: isUnlocked ? () => _play(number) : null,
        ),
      ),
    ];
  }

  Future<void> _play(int number) async {
    final lvl = ref.read(levelLoaderProvider).load(number);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameScreen(level: lvl)));
    await _loadStars();
  }
}

/// A signboard on a post showing a level number, stars and lock state.
class _Billboard extends StatelessWidget {
  const _Billboard({
    required this.number,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.theme,
    this.onTap,
  });

  final int number;
  final bool unlocked;
  final bool current;
  final int stars;
  final EnvironmentTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = unlocked ? theme.vehicleColor(number) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, 0.25)!,
              base,
              Color.lerp(base, Colors.black, 0.20)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: current ? Colors.white : Colors.white24,
            width: current ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (unlocked) ...[
                  const Text('LEVEL',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  Text('$number',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.0)),
                  const SizedBox(height: 2),
                  _Stars(stars: stars),
                ] else
                  const Icon(Icons.lock, color: Colors.white, size: 26),
              ],
            ),
            if (current)
              Positioned(
                top: -10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('NOW',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});
  final int stars;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: earned ? const Color(0xFFFFD54F) : Colors.white38,
        );
      }),
    );
  }
}

/// Paints the winding road that the billboards line up along.
class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.theme});
  final EnvironmentTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final roadWidth = size.width * 0.24;
    final pts = <Offset>[];
    for (double y = 0; y <= size.height; y += 6) {
      pts.add(Offset(size.width / 2 + size.width * 0.13 * sin(y / 200), y));
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    // Shoulder + asphalt.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2A2E37)
        ..strokeWidth = roadWidth + 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3C424E)
        ..strokeWidth = roadWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dashed centre line.
    final dash = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 4 < pts.length; i += 11) {
      canvas.drawLine(pts[i], pts[i + 4], dash);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => old.theme != theme;
}
