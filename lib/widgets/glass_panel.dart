import 'dart:ui';

import 'package:flutter/material.dart';

/// A refined "liquid glass" container (à la Apple): a strong backdrop blur, a
/// translucent tinted fill, a glossy top sheen, a crisp light rim and a soft
/// drop shadow for depth. Used for HUD chips, dialogs, sheets and panels.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 26,
    this.blur = 24,
    this.opacity = 0.16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  /// Base tint strength of the glass.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          // Faint top rim light.
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity + 0.16),
                  Colors.white.withOpacity(opacity + 0.02),
                  Colors.white.withOpacity(opacity * 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.2,
              ),
            ),
            // Glossy specular sheen drawn over the content's top edge.
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
