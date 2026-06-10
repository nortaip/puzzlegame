import 'package:flutter/material.dart';

import '../../../widgets/coin_display.dart';
import '../../../widgets/glass_panel.dart';

/// Top-of-screen heads-up display: navigation, level + move counter and the
/// always-instant restart button.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.levelNumber,
    required this.moves,
    required this.optimalMoves,
    required this.onBack,
    required this.onRestart,
    this.isDaily = false,
  });

  final int levelNumber;
  final int moves;
  final int optimalMoves;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isDaily ? 'Daily' : 'Level $levelNumber',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('Best: $optimalMoves moves',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$moves',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22)),
                    const Text('moves',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
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
