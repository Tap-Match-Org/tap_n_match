import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF606060),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ACHIEVEMENTS', style: GoogleFonts.pixelifySans(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _achievementTile("First Match", "Match your first colors", true),
          _achievementTile("Speed Demon", "Finish in under 10 seconds", false),
        ],
      ),
    );
  }

  Widget _achievementTile(String title, String desc, bool unlocked) {
    return Card(
      color: unlocked ? Colors.greenAccent.shade700 : Colors.grey.shade800,
      child: ListTile(
        leading: Icon(Icons.emoji_events, color: unlocked ? Colors.yellow : Colors.grey),
        title: Text(title, style: GoogleFonts.pixelifySans(color: Colors.white)),
        subtitle: Text(desc, style: GoogleFonts.pixelifySans(color: Colors.white70)),
      ),
    );
  }
}