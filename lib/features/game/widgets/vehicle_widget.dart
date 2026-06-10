import 'package:flutter/material.dart';

import '../../../game/models/vehicle.dart';

/// Pure visual for a single vehicle — a glossy rounded car/truck body with a
/// windshield, subtle highlight and an optional lock badge. No gesture logic.
class VehicleWidget extends StatelessWidget {
  const VehicleWidget({
    super.key,
    required this.vehicle,
    required this.color,
    required this.selected,
    required this.hinted,
  });

  final Vehicle vehicle;
  final Color color;
  final bool selected;
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final horizontal = vehicle.isHorizontal;
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: selected ? 1.04 : 1.0,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: vehicle.isTarget
              ? Border.all(color: Colors.white, width: 2.4)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
            if (hinted)
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Windshield band oriented along the body.
            Align(
              alignment: horizontal ? Alignment.centerLeft : Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: horizontal ? 0.32 : 0.66,
                heightFactor: horizontal ? 0.66 : 0.32,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (vehicle.isLocked)
              const Center(
                child: Icon(Icons.lock, color: Colors.white, size: 22),
              ),
            if (vehicle.isTarget)
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
