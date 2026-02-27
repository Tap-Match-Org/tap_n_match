import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardsPage extends StatelessWidget {
  const LeaderboardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF606060),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('LEADERBOARDS', style: GoogleFonts.pixelifySans(color: Colors.white)),
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _leaderRow("1st", "PixelMaster", "5000"),
              _leaderRow("2nd", "ColorKing", "4200"),
              _leaderRow("3rd", "TapGod", "3900"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaderRow(String rank, String name, String score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$rank $name", style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 18)),
          Text(score, style: GoogleFonts.pixelifySans(color: Colors.yellow, fontSize: 18)),
        ],
      ),
    );
  }
}