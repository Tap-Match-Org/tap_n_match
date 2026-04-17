import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef ClaimCallback = Future<void> Function(String achievementId);

class AchievementList extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final ClaimCallback onClaim;
  final String? claimingId;

  const AchievementList({
    super.key,
    required this.achievements,
    required this.onClaim,
    this.claimingId,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          "No achievements yet.",
          style: GoogleFonts.pixelifySans(fontSize: 14, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemCount: achievements.length,
      itemBuilder: (context, index) => _buildAchievementTile(context, achievements[index]),
    );
  }

  Widget _buildAchievementTile(BuildContext context, Map<String, dynamic> achievement) {
    final String id = achievement['id'] as String? ?? '';
    final String title = achievement['title'] as String? ?? 'Untitled';
    final String description = achievement['description'] as String? ?? '';
    final String rewardName = achievement['reward_name'] as String? ?? '';
    final bool isUnlocked = achievement['is_unlocked'] == true;
    final bool isClaimed = achievement['is_claimed'] == true;
    final bool canClaim = achievement['can_claim'] == true;
    final double progress = (achievement['progress'] as num?)?.toDouble() ?? 0.0;
    final String iconName = achievement['icon'] as String? ?? 'lock';
    final IconData iconData = _iconForName(iconName);

    Widget statusWidget;
    if (canClaim) {
      statusWidget = ElevatedButton(
        onPressed: claimingId == id
            ? null
            : () async {
                await onClaim(id);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(80, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          claimingId == id ? "..." : "Claim",
          style: GoogleFonts.pixelifySans(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else if (isClaimed) {
      statusWidget = Text(
        "Claimed",
        style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w800),
      );
    } else if (isUnlocked) {
      statusWidget = Text(
        "Unlocked",
        style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold),
      );
    } else {
      statusWidget = Text(
        "Locked",
        style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.black38),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Icon(iconData, color: Colors.black87, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.pixelifySans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.pixelifySans(fontSize: 10, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Reward Column
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.lock, size: 10, color: Colors.black45),
                          ),
                        Flexible(
                          child: Text(
                            rewardName.isNotEmpty ? rewardName : "Reward",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.pixelifySans(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black87 : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    statusWidget,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.green.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${(progress * 100).round()}%",
                style: GoogleFonts.pixelifySans(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'grid_view':
        return Icons.grid_view;
      case 'bolt':
        return Icons.bolt;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'whatshot':
        return Icons.whatshot;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'palette':
        return Icons.palette;
      case 'color_lens':
        return Icons.color_lens;
      case 'verified':
        return Icons.verified;
      case 'image':
        return Icons.image;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'music_note':
        return Icons.music_note;
      case 'album':
        return Icons.album;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'stars':
        return Icons.stars;
      case 'trending_up':
        return Icons.trending_up;
      case 'diamond':
        return Icons.diamond;
      case 'ads_click':
        return Icons.ads_click;
      case 'touch_app':
        return Icons.touch_app;
      case 'military_tech':
        return Icons.military_tech;
      case 'gavel':
        return Icons.gavel;
      case 'event_available':
        return Icons.event_available;
      case 'history':
        return Icons.history;
      case 'task_alt':
        return Icons.task_alt;
      case 'speed':
        return Icons.speed;
      case 'verified_user':
        return Icons.verified_user;
      case 'collections':
        return Icons.collections;
      default:
        return Icons.help_outline;
    }
  }
}
