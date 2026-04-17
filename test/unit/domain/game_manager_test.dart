import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/domain/game/game_manager.dart';

void main() {
  group('GameManager', () {
    test('calculateEarnedScore includes time bonus and perfect bonus', () {
      final manager = GameManager();
      
      // Level 1: 100 base + 10 level points = 110
      // 5 seconds left * 2 = 10 bonus
      // Perfect bonus = 50
      final score = manager.calculateEarnedScore(
        level: 1,
        secondsLeft: 5,
        isPerfect: true,
      );
      
      expect(score, 110 + 10 + 50);
    });

    test('isMatch returns true when patterns are identical', () {
      final manager = GameManager();
      final p1 = [1, 2, 3];
      final p2 = [1, 2, 3];
      expect(manager.isMatch(p1, p2), isTrue);
    });

    test('isMatch returns false when patterns differ', () {
      final manager = GameManager();
      expect(manager.isMatch([1, 2, 3], [1, 2, 0]), isFalse);
    });
  });
}
