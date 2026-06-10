import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the game's sound effects. Each effect has its own reusable player so
/// overlapping calls restart cleanly; the police siren loops on a dedicated
/// player. All playback is guarded and honours the user's [enabled] setting, so
/// it never throws into game code and is safe on every platform (incl. web).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool enabled = true;

  final Map<String, AudioPlayer> _players = {};
  AudioPlayer? _siren;

  Future<void> _play(String asset, {double volume = 1.0}) async {
    if (!enabled) return;
    try {
      final player = _players.putIfAbsent(
        asset,
        () => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      );
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (e) {
      if (kDebugMode) debugPrint('Sound error ($asset): $e');
    }
  }

  Future<void> honk() => _play('audio/honk.wav', volume: 0.8);
  Future<void> drive() => _play('audio/drive.wav', volume: 0.7);
  Future<void> win() => _play('audio/win.wav', volume: 0.9);
  Future<void> coin() => _play('audio/coin.wav', volume: 0.8);
  Future<void> tap() => _play('audio/tap.wav', volume: 0.5);

  Future<void> startSiren() async {
    if (!enabled) return;
    try {
      final siren = _siren ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      await siren.play(AssetSource('audio/siren.wav'), volume: 0.6);
    } catch (e) {
      if (kDebugMode) debugPrint('Siren error: $e');
    }
  }

  Future<void> stopSiren() async {
    try {
      await _siren?.stop();
    } catch (_) {}
  }
}
