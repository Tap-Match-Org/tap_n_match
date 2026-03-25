import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementList extends StatelessWidget {
  const AchievementList({super.key});

  static final List<_AchievementData> _achievements = [
    const _AchievementData(
      title: 'First Match',
      description: 'Clear your first color pattern.',
      progress: 1.0,
      isUnlocked: true,
      rewardType: 'Trophy',
      icon: Icons.emoji_events,
    ),
    const _AchievementData(
      title: 'Getting Warmed Up',
      description: 'Clear 5 regular levels.',
      progress: 0.4,
      isUnlocked: false,
      rewardType: 'Badge',
      icon: Icons.local_fire_department,
    ),
    const _AchievementData(
      title: 'Pattern Pro',
      description: 'Clear 25 regular levels.',
      progress: 0.08,
      isUnlocked: false,
      rewardType: 'Badge',
      icon: Icons.grid_view,
    ),
    const _AchievementData(
      title: 'Quick Fingers',
      description: 'Beat a level with at least 5 seconds left.',
      progress: 0.0,
      isUnlocked: false,
      rewardType: 'Title',
      icon: Icons.bolt,
    ),
    const _AchievementData(
      title: 'Daily Starter',
      description: 'Complete your first daily challenge.',
      progress: 0.0,
      isUnlocked: false,
      rewardType: 'Theme',
      icon: Icons.calendar_today,
    ),
    const _AchievementData(
      title: '3-Day Streak',
      description: 'Complete daily challenges on 3 straight days.',
      progress: 0.33,
      isUnlocked: false,
      rewardType: 'Theme',
      icon: Icons.whatshot,
    ),
    const _AchievementData(
      title: '7-Day Streak',
      description: 'Reach a 7-day daily challenge streak.',
      progress: 0.14,
      isUnlocked: false,
      rewardType: 'Theme',
      icon: Icons.workspace_premium,
    ),
    const _AchievementData(
      title: 'Theme Hunter',
      description: 'Unlock 3 color themes.',
      progress: 0.33,
      isUnlocked: false,
      rewardType: 'Collection',
      icon: Icons.palette,
    ),
    const _AchievementData(
      title: 'Palette Collector',
      description: 'Unlock 7 color themes.',
      progress: 0.14,
      isUnlocked: false,
      rewardType: 'Collection',
      icon: Icons.color_lens,
    ),
    const _AchievementData(
      title: 'Comeback',
      description: 'Lose a level, retry, then win.',
      progress: 0.0,
      isUnlocked: false,
      rewardType: 'Trophy',
      icon: Icons.replay,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemCount: _achievements.length,
      itemBuilder: (context, index) => _buildAchievementTile(_achievements[index]),
    );
  }

  Widget _buildAchievementTile(_AchievementData achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? Colors.white : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked ? const Color(0xFFAEC6FF) : Colors.grey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(
              achievement.isUnlocked ? achievement.icon : Icons.lock,
              color: achievement.isUnlocked ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: achievement.progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF98EE99),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Text(
                  'Type',
                  style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  achievement.rewardType,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFCA016),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementData {
  final String title;
  final String description;
  final double progress;
  final bool isUnlocked;
  final String rewardType;
  final IconData icon;

  const _AchievementData({
    required this.title,
    required this.description,
    required this.progress,
    required this.isUnlocked,
    required this.rewardType,
    required this.icon,
  });
}
