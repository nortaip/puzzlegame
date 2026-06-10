import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Thin wrapper over platform haptics with a graceful fallback. Honors a
/// user-controllable [enabled] flag set from settings.
class Haptics {
  Haptics._();

  static bool enabled = true;
  static bool? _hasVibrator;

  static Future<void> _ensure() async {
    _hasVibrator ??= await Vibration.hasVibrator() ?? false;
  }

  static Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    if (!enabled) return;
    await _ensure();
    if (_hasVibrator == true) {
      await Vibration.vibrate(pattern: const [0, 30, 60, 50]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> error() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }
}
