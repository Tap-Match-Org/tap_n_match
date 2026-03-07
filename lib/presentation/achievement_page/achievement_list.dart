import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementList extends StatelessWidget {
  const AchievementList({super.key});

  @override
  Widget build(BuildContext context) {
    // This list is structured to handle the "Reward system" mentioned in your proposal.
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildAchievementTile(
          title: "First Match",
          description: "Successfully match your first color pattern.",
          progress: 1.0, 
          isUnlocked: true,
          rewardType: "Trophy",
        ),
        _buildAchievementTile(
          title: "Speedster I",
          description: "Finish 5 levels in under 10 seconds.",
          progress: 0.4, // e.g., 2/5 levels done
          isUnlocked: false,
          rewardType: "Audio",
        ),
        _buildAchievementTile(
          title: "Amethyst Collector",
          description: "Unlock the Amethyst background theme.",
          progress: 0.0,
          isUnlocked: false,
          rewardType: "Theme",
        ),
        _buildAchievementTile(
          title: "Color Master",
          description: "Complete all Easy Mode levels.",
          progress: 0.7,
          isUnlocked: false,
          rewardType: "Badge",
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFF98EE99) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked ? Colors.orange : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 15),
          // Content
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
                  style: GoogleFonts.pixelifySans(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAEC6FF),
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
              Text("REWARD", style: GoogleFonts.pixelifySans(fontSize: 8, color: Colors.grey)),
              Text(
                rewardType,
                style: GoogleFonts.pixelifySans(
                  fontSize: 10,
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