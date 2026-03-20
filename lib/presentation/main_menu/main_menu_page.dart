import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class MainMenuPage extends StatefulWidget {
  MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int userId = 1; // Default fallback
  bool isNewbie = true;
  int userStreak = 1;
  String selectedTheme = "#A9A9A9";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userStreak = data['streak'] ?? 1;
          isNewbie = userStreak <= 7;
          selectedTheme = data['selected_theme'] ?? "#A9A9A9";
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Configuration for the 7 newbie days rewards
  final List<Map<String, dynamic>> newbieDaysConfig = [
    {"color": "#98EE99", "name": "Mint"},
    {"color": "#2E1A47", "name": "Amethyst"},
    {"color": "#1A3A5F", "name": "Ocean"},
    {"color": "#FFA500", "name": "Orange"},
    {"color": "#FFC0CB", "name": "Pink"},
    {"color": "#00FF00", "name": "Lime"},
    {"color": "#00FFFF", "name": "Cyan"},
  ];

  // Get current reward based on user streak
  Map<String, dynamic> _getCurrentReward() {
    int index = (userStreak == 0 ? 0 : (userStreak - 1)).clamp(0, 6);
    return newbieDaysConfig[index];
  }

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

  // --- STYLIZED MENU BUTTON (Play / Exit) ---
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
      onTap: () => Navigator.of(context).pushNamed(
        route,
        arguments: {'user_id': userId},
      ),
      child: Stack(
        children: [
          Icon(icon, size: size + 2, color: Colors.black),
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
              child: Icon(icon, color: Colors.white, size: size),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = screenWidth > screenHeight;

    Color themeColor = Color(int.parse(selectedTheme.replaceFirst('#', '0xFF')));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              themeColor.withOpacity(0.8),
              themeColor.withOpacity(0.4),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. SIDEBAR ICONS (Top Left)
            Positioned(
              left: 20,
              top: 25,
              child: Column(
                children: [
                  _buildSidebarIcon(context, Icons.account_circle, '/profile', isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.emoji_events, '/achievements', isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.leaderboard, '/leaderboards', isLandscape),
                  const SizedBox(height: 15),
                  _buildSidebarIcon(context, Icons.palette, '/theme', isLandscape),
                ],
              ),
            ),

            // 2. DAILY CHALLENGE PANEL (Right Side)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: isLandscape ? 150 : 170,
                  height: isLandscape ? 210 : 250, 
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 136, 198, 232),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    children: [
                      // Header
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
                      Text('Reward:', style: GoogleFonts.pixelifySans(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      // Colored Reward Box
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(int.parse(_getCurrentReward()["color"].replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getCurrentReward()["name"],
                        style: GoogleFonts.pixelifySans(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // --- RECTANGULAR PLAY NOW BUTTON ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed(
                            '/daily_challenge',
                            arguments: {
                              'user_id': userId,
                              'isNewbie': isNewbie,
                              'streak': userStreak,
                            },
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 231, 237, 236), // Rectangular button color
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color.fromARGB(86, 0, 0, 0), width: 2),
                            ),
                            child: Text(
                              'Play Now',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pixelifySans(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                      onTap: () => Navigator.of(context).pushNamed(
                      '/game',
                      arguments: {'user_id': userId},
                    ),
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