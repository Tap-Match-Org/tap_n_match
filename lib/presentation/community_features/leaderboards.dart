import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  int userId = 1; // Default fallback
  String selectedTheme = "#A9A9A9";
  bool isLoading = true;
  bool _didInitialize = false;
  List<Map<String, dynamic>> _players = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    await _loadUserData();
    await _loadLeaderboards();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            selectedTheme = data['selected_theme'] ?? "#A9A9A9";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadLeaderboards() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/leaderboards'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawPlayers = (data['players'] as List<dynamic>? ?? []);
        if (mounted) {
          setState(() {
            _players = rawPlayers
                .map((player) => Map<String, dynamic>.from(player as Map))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
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
                          color: const Color(0xFFFCA016), 
                          shadows: [
                            const Shadow(offset: Offset(2, 2), color: Colors.black),
                          ],
                        ),
                      ),
                    ),

                    if (isLoading)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_players.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            "No scores yet.",
                            style: GoogleFonts.pixelifySans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // TABLE HEADERS
                      Container(
                        color: const Color(0xFFAEC6FF).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHeaderText("RANKING"),
                            _buildHeaderText("PLAYER NAME"),
                            _buildHeaderText("HIGHEST SCORE"),
                            _buildHeaderText("HIGHEST LEVEL"),
                            _buildHeaderText("ACHIEVEMENTS"),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          'Tap a player row to open their public profile.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      // SCROLLABLE LIST OF PLAYERS
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(10),
                          children: _players.map((player) {
                            final rank = (player['rank'] ?? '').toString();
                            final name = (player['username'] ?? '').toString();
                            final highestScore = (player['score'] ?? 0).toString();
                            final level = (player['highest_level'] ?? 0).toString();
                            final ach = (player['achievement_count'] ?? 0).toString();
                            final playerId = (player['user_id'] as num?)?.toInt() ?? 0;
                            final isCurrentUser = playerId == userId;
                            return _buildLeaderRow(
                              context,
                              playerId: playerId,
                              rank: rank,
                              name: name,
                              highestScore: highestScore,
                              level: level,
                              ach: ach,
                              isCurrentUser: isCurrentUser,
                            );
                          }).toList(),
                        ),
                      ),
                    ]
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

  Widget _buildLeaderRow(
    BuildContext context, {
    required int playerId,
    required String rank,
    required String name,
    required String highestScore,
    required String level,
    required String ach,
    bool isCurrentUser = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pushNamed(
          '/profile',
          arguments: {
            'user_id': playerId,
            'public_profile': true,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFFFCA016).withOpacity(0.35) : const Color(0xFFAEC6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCellText(rank),
            _buildCellText(name),
            _buildCellText(highestScore),
            _buildCellText(level),
            _buildCellText(ach),
          ],
        ),
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
