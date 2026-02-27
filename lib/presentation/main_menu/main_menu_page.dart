import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  // --- 3x3 GRID LOGO ---
  Widget _buildLogoGrid() {
    final List<Color> gridColors = [
      Colors.red, Colors.blue, Colors.greenAccent,
      Colors.yellow, Colors.white, Colors.yellow,
      Colors.greenAccent, Colors.red, Colors.blue,
    ];

    return SizedBox(
      width: 160, 
      height: 160,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: gridColors[index],
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  // --- STYLIZED MENU BUTTONS ---
  Widget _buildMenuButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.pixelifySans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIDEBAR ICON HELPER ---
  Widget _buildSidebarIcon(BuildContext context, IconData icon, String routeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(routeName), // Using direct string
        child: Icon(icon, color: Colors.black, size: 40),
      ),
    );
  }

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
            // 1. SIDEBAR ICONS
            Positioned(
              left: 20,
              top: 20,
              child: Column(
                children: [
                  _buildSidebarIcon(context, Icons.account_circle, '/profile'),
                  _buildSidebarIcon(context, Icons.emoji_events, '/achievements'),
                  _buildSidebarIcon(context, Icons.leaderboard, '/leaderboards'),
                  _buildSidebarIcon(context, Icons.palette, '/theme'),
                ],
              ),
            ),

            // 2. DAILY CHALLENGE PANEL
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 170,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF98EE99),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC6D8FF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                        ),
                        child: Text(
                          'Daily Challenge',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Reward:', style: GoogleFonts.pixelifySans()),
                      const SizedBox(height: 10),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. MAIN CENTER CONTENT
            Align(
              alignment: const Alignment(0, -0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogoGrid(),
                  const SizedBox(height: 15),
                  Stack(
                    children: [
                      Text(
                        'Tap & Match',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 6
                            ..color = Colors.black,
                        ),
                      ),
                      Text(
                        'Tap & Match',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFCA016),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Text(
                        'The Color Game',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = Colors.black,
                        ),
                      ),
                      Text(
                        'The Color Game',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 22,
                          color: const Color(0xFF20DEFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildMenuButton(
                    text: 'Play',
                    icon: Icons.play_arrow,
                    color: const Color(0xFFAEC6FF),
                    onTap: () => Navigator.of(context).pushNamed('/game'),
                  ),
                  _buildMenuButton(
                    text: 'Exit',
                    icon: Icons.close,
                    color: const Color(0xFFFF7E7E),
                    onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}