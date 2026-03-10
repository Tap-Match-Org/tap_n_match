import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
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

            // MAIN THEME PANEL
            Align(
              alignment: Alignment.topCenter, // Changed to topCenter to help move it up
              child: Padding(
                // top: 60 moves it below back button, bottom: 40 keeps it away from the edge
                padding: const EdgeInsets.only(top: 65, bottom: 45), 
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    children: [
                      // HEADER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE59A5A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(17),
                            topRight: Radius.circular(17),
                          ),
                          border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                        ),
                        child: Text(
                          'THEMES',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE08CF4),
                            shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)],
                          ),
                        ),
                      ),

                      // 3-COLUMN CONTENT
                      Expanded(
                        child: Row(
                          children: [
                            // Column 1: Background (Light Blue)
                            _buildThemeColumn("Background", const Color(0xFFAEC6FF), [
                              _themeItem(const Color(0xFFA9A9A9), "Default", true),
                              _themeItem(const Color(0xFF2E1A47), "Amethyst", false),
                              _themeItem(const Color(0xFF1A3A5F), "Ocean", false),
                            ]),
                            const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                            // Column 2: Tap Sound (Yellow)
                            _buildThemeColumn("Tap Sound", const Color(0xFFFFF9B0), [
                              _themeItem(const Color(0xFFFFF9B0), "Classic", true),
                              _themeItem(const Color(0xFF7A7640), "Solfège", false),
                              _themeItem(const Color(0xFF7A7640), "Drums", false),
                            ]),
                            const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                            // Column 3: Music (Light Green)
                            _buildThemeColumn("Music", const Color(0xFFB4FF91), [
                              _themeItem(const Color(0xFFB4FF91), "Sweden", true),
                              _themeItem(const Color(0xFF4A6B3A), "Unity", false),
                              _themeItem(const Color(0xFF4A6B3A), "Fainted", false),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeColumn(String title, Color headerColor, List<Widget> items) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.3), // Subtle tint for the column header area
              border: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeItem(Color color, String name, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 45,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            name,
            style: GoogleFonts.pixelifySans(
              fontSize: 14,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isUnlocked)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 16)),
            ),
        ],
      ),
    );
  }
}