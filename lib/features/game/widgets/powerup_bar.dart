import 'package:flutter/material.dart';

import '../../../widgets/glass_panel.dart';

class PowerUp {
  const PowerUp({
    required this.icon,
    required this.label,
    required this.charges,
    required this.cost,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int charges;
  final int cost;
  final VoidCallback onTap;
}

/// Bottom action bar exposing the three power-ups (Police, Shuffle, Hint). Each
/// button shows its remaining free charges, or its coin cost when none remain.
class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key, required this.powerUps});

  final List<PowerUp> powerUps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final p in powerUps) _PowerUpButton(power: p),
      ],
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  const _PowerUpButton({required this.power});
  final PowerUp power;

  @override
  Widget build(BuildContext context) {
    final hasCharge = power.charges > 0;
    return GestureDetector(
      onTap: power.onTap,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(power.icon, color: Colors.white, size: 30),
                if (hasCharge)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${power.charges}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(power.label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 2),
            if (hasCharge)
              const Text('Free',
                  style: TextStyle(color: Colors.white70, fontSize: 10))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFD54F), size: 12),
                  const SizedBox(width: 2),
                  Text('${power.cost}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
