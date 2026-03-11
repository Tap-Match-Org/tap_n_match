import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/core/routes.dart'; // Ensure this import matches your project structure

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  // --- RESPONSIVE GRID LOGO ---
  Widget _buildLogoGrid(double screenHeight) {
    final double gridSize = screenHeight * 0.35;
    final List<Color> gridColors = [
      Colors.red, Colors.blue, Colors.greenAccent,
      Colors.yellow, Colors.white, Colors.yellow,
      Colors.greenAccent, Colors.red, Colors.blue,
    ];

    return SizedBox(
      width: gridSize.clamp(100.0, 160.0),
      height: gridSize.clamp(100.0, 160.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: gridColors[index],
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  // --- STYLIZED MENU BUTTON ---
  Widget _buildMenuButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isLandscape,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: EdgeInsets.symmetric(vertical: isLandscape ? 4 : 8),
        padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.pixelifySans(
                fontSize: 20,
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
  Widget _buildSidebarIcon(BuildContext context, IconData icon, String route, bool isLandscape) {
    final double size = isLandscape ? 35 : 44;
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Stack(
        children: [
          Icon(
            icon,
            size: size + 2,
            color: Colors.black,
          ),
          Positioned(
            left: 1,
            top: 1,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(255, 239, 140, 47), Color(0xFFB0B0B0)],
                ).createShader(bounds);
              },
              child: Icon(
                icon,
                color: Colors.white,
                size: size,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: DIALOG BUTTON HELPER ---
  Widget _buildDialogButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          text,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  // --- NEW: SHOW CHALLENGE CONFIRMATION ---
  void _showChallengeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFB2B9D1), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You only get 1 chance",
                  style: GoogleFonts.pixelifySans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Continue to Challenge?",
                  style: GoogleFonts.pixelifySans(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialogButton("Yes", () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushNamed(context, AppRoutes.dailyChallenge);
                    }),
                    _buildDialogButton("No", () {
                      Navigator.pop(context); // Close dialog
                    }),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
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
            // 1. SIDEBAR ICONS
            Positioned(
              left: 20,
              top: 25,
              child: Column(
                children: [
                  _buildSidebarIcon(context, Icons.account_circle, AppRoutes.profile, isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.emoji_events, AppRoutes.achievements, isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.leaderboard, AppRoutes.leaderboards, isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.palette, AppRoutes.theme, isLandscape),
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
                  width: isLandscape ? 140 : 170,
                  height: isLandscape ? 200 : 250, 
                  decoration: BoxDecoration(
                    color: const Color(0xFF98EE99),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text('Reward:', style: GoogleFonts.pixelifySans(fontSize: 12)),
                      const SizedBox(height: 5),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.palette, color: Colors.cyanAccent, size: 24),
                      ),
                      const SizedBox(height: 12),
                      
                      // --- UPDATED PLAY NOW BUTTON ---
                      GestureDetector(
                        onTap: () => _showChallengeConfirmation(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            'Play Now',
                            style: GoogleFonts.pixelifySans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),

            // 3. MAIN CENTER CONTENT
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogoGrid(screenHeight),
                    SizedBox(height: isLandscape ? 8 : 15),
                    _buildTitleText('Tap & Match', isLandscape ? 40 : 55, const Color(0xFFFCA016)),
                    _buildTitleText('The Color Game', isLandscape ? 16 : 22, const Color(0xFF20DEFF)),
                    SizedBox(height: isLandscape ? 8 : 25),
                    _buildMenuButton(
                      text: 'Play',
                      icon: Icons.play_arrow,
                      color: const Color(0xFFAEC6FF),
                      isLandscape: isLandscape,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.game),
                    ),
                    _buildMenuButton(
                      text: 'Exit',
                      icon: Icons.close,
                      color: const Color(0xFFFF7E7E),
                      isLandscape: isLandscape,
                      onTap: () {
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else if (Platform.isIOS) {
                          exit(0);
                        }
                      },
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

  Widget _buildTitleText(String text, double size, Color color) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: size,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}