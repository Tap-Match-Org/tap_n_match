import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';

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
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;
  final GlobalKey _headerRowKey = GlobalKey();
  final GlobalKey _playersListKey = GlobalKey();

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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            selectedTheme = data['selected_theme'] ?? "#A9A9A9";
          });
        }
        _queueTutorialIfNeeded(data);
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

  List<TutorialStep> get _tutorialSteps => [
        TutorialStep(
          targetKey: _headerRowKey,
          title: 'Leaderboard Columns',
          description:
              'This row shows how the leaderboard is ranked: score, level progress, and achievements all contribute to the overview.',
          cardPosition: TutorialCardPosition.topCenter,
        ),
        TutorialStep(
          targetKey: _playersListKey,
          title: 'Open Player Profiles',
          description:
              'Tap any player row to open their public profile and compare their performance with yours.',
          cardPosition: TutorialCardPosition.bottomCenter,
        ),
      ];

  void _queueTutorialIfNeeded(Map<String, dynamic> data) {
    if (_tutorialQueued || !hasPendingTutorial(data, TutorialIds.leaderboards)) {
      return;
    }

    _tutorialQueued = true;
    _showTutorialWhenReady();
  }

  void _showTutorialWhenReady() {
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;

      if (!_areTutorialTargetsReady()) {
        WidgetsBinding.instance.scheduleFrame();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _showTutorialWhenReady();
        });
        return;
      }

      if (_showTutorial) return;

      setState(() {
        _tutorialStepIndex = 0;
        _showTutorial = true;
      });
    });
  }

  bool _areTutorialTargetsReady() {
    final targets = [
      _headerRowKey,
      _playersListKey,
    ];

    for (final key in targets) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return false;
      }
    }

    return true;
  }

  Future<void> _finishTutorial() async {
    if (_isSavingTutorial) return;

    setState(() => _isSavingTutorial = true);
    try {
      await markTutorialComplete(
        userId: userId,
        tutorialId: TutorialIds.leaderboards,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTutorial = false;
          _showTutorial = false;
        });
      }
    }
  }

  Future<void> _handleTutorialNext() async {
    if (_tutorialStepIndex < _tutorialSteps.length - 1) {
      setState(() => _tutorialStepIndex++);
      return;
    }

    await _finishTutorial();
  }

  void _handleTutorialBack() {
    if (_tutorialStepIndex == 0) return;
    setState(() => _tutorialStepIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
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
                        key: _headerRowKey,
                        color: const Color(0xFFAEC6FF).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHeaderText("RANKING"),
                            _buildHeaderText("PLAYER NAME"),
                            _buildHeaderText("LIFETIME POINTS"),
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
                          key: _playersListKey,
                          padding: const EdgeInsets.all(10),
                          children: _players.map((player) {
                            final rank = (player['rank'] ?? '').toString();
                            final name = (player['username'] ?? '').toString();
                            final highestScore = (player['score'] ?? 0).toString();
                            final level = (player['highest_level'] ?? 0).toString();
                            final ach = (player['achievement_count'] ?? 0).toString();
                            final playerId = (player['user_id'] as num?)?.toInt() ?? 0;
                            final playerTheme = (player['selected_theme'] ?? '#A9A9A9').toString();
                            final isCurrentUser = playerId == userId;
                            return _buildLeaderRow(
                              context,
                              playerId: playerId,
                              selectedTheme: playerTheme,
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
            if (_showTutorial)
              GuidedTutorialOverlay(
                steps: _tutorialSteps,
                currentIndex: _tutorialStepIndex,
                onNext: _handleTutorialNext,
                onBack: _handleTutorialBack,
                onSkip: _finishTutorial,
                isSaving: _isSavingTutorial,
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
    required String selectedTheme,
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
            'initial_selected_theme': selectedTheme,
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
