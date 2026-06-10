import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_panel.dart';

/// Celebration shown when a level is solved: confetti burst, animated stars,
/// the coin reward and the "just one more level" Next button.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.stars,
    required this.moves,
    required this.coinsEarned,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final int stars;
  final int moves;
  final int coinsEarned;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2))..play();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppConstants.screenTransition,
  )..forward();

  @override
  void dispose() {
    _confetti.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
          ),
        ),
        ScaleTransition(
          scale: CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
          child: GlassPanel(
            opacity: 0.22,
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Level Complete!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final earned = i < widget.stars;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: earned ? 1 : 0.4),
                      duration: Duration(milliseconds: 300 + i * 150),
                      curve: Curves.elasticOut,
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Icon(
                          Icons.star_rounded,
                          size: 56,
                          color: earned
                              ? const Color(0xFFFFD54F)
                              : Colors.white24,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text('Solved in ${widget.moves} moves',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Color(0xFFFFD54F)),
                    const SizedBox(width: 6),
                    Text('+${widget.coinsEarned}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundAction(
                        icon: Icons.home_rounded, onTap: widget.onHome),
                    const SizedBox(width: 14),
                    _RoundAction(
                        icon: Icons.refresh_rounded, onTap: widget.onReplay),
                    const SizedBox(width: 14),
                    FilledButton.icon(
                      onPressed: widget.onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
