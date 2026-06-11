import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Shows the PARK FLOW logo image (assets/branding/logo.png) when present, and
/// falls back to a drawn icon + wordmark if the file hasn't been added yet — so
/// the app never breaks if the asset is missing.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 170});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, _, __) => _fallback(),
    );
  }

  Widget _fallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.local_parking_rounded,
              size: 64, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text('PARK FLOW',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0)),
        const SizedBox(height: 2),
        Text(AppConstants.tagline,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
                letterSpacing: 4)),
      ],
    );
  }
}
