import 'dart:math';

class GameDifficultyConfig {
  const GameDifficultyConfig({
    required this.rows,
    required this.cols,
    required this.colors,
    required this.time,
    required this.label,
  });

  final int rows;
  final int cols;
  final int colors;
  final int time;
  final String label;
}

GameDifficultyConfig getDifficultyConfig(int level) {
  if (level <= 20) {
    return const GameDifficultyConfig(
      rows: 2,
      cols: 2,
      colors: 4,
      time: 12,
      label: 'Easy',
    );
  }

  if (level <= 50) {
    return const GameDifficultyConfig(
      rows: 3,
      cols: 3,
      colors: 5,
      time: 15,
      label: 'Normal',
    );
  }

  if (level <= 100) {
    return const GameDifficultyConfig(
      rows: 5,
      cols: 5,
      colors: 5,
      time: 20,
      label: 'Hard',
    );
  }

  return const GameDifficultyConfig(
    rows: 5,
    cols: 5,
    colors: 8,
    time: 32,
    label: 'Extreme',
  );
}

int nextPatternValue(
  Random random,
  int colorCount, {
  bool excludeDefault = false,
}) {
  if (colorCount <= 1) {
    return 0;
  }

  if (excludeDefault) {
    return 1 + random.nextInt(colorCount - 1);
  }

  final weightedPoolSize = 1 + ((colorCount - 1) * 2);
  final roll = random.nextInt(weightedPoolSize);
  if (roll == 0) {
    return 0;
  }

  return 1 + ((roll - 1) ~/ 2);
}

const int _baseReward = 100;
const int _pointsPerLevel = 10;

int calculateLevelReward(int level) {
  return _baseReward + (level * _pointsPerLevel);
}
