import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardsPage extends StatelessWidget {
  const LeaderboardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFFB0B0B0), Color(0xFF606060)],
          ),
        ),
        child: Stack(
          children: [
            // BACK BUTTON
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                ),
              ),
            ),

            // MAIN LEADERBOARD PANEL
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: isLandscape ? MediaQuery.of(context).size.height * 0.8 : 550,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  children: [
                    // BLUE HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAEC6FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                      ),
                      child: Text(
                        'Leaderboards',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFCA016), // Orange outline color from screenshot
                          shadows: [
                            const Shadow(offset: Offset(2, 2), color: Colors.black),
                          ],
                        ),
                      ),
                    ),

                    // TABLE HEADERS
                    Container(
                      color: const Color(0xFFAEC6FF).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderText("RANKING"),
                          _buildHeaderText("PLAYER NAME"),
                          _buildHeaderText("SCORE"),
                          _buildHeaderText("HIGHEST LEVEL"),
                          _buildHeaderText("ACHIEVEMENTS"),
                        ],
                      ),
                    ),

                    // SCROLLABLE LIST OF PLAYERS
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(10),
                        children: [
                          _buildLeaderRow("1", "67taps", "9999", "1000", "100"),
                          _buildLeaderRow("2", "Marlowww", "8000", "800", "67"),
                          _buildLeaderRow("3", "Swight", "6000", "600", "50"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.pixelifySans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLeaderRow(String rank, String name, String score, String level, String ach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFAEC6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCellText(rank),
          _buildCellText(name),
          _buildCellText(score),
          _buildCellText(level),
          _buildCellText(ach),
        ],
      ),
    );
  }

  Widget _buildCellText(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.pixelifySans(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}