import 'dart:convert';
import 'dart:io'; 
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';
import 'package:tap_n_match/core/api_config.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with TickerProviderStateMixin {
  int userId = 1; // Default fallback
  bool isNewbie = true;
  int userStreak = 0;
  int completedDailyChallenges = 0;
  int bankedPoints = 0;
  int lifetimePoints = 0;
  String selectedTheme = "#A9A9A9";
  bool challengeCompletedToday = false;
  late final AnimationController _menuController;
  bool _didInitialize = false;
  int _claimableRewardCount = 0;
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;
  String? _activeTutorialId;
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _dailyChallengePanelKey = GlobalKey();
  final GlobalKey _dailyChallengeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(ApiConfig.getUri('/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['is_banned'] == 1 || data['is_banned'] == true) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/banned', 
              (route) => false,
              arguments: {'reason': data['ban_reason']},
            );
          }
          return;
        }

        setState(() {
          userStreak = data['streak'] ?? 0;
          completedDailyChallenges = data['completed_daily_challenges'] ?? 0;
          isNewbie = completedDailyChallenges < 7;
          selectedTheme = data['selected_theme'] ?? "#A9A9A9";
          bankedPoints = data['banked_points'] ?? 0;
          lifetimePoints = data['lifetime_points'] ?? 0;
          
          // Check if challenge was completed today
          final String? lastChallengeDate = data['last_challenge_date'];
          final String today = DateTime.now().toIso8601String().split('T')[0];
          challengeCompletedToday = (lastChallengeDate == today);
          _claimableRewardCount = data['claimable_reward_count'] as int? ?? 0;
        });

        // Update sound settings
        await soundManager.setTapSoundEnabled(data['tap_sound_enabled'] ?? true);
        await soundManager.setBgMusicEnabled(data['bg_music_enabled'] ?? true);
        await soundManager.setTapVolume((data['tap_volume'] as num?)?.toDouble() ?? 1.0);
        await soundManager.setBgVolume((data['bg_volume'] as num?)?.toDouble() ?? 0.5);
        await soundManager.setColorblindMode(data['colorblind_mode'] ?? false);
        
        await soundManager.updateSettings(
          tapSound: data['selected_tap_sound'],
          bgMusic: data['selected_bg_music'],
        );

        _queueTutorialIfNeeded(data);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  List<TutorialStep> get _tutorialSteps {
    if (_activeTutorialId == TutorialIds.welcome) {
      return <TutorialStep>[
        TutorialStep(
          targetKey: _playButtonKey,
          title: 'Welcome to Tap & Match!',
          description: 'Tap Play to start the game.',
          cardPosition: TutorialCardPosition.center,
          showSkip: false,
          cardOpacity: 0.7,
        ),
      ];
    }

    return <TutorialStep>[
      TutorialStep(
        targetKey: _dailyChallengePanelKey,
        title: 'Daily Challenge',
        description:
            'This panel shows today\'s Daily Challenge reward. Use it from the main menu when you want a special limited-time run.',
        cardPosition: TutorialCardPosition.centerLeft,
        cardOpacity: 0.7,
      ),
      TutorialStep(
        targetKey: _dailyChallengeButtonKey,
        title: 'Only 2 Attempts',
        description:
            'You only get 2 attempts for each Daily Challenge, so use them carefully before tapping Play Now.',
        cardPosition: TutorialCardPosition.bottomLeft,
        cardOpacity: 0.7,
      ),
      TutorialStep(
        targetKey: _dailyChallengePanelKey,
        title: '7-Day Daily Challenge',
        description:
            'The Daily Challenge cycle lasts for 7 days only. After that, the game moves on to the Weekly Challenge.',
        cardPosition: TutorialCardPosition.topLeft,
        cardOpacity: 0.7,
      ),
    ];
  }

  void _queueTutorialIfNeeded(Map<String, dynamic> data) {
    if (_tutorialQueued || _showTutorial) {
      return;
    }

    if (hasPendingTutorial(data, TutorialIds.welcome)) {
      _tutorialQueued = true;
      _showTutorialWhenReady(TutorialIds.welcome);
      return;
    }

    if (!hasPendingTutorial(data, TutorialIds.dailyChallenge)) {
      return;
    }

    if (hasPendingTutorial(data, TutorialIds.play) || challengeCompletedToday) {
      return;
    }

    _tutorialQueued = true;
    _showTutorialWhenReady(TutorialIds.dailyChallenge);
  }

  void _showTutorialWhenReady(String tutorialId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_areTutorialTargetsReady(tutorialId)) {
        // Wait 100ms and try again to avoid being stuck if no frames are scheduled
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _showTutorialWhenReady(tutorialId);
        });
        return;
      }

      setState(() {
        _activeTutorialId = tutorialId;
        _tutorialStepIndex = 0;
        _showTutorial = true;
      });
    });
  }

  bool _areTutorialTargetsReady(String tutorialId) {
    final List<GlobalKey> targets;
    switch (tutorialId) {
      case TutorialIds.welcome:
        targets = [_playButtonKey];
        break;
      case TutorialIds.dailyChallenge:
      default:
        targets = [
          _dailyChallengePanelKey,
          _dailyChallengeButtonKey,
        ];
        break;
    }

    for (final key in targets) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return false;
      }
    }

    return true;
  }

  Future<void> _finishTutorial() async {
    if (_isSavingTutorial || _activeTutorialId == null) return;

    final tutorialId = _activeTutorialId!;

    setState(() => _isSavingTutorial = true);
    try {
      await markTutorialComplete(
        userId: userId,
        tutorialId: tutorialId,
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
          _activeTutorialId = null;
          _tutorialQueued = false;
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFAED9E0), Color(0xFF89AFCF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black, width: 4),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SETTINGS',
                            style: GoogleFonts.pixelifySans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Tap Sound Toggle
                          _buildSettingsRow(
                            'Tap Sound',
                            Switch(
                              value: soundManager.tapSoundEnabled,
                              onChanged: (value) async {
                                await soundManager.setTapSoundEnabled(value);
                                await soundManager.persistToServer(userId);
                                setDialogState(() {});
                              },
                              activeThumbColor: Colors.green,
                            ),
                          ),
                          // Tap Volume Slider
                          _buildVolumeSlider(
                            'Tap Volume',
                            soundManager.tapVolume,
                            (value) async {
                              await soundManager.setTapVolume(value);
                              await soundManager.persistToServer(userId);
                              setDialogState(() {});
                            },
                          ),
                          const Divider(color: Colors.black54),
                          // Music Toggle
                          _buildSettingsRow(
                            'Music',
                            Switch(
                              value: soundManager.bgMusicEnabled,
                              onChanged: (value) async {
                                await soundManager.setBgMusicEnabled(value);
                                await soundManager.persistToServer(userId);
                                setDialogState(() {});
                              },
                              activeThumbColor: Colors.green,
                            ),
                          ),
                          // Music Volume Slider
                          _buildVolumeSlider(
                            'Music Volume',
                            soundManager.bgVolume,
                            (value) async {
                              await soundManager.setBgVolume(value);
                              await soundManager.persistToServer(userId);
                              setDialogState(() {});
                            },
                          ),
                          const Divider(color: Colors.black54),
                          // Colorblind Mode Toggle
                          _buildSettingsRow(
                            'Colorblind Mode',
                            Switch(
                              value: soundManager.colorblindMode,
                              onChanged: (value) async {
                                await soundManager.setColorblindMode(value);
                                await soundManager.persistToServer(userId);
                                setDialogState(() {});
                              },
                              activeThumbColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black, size: 28),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsRow(String label, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.pixelifySans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing,
      ],
    );
  }

  Widget _buildVolumeSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.pixelifySans(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: onChanged,
          activeColor: Colors.black,
          inactiveColor: Colors.black26,
        ),
      ],
    );
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

  final List<Map<String, dynamic>> weeklyChallengesConfig = [
    {"asset": "assets/background/harvest_moon_background.jpeg", "name": "Harvest Moon", "type": "theme"},
    {"asset": "assets/background/genshin_background.jpeg", "name": "Genshin", "type": "theme"},
  ];

  // Get current reward based on user progress
  Map<String, dynamic> _getCurrentReward() {
    if (isNewbie) {
      int index = completedDailyChallenges.clamp(0, 6);
      return newbieDaysConfig[index];
    } else {
      // Weekly challenges for veterans
      // Day 8-14: Week 1, Day 15-21: Week 2, etc.
      int weekIndex = ((completedDailyChallenges - 7) ~/ 7).clamp(0, weeklyChallengesConfig.length - 1);
      return weeklyChallengesConfig[weekIndex];
    }
  }

  ({String label, List<Color> colors, double phase}) _sidebarStyleForRoute(String route) {
    switch (route) {
      case '/profile':
        return (
          label: 'Profile',
          colors: [const Color(0xFF7ED6FF), const Color(0xFF3B82F6)],
          phase: 0.0,
        );
      case '/achievements':
        return (
          label: 'Awards',
          colors: [const Color(0xFFFFD166), const Color(0xFFFCA016)],
          phase: 0.9,
        );
      case '/leaderboards':
        return (
          label: 'Ranks',
          colors: [const Color(0xFF98EE99), const Color(0xFF2FBF71)],
          phase: 1.7,
        );
      case '/shop':
        return (
          label: 'Shop',
          colors: [const Color(0xFFFF9A8B), const Color(0xFFFF6A88)],
          phase: 2.1,
        );
      case '/theme':
      default:
        return (
          label: 'Themes',
          colors: [const Color(0xFFC38DFF), const Color(0xFF8E66FF)],
          phase: 2.4,
        );
    }
  }

  List<Color> _logoPalette(Color themeColor) {
    return [
      themeColor,
      const Color(0xFFFCA016),
      const Color(0xFF20DEFF),
      const Color(0xFF98EE99),
      const Color(0xFFFF7E7E),
      const Color(0xFFFFD166),
    ];
  }

  Color _logoCellColor(int index, double progress, List<Color> palette) {
    final shifted = (progress * palette.length * 1.35).floor();
    final baseIndex = (index + shifted) % palette.length;
    final nextIndex = (baseIndex + 1) % palette.length;
    final blend = (math.sin((progress * 2 * math.pi) + index * 0.75) + 1) / 2;
    return Color.lerp(palette[baseIndex], palette[nextIndex], blend) ?? palette[baseIndex];
  }

  Future<void> _openSidebarRoute(String route) async {
    await Navigator.of(context).pushNamed(
      route,
      arguments: {'user_id': userId},
    );

    if (!mounted) return;

    if (route == '/theme' || route == '/achievements') {
      await _loadUserData();
    }
  }

  // --- RESPONSIVE GRID LOGO ---
  Widget _buildLogoGrid(double screenHeight, Color themeColor) {
    final double gridSize = screenHeight * 0.35;
    final palette = _logoPalette(themeColor);

    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_menuController.value);
        final scale = 1 + math.sin(progress * 2 * math.pi) * 0.02;
        final rotation = math.sin(progress * 2 * math.pi) * 0.02;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: SizedBox(
              width: gridSize.clamp(110.0, 176.0),
              height: gridSize.clamp(110.0, 176.0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LogoSparkPainter(
                        progress: progress,
                        palette: palette,
                      ),
                    ),
                  ),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final color = _logoCellColor(index, progress, palette);
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withValues(alpha: 0.98),
                                color.withValues(alpha: 0.72),
                              ],
                            ),
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 4,
                                top: 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton({
    required bool isLandscape,
    required Color themeColor,
    required VoidCallback onTap,
    Key? tutorialKey,
  }) {
    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_menuController.value);
        final pulse = 1 + math.sin(progress * 2 * math.pi) * 0.025;
        final gradientShift = progress;
        final gradient = LinearGradient(
          begin: Alignment(-1 + gradientShift * 0.4, -1),
          end: Alignment(1, 1 - gradientShift * 0.35),
          colors: [
            Color.lerp(themeColor, const Color(0xFF8BD7FF), progress) ?? themeColor,
            Color.lerp(const Color(0xFFFCA016), const Color(0xFFFFE8A3), 1 - progress) ??
                const Color(0xFFFCA016),
          ],
        );

        return Transform.scale(
          scale: pulse,
          child: GestureDetector(
            key: tutorialKey,
            onTap: onTap,
            child: Container(
              width: isLandscape ? 220 : 210,
              margin: EdgeInsets.symmetric(vertical: isLandscape ? 4 : 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFCA016).withValues(alpha: 0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 14 : 16,
                        vertical: isLandscape ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.black, width: 2.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.32),
                              border: Border.all(color: Colors.black, width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLAY',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: isLandscape ? 20 : 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  shadows: const [
                                    Shadow(offset: Offset(1, 1), color: Colors.white70),
                                  ],
                                ),
                              ),
                              Text(
                                'Start the match',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: isLandscape ? 9 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Align(
                            alignment: Alignment(-1.2 + (progress * 2.4), 0),
                            child: Transform.rotate(
                              angle: -0.45,
                              child: Container(
                                width: 36,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.24),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildExitButton({
    required bool isLandscape,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLandscape ? 168 : 160,
        margin: EdgeInsets.symmetric(vertical: isLandscape ? 2 : 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade600.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.38), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_outlined, color: Colors.black54, size: isLandscape ? 18 : 17),
            const SizedBox(width: 8),
            Text(
              'Exit',
              style: GoogleFonts.pixelifySans(
                fontSize: isLandscape ? 15 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIDEBAR ICON HELPER ---
  Widget _buildSidebarIcon(
    BuildContext context,
    IconData icon,
    String route,
    bool isLandscape, {
    int badgeCount = 0,
  }) {
    final style = _sidebarStyleForRoute(route);
    final double tileSize = isLandscape ? 52 : 58;
    final double iconSize = isLandscape ? 20 : 23;

    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_menuController.value);
        final bob = math.sin((progress * 2 * math.pi) + style.phase) * (isLandscape ? 1.0 : 1.4);
        final glowStrength = 0.18 + (math.sin((progress * 2 * math.pi) + style.phase) + 1) * 0.08;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openSidebarRoute(route),
                child: Container(
                  width: tileSize,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: style.colors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: style.colors.first.withValues(alpha: glowStrength),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.40),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: iconSize + 12,
                          height: iconSize + 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1.2),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(icon, color: Colors.black.withValues(alpha: 0.60), size: iconSize + 2),
                              Icon(icon, color: Colors.white, size: iconSize),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          style.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                            fontSize: isLandscape ? 7.5 : 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            shadows: const [
                              Shadow(offset: Offset(1, 1), color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: GoogleFonts.pixelifySans(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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

    final themeColor = parseThemeColor(selectedTheme);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
        child: Stack(
          children: [
            // 1. SIDEBAR ICONS (Top Left)
            Positioned(
              left: 20,
              top: 25,
              child: Column(
                children: [
                  _buildSidebarIcon(context, Icons.account_circle, '/profile', isLandscape),
                  const SizedBox(height: 8),
                  _buildSidebarIcon(
                    context,
                    Icons.emoji_events,
                    '/achievements',
                    isLandscape,
                    badgeCount: _claimableRewardCount,
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarIcon(context, Icons.leaderboard, '/leaderboards', isLandscape),
                  const SizedBox(height: 8),
                  _buildSidebarIcon(context, Icons.shopping_cart, '/shop', isLandscape),
                  const SizedBox(height: 8),
                  _buildSidebarIcon(context, Icons.palette, '/theme', isLandscape),
                ],
              ),
            ),

            // Settings Icon (Top Right)
            Positioned(
              right: 20,
              top: 25,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          bankedPoints.toString(),
                          style: GoogleFonts.pixelifySans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showSettingsDialog,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
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
                  key: _dailyChallengePanelKey,
                  width: isLandscape ? 142 : 150,
                  height: isLandscape ? 178 : 194,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black, width: 2.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFBBD5FF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                        ),
                        child: Text(
                          'Daily Challenge',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: challengeCompletedToday
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF98EE99),
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: const Icon(Icons.check_rounded, color: Colors.black, size: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Completed today',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.pixelifySans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Come back tomorrow',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 8,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Today\'s reward',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getCurrentReward().containsKey("color")
                                          ? Color(int.parse(_getCurrentReward()["color"].replaceFirst('#', '0xFF')))
                                          : Colors.grey[300],
                                      image: _getCurrentReward().containsKey("asset")
                                          ? DecorationImage(
                                              image: AssetImage(_getCurrentReward()["asset"]),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getCurrentReward()["name"],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.of(context).pushNamed(
                                        '/daily_challenge',
                                        arguments: {
                                          'user_id': userId,
                                          'isNewbie': isNewbie,
                                          'streak': userStreak,
                                          'completedChallenges': completedDailyChallenges,
                                        },
                                      );
                                      _loadUserData();
                                    },
                                    child: Container(
                                      key: _dailyChallengeButtonKey,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F8FC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color.fromARGB(86, 0, 0, 0), width: 1.4),
                                      ),
                                      child: Text(
                                        'Play Now',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.pixelifySans(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                    _buildLogoGrid(screenHeight, themeColor),
                    SizedBox(height: isLandscape ? 8 : 15),
                    _buildTitleText('Tap & Match', isLandscape ? 40 : 55, const Color(0xFFFCA016)),
                    _buildTitleText('The Color Game', isLandscape ? 16 : 22, const Color(0xFF20DEFF)),
                    SizedBox(height: isLandscape ? 8 : 25),
                    _buildPlayButton(
                      isLandscape: isLandscape,
                      themeColor: themeColor,
                      tutorialKey: _playButtonKey,
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          '/game',
                          arguments: {'user_id': userId},
                        );
                        if (!mounted) return;
                        await _loadUserData();
                      },
                    ),
                    _buildExitButton(
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

            // 4. SUPPORT BUTTON (Bottom Right)
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(
                  '/support',
                  arguments: {
                    'user_id': userId,
                    'selected_theme': selectedTheme,
                  },
                ),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FB3D9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
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

class _LogoSparkPainter extends CustomPainter {
  _LogoSparkPainter({
    required this.progress,
    required this.palette,
  });

  final double progress;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius * 0.88, ringPaint);

    const sparkCount = 12;
    for (var i = 0; i < sparkCount; i++) {
      final baseAngle = (i / sparkCount) * 2 * math.pi;
      final orbitOffset = progress * 2 * math.pi * (0.8 + (i % 4) * 0.05);
      final wobble = math.sin((progress * 2 * math.pi) + i * 0.55);
      final distance = radius * 0.90 + 8 + wobble * 3.5;
      final direction = baseAngle + orbitOffset;
      final sparkPosition = center +
          Offset(
            math.cos(direction) * distance,
            math.sin(direction) * distance,
          );
      final color = palette[(i + (progress * palette.length).floor()) % palette.length];

      final sparkPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.95);
      canvas.drawCircle(sparkPosition, 1.4 + (i % 3) * 0.35, sparkPaint);

      final streakPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.9
        ..color = color.withValues(alpha: 0.45);
      canvas.drawLine(
        sparkPosition - const Offset(2, 0),
        sparkPosition + const Offset(2, 0),
        streakPaint,
      );
      canvas.drawLine(
        sparkPosition - const Offset(0, 2),
        sparkPosition + const Offset(0, 2),
        streakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoSparkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.palette != palette;
  }
}
