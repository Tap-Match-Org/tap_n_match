import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementList extends StatelessWidget {
  const AchievementList({super.key});

  @override
  Widget build(BuildContext context) {
    // This list will eventually be populated by your Domain Layer / Firebase
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      children: [
        _buildAchievementTile(
          title: "First Match",
          description: "Match your first color pattern successfully.",
          progress: 1.0, // 100% complete
          isUnlocked: true,
          rewardType: "Trophy",
        ),
        _buildAchievementTile(
          title: "Speedster I",
          description: "Complete 5 levels in under 10 seconds each.",
          progress: 0.6, // 3/5 complete
          isUnlocked: false,
          rewardType: "Audio",
        ),
        _buildAchievementTile(
          title: "Color Collector",
          description: "Unlock the 'Amethyst' background theme.",
          progress: 0.0,
          isUnlocked: false,
          rewardType: "Theme",
        ),
        _buildAchievementTile(
          title: "Daily Grinder",
          description: "Complete 7 Daily Challenges in a row.",
          progress: 0.2, // 1/7 complete
          isUnlocked: false,
          rewardType: "Reward",
        ),
      ],
    );
  }

  Widget _buildAchievementTile({
    required String title,
    required String description,
    required double progress,
    required bool isUnlocked,
    required String rewardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFFAEC6FF) : Colors.grey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(width: 15),
          // Text and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress Bar
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
                      widthFactor: progress,
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
          // Reward Label
          Column(
            children: [
              Text(
                "Type",
                style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.grey),
              ),
              Text(
                rewardType,
                style: GoogleFonts.pixelifySans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFCA016),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}