import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../state/player_controller.dart';
import '../../../widgets/glass_panel.dart';

/// HUD chip showing the player's remaining mistake hearts.
class HeartsDisplay extends ConsumerWidget {
  const HeartsDisplay({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearts = ref.watch(playerControllerProvider).hearts;
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < AppConstants.maxHearts; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Icon(
                  i < hearts ? Icons.favorite : Icons.favorite_border,
                  color: i < hearts ? const Color(0xFFFF5267) : Colors.white38,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formats a refill countdown like "1:23:45" or "12:05".
String formatHeartTimer(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
