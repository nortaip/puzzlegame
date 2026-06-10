import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Thin wrapper over platform haptics with a graceful fallback. Honors a
/// user-controllable [enabled] flag set from settings. Safe on web and any
/// platform without a vibrator (calls are guarded and never throw).
class Haptics {
  Haptics._();

  static bool enabled = true;
  static bool? _hasVibrator;

  static Future<void> _ensure() async {
    if (_hasVibrator != null) return;
    if (kIsWeb) {
      _hasVibrator = false;
      return;
    }
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
    } catch (_) {
      _hasVibrator = false;
    }
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
