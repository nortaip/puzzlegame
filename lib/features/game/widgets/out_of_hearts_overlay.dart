import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/ads/ads_service.dart';
import '../../../state/game_controller.dart';
import '../../../state/player_controller.dart';
import '../../../state/providers.dart';
import '../../../widgets/glass_panel.dart';
import 'hearts_display.dart';

/// Shown when the player runs out of hearts: offers a rewarded ad (+1 heart) or
/// a wait timer, and resumes the level automatically once a heart is available.
class OutOfHeartsOverlay extends ConsumerStatefulWidget {
  const OutOfHeartsOverlay({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  ConsumerState<OutOfHeartsOverlay> createState() =>
      _OutOfHeartsOverlayState();
}

class _OutOfHeartsOverlayState extends ConsumerState<OutOfHeartsOverlay> {
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final player = ref.read(playerControllerProvider.notifier);
    await player.refreshHearts();
    if (!mounted) return;
    if (player.hearts > 0) {
      _resume();
    } else {
      setState(() {}); // update countdown
    }
  }

  void _resume() {
    _timer?.cancel();
    ref.read(gameControllerProvider.notifier).resumeFromLost();
  }

  Future<void> _watchAd() async {
    if (_busy) return;
    setState(() => _busy = true);
    final earned =
        await ref.read(adsServiceProvider).showRewarded(AdPlacement.hearts);
    if (!mounted) return;
    if (earned) {
      await ref.read(playerControllerProvider.notifier).addHeart();
      ref.read(analyticsServiceProvider).rewardedAdWatched('hearts');
      _resume();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Ad not available')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        ref.watch(playerControllerProvider.notifier).heartRefillRemaining;

    return Stack(
      alignment: Alignment.center,
      children: [
        const ModalBarrier(color: Colors.black87, dismissible: false),
        GlassPanel(
          opacity: 0.22,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  AppConstants.maxHearts,
                  (_) => const Icon(Icons.favorite_border,
                      color: Color(0x55FF5267), size: 40),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Out of hearts!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                remaining == null
                    ? 'Refilling…'
                    : 'Full hearts in ${formatHeartTimer(remaining)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _watchAd,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.favorite),
                  label: const Text('Watch ad  +1 heart'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: widget.onHome,
                child: const Text('Quit to menu',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
