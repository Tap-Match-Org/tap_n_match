class Challenge {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int currentProgress;
  final bool isComplete;
  final int rewardPoints;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.currentProgress,
    required this.isComplete,
    required this.rewardPoints,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Weekly Challenge',
      description: json['description'] as String? ?? '',
      targetCount: (json['target_count'] as num?)?.toInt() ?? 0,
      currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
      isComplete: json['is_complete'] as bool? ?? false,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
    );
  }

  Challenge copyWith({
    int? currentProgress,
    bool? isComplete,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      targetCount: targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      isComplete: isComplete ?? this.isComplete,
      rewardPoints: rewardPoints,
    );
  }

  double get progress => targetCount > 0 ? currentProgress / targetCount : 0.0;
}
