import 'package:flutter/material.dart';

import '../../../widgets/coin_display.dart';
import '../../../widgets/glass_panel.dart';

/// Top-of-screen heads-up display: navigation, level + remaining-cars counter
/// and the always-instant restart button.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.levelNumber,
    required this.carsLeft,
    required this.totalCars,
    required this.onBack,
    required this.onRestart,
    this.isDaily = false,
  });

  final int levelNumber;
  final int carsLeft;
  final int totalCars;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
    final cleared = totalCars - carsLeft;
    final progress = totalCars == 0 ? 0.0 : cleared / totalCars;
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isDaily ? 'Daily' : 'Level $levelNumber',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('$carsLeft cars left',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Restart',
        ),
      ],
    );
  }
}

/// The coin chip, exposed for the game screen header.
class GameCoins extends StatelessWidget {
  const GameCoins({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => CoinDisplay(onTap: onTap);
}
