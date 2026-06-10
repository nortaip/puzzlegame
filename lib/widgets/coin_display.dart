import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_controller.dart';
import 'glass_panel.dart';

/// HUD chip showing the player's current coin balance, kept live via Riverpod.
class CoinDisplay extends ConsumerWidget {
  const CoinDisplay({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(playerControllerProvider).coins;
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 22),
            const SizedBox(width: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: coins, end: coins),
              duration: const Duration(milliseconds: 400),
              builder: (_, value, __) => Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.add_circle, color: Colors.white70, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
