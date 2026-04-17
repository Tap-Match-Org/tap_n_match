import 'package:tap_n_match/domain/game/game_rules.dart';

class GameManager {
  static const int perfectBonusValue = 50;
  static const int timeBonusMultiplier = 2;

  int calculateEarnedScore({
    required int level,
    required int secondsLeft,
    required bool isPerfect,
  }) {
    final baseLevelPoints = calculateLevelReward(level);
    final timeBonus = secondsLeft * timeBonusMultiplier;
    final perfectBonus = isPerfect ? perfectBonusValue : 0;
    
    return baseLevelPoints + timeBonus + perfectBonus;
  }

  bool isMatch(List<int> pattern1, List<int> pattern2) {
    if (pattern1.length != pattern2.length) return false;
    for (int i = 0; i < pattern1.length; i++) {
      if (pattern1[i] != pattern2[i]) return false;
    }
    return true;
  }
}
