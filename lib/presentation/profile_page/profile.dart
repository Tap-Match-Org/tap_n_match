import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Helper to build the dynamic stat boxes with strokes

  Widget _buildStatBox(String value, String label) {
    final displayValue = value.isEmpty ? "-" : value;

    return Container(
      width: 140,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stack used to create the stroke effect on the number
          Stack(
            children: [
              // The Black Stroke (Background)
              Text(
                displayValue,
                style: GoogleFonts.pixelifySans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.black,
                ),
              ),
              // The Gold/Orange Fill (Foreground)
              Text(
                displayValue,
                style: GoogleFonts.pixelifySans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFCA016),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.pixelifySans(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = screenWidth > screenHeight;

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
            // 1. BACK BUTTON
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
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 26),
                ),
              ),
            ),

            // 2. LOGOUT - Wrapped to ensure it stays on top and visible
            Positioned(
              right: 20,
              top: 25,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Subtle background to prevent text overlap confusion
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout, color: Colors.black, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        'Logout',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. MAIN PANEL - Adjusted width for landscape to prevent Logout overlap
            Center(
              child: Container(
                width: isLandscape ? screenWidth * 0.75 : screenWidth * 0.85, 
                height: isLandscape ? screenHeight * 0.8 : 500,
                decoration: BoxDecoration(
                  color: const Color(0xFFE59A5A), 
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC08E66), 
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                      ),
                      child: Text(
                        'Statistics',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatBox('0', 'Highest Score'),
                              _buildStatBox('0', 'Games Played'),
                              _buildStatBox('0', 'Boxes Tapped'),
                              _buildStatBox('0', 'Achievements'),
                              _buildStatBox('0', 'Highest Level'),
                              _buildStatBox('0', 'Leaderboards'),
                            ],
                          ),
                        ),
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
}