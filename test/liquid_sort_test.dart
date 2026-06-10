import 'package:flow_park_puzzle/liquid/liquid_sort_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = LiquidSortEngine();

  test('generated liquid puzzles are always solvable and non-trivial', () {
    for (final colors in [3, 4, 6, 8]) {
      final tubes = engine.generate(colorCount: colors, seed: colors * 31);
      expect(engine.isSolved(tubes), isFalse,
          reason: '$colors-color puzzle should not start solved');
      expect(engine.isSolvable(tubes), isTrue,
          reason: '$colors-color puzzle must be solvable');
    }
  });

  test('pour respects rules', () {
    final tubes = engine.generate(colorCount: 4, seed: 1);
    // Pouring a tube into itself is illegal.
    expect(engine.canPour(tubes[0], tubes[0]), isFalse);
  });
}
