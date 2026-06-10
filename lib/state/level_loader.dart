import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/logic/level_generator.dart';
import '../game/models/level.dart';
import 'providers.dart';

/// Generates and caches levels so navigation between them is instant. After a
/// level is requested, the next one is prefetched off the critical path.
class LevelLoader {
  LevelLoader(this._generator);

  final LevelGenerator _generator;
  final Map<int, Level> _cache = {};

  Level load(int number, {int? seed}) {
    final cached = _cache[number];
    if (cached != null && seed == null) return cached;
    final level = _generator.generate(number, seed: seed);
    if (seed == null) _cache[number] = level;
    _prefetch(number + 1);
    return level;
  }

  void _prefetch(int number) {
    if (_cache.containsKey(number)) return;
    // Schedule after the current frame so generation never blocks a transition.
    Future<void>(() {
      _cache[number] ??= _generator.generate(number);
    });
  }

  /// Deterministic daily challenge keyed by date (same seed for all players).
  Level daily(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    // Difficulty roughly mid-game so dailies are interesting but fair.
    return _generator.generate(30, seed: seed);
  }
}

final levelLoaderProvider =
    Provider<LevelLoader>((ref) => LevelLoader(ref.watch(levelGeneratorProvider)));
