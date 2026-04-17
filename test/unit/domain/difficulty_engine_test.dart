import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/domain/game/game_rules.dart';

void main() {
  group('Game difficulty rules', () {
    test('difficulty tiers map levels to the expected board and timer values', () {
      expect(getDifficultyConfig(1).label, 'Easy');
      expect(getDifficultyConfig(20).rows, 2);

      final normal = getDifficultyConfig(21);
      expect(normal.label, 'Normal');
      expect(normal.cols, 3);
      expect(normal.colors, 5);

      final hard = getDifficultyConfig(51);
      expect(hard.label, 'Hard');
      expect(hard.rows, 5);
      expect(hard.time, 20);

      final extreme = getDifficultyConfig(101);
      expect(extreme.label, 'Extreme');
      expect(extreme.colors, 8);
      expect(extreme.time, 32);
    });

    test('target patterns never include white when excludeDefault is true', () {
      final random = Random(42);
      const colorCounts = [2, 3, 5, 8];

      for (final count in colorCounts) {
        for (var i = 0; i < 100; i++) {
          final value = nextPatternValue(
            random,
            count,
            excludeDefault: true,
          );
          expect(value, isNot(0));
          expect(value, greaterThanOrEqualTo(1));
          expect(value, lessThan(count));
        }
      }
    });

    test('color counts of 1 or less always return 0', () {
      final random = Random(7);

      expect(nextPatternValue(random, 1, excludeDefault: true), 0);
      expect(nextPatternValue(random, 0, excludeDefault: true), 0);
    });

    test('calculateLevelReward returns 110 points for level 1 (base 100 + level*10)', () {
      expect(calculateLevelReward(1), 110);
    });

    test('calculateLevelReward returns 200 points for level 10 (base 100 + level*10)', () {
      expect(calculateLevelReward(10), 200);
    });
  });
}
