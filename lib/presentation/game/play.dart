import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';

class GamePage extends StatefulWidget {
  final http.Client? httpClient;
  const GamePage({super.key, this.httpClient});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final Random _random = Random();
  int userId = 1;
  String selectedTheme = "#A9A9A9";
  int currentLevel = 1;
  int currentScore = 0;
  int achievementCount = 0;
  int highestScore = 0;
  bool isGameOver = false;
  bool isPaused = false;
  bool _isLoading = true;
  bool _didInitialize = false;
  bool _isSubmittingLevel = false;
  bool _usedDoneButtonThisLevel = false;
  bool _madeDoneMistakeThisLevel = false;
  int _tapCountThisLevel = 0;
  int _optimalTapCount = 0;
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  bool _hasPendingPlayTutorial = false;
  bool _isTutorialActive = false;
  int _tutorialStepIndex = 0;
  final GlobalKey _scoreBarKey = GlobalKey();
  final GlobalKey _targetGridKey = GlobalKey();
  final GlobalKey _userGridKey = GlobalKey();
  final GlobalKey _doneButtonKey = GlobalKey();

  late List<int> targetPattern;
  late List<int> userPattern;
  late int secondsLeft;
  Timer? timer;
  Timer? pauseShuffleTimer;
  Timer? _topSnackBarTimer;
  OverlayEntry? _topSnackBarEntry;
  late final AnimationController _topSnackBarController;
  late final http.Client _client;
  late final bool _ownsClient;
  String _topSnackBarMessage = "";

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.httpClient == null;
    _client = widget.httpClient ?? http.Client();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _topSnackBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _initializeGame();
  }

  List<TutorialStep> get _tutorialSteps => [
        TutorialStep(
          targetKey: _targetGridKey,
          title: 'Copy This Pattern',
          description:
              'The left boxes show the pattern you need to match. Study the colors before you start tapping.',
          cardPosition: TutorialCardPosition.topLeft,
          showArrow: false,
        ),
        TutorialStep(
          targetKey: _userGridKey,
          title: 'Tap Your Boxes',
          description:
              'Tap the boxes on your grid to cycle through colors until every box matches the target pattern.',
          cardPosition: TutorialCardPosition.topRight,
          showArrow: false,
        ),
        TutorialStep(
          targetKey: _doneButtonKey,
          title: 'Finish The Level',
          description:
              'When your grid matches the target, tap Done. Clear the pattern before the timer reaches zero to finish the level.',
          cardPosition: TutorialCardPosition.topCenter,
        ),
        TutorialStep(
          targetKey: _scoreBarKey,
          title: 'How Scoring Works',
          description:
              'Your score increases from base level points, a fast-finish bonus when you clear early, and a perfect bonus for clean matches.',
          cardPosition: TutorialCardPosition.bottomLeft,
        ),
      ];

  Future<void> _initializeGame() async {
    await _loadUserData();
    _startLevel();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    _queueTutorialIfNeeded();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _client.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _hasPendingPlayTutorial = hasPendingTutorial(
          Map<String, dynamic>.from(data as Map),
          TutorialIds.play,
        );
        if (mounted) {
          setState(() {
            selectedTheme = data['selected_theme'] ?? "#A9A9A9";
            currentScore = 0;
            highestScore = data['highest_score'] ?? 0;
            achievementCount = data['achievement_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading theme: $e");
    }
  }

  void _queueTutorialIfNeeded() {
    if (_tutorialQueued || !_hasPendingPlayTutorial) {
      return;
    }

    _tutorialQueued = true;
    timer?.cancel();
    unawaited(_showTutorialWhenReady());
  }

  Future<void> _showTutorialWhenReady() async {
    while (mounted) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      if (_areTutorialTargetsReady()) {
        setState(() {
          _isTutorialActive = true;
          _tutorialStepIndex = 0;
          _showTutorial = true;
        });
        return;
      }

      // Force a new frame to ensure currentContext is updated
      WidgetsBinding.instance.scheduleFrame();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _areTutorialTargetsReady() {
    final targets = [
      _targetGridKey,
      _userGridKey,
      _doneButtonKey,
      _scoreBarKey,
    ];

    for (final key in targets) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return false;
      }
    }

    return true;
  }

  void _resumeAfterTutorialIfNeeded() {
    if (!mounted || _isLoading || isPaused || isGameOver) {
      return;
    }
    _startTimer();
  }

  Future<void> _finishTutorial() async {
    if (_isSavingTutorial) return;

    setState(() => _isSavingTutorial = true);
    try {
      await markTutorialComplete(
        userId: userId,
        tutorialId: TutorialIds.play,
      );
    } catch (error) {
      await _showTopSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTutorial = false;
          _isTutorialActive = false;
          _showTutorial = false;
        });
        _resumeAfterTutorialIfNeeded();
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

  void _startLevel() {
    final config = _getDifficultyConfig(currentLevel);
    int totalBoxes = config.rows * config.cols;

    timer?.cancel();
    pauseShuffleTimer?.cancel();
    targetPattern = List.generate(totalBoxes, (index) => _nextPatternValue(config.colors, excludeDefault: true));
    userPattern = List.filled(totalBoxes, 0);
    _optimalTapCount = targetPattern.fold<int>(0, (sum, value) => sum + value);
    _tapCountThisLevel = 0;
    _usedDoneButtonThisLevel = false;
    _madeDoneMistakeThisLevel = false;
    _isSubmittingLevel = false;
    secondsLeft = config.time;
    isGameOver = false;
    isPaused = false;

    _startTimer();
    if (mounted) setState(() {});
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || isPaused || isGameOver || _isTutorialActive) return;

      if (secondsLeft <= 1) {
        t.cancel();
        setState(() => secondsLeft = 0);
        _handleGameOver(false);
        return;
      }

      setState(() => secondsLeft--);
    });
  }

  void _pauseGame() {
    if (isPaused || isGameOver) return;

    timer?.cancel();
    pauseShuffleTimer?.cancel();
    setState(() => isPaused = true);

    // Anti-abuse: Shuffle target pattern every 2 seconds while paused
    pauseShuffleTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      final config = _getDifficultyConfig(currentLevel);
      if (mounted) {
        setState(() {
          targetPattern = List.generate(
            targetPattern.length,
            (index) => _nextPatternValue(config.colors, excludeDefault: true)
          );
        });
      }
    });
  }

  void _resumeGame() {
    if (!isPaused || isGameOver) return;

    pauseShuffleTimer?.cancel();
    setState(() => isPaused = false);
    _startTimer();
  }

  Future<void> _showExitConfirmation({bool returnToPauseMenu = false}) async {
    bool wasPaused = isPaused;
    if (!wasPaused) _pauseGame();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 3)),
        title: Text("QUIT GAME?", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        content: Text("Your progress will be lost and reset to Level 1!", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans()),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton("No", () {
                Navigator.pop(ctx);
                if (returnToPauseMenu) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showPauseDialog();
                    }
                  });
                } else if (!wasPaused) {
                  _resumeGame();
                }
              }),
              _buildButton("Yes", () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    if (_isLoading || isGameOver) return;

    _pauseGame();
    final action = await showDialog<_PauseDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFB2B9D1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 3)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconBtn(Icons.play_arrow, "Resume", () {
                  Navigator.pop(ctx, _PauseDialogAction.resume);
                }),
                Text(
                  "PAUSED",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
                ),
                _buildIconBtn(Icons.home, "Home", () {
                  Navigator.pop(ctx, _PauseDialogAction.home);
                }),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tap Sounds", style: GoogleFonts.pixelifySans(fontSize: 12)),
                        Switch(
                          value: soundManager.tapSoundEnabled,
                          onChanged: (val) async {
                            await soundManager.setTapSoundEnabled(val);
                            await soundManager.persistToServer(userId);
                            setDialogState(() {});
                          },
                          activeThumbColor: Colors.green,
                        ),
                        ],
                        ),
                        const SizedBox(height: 8),
                        _buildVolumeControl(
                        label: "Tap Volume",
                        value: soundManager.tapVolume,
                        onChanged: (value) async {
                        await soundManager.setTapVolume(value);
                        await soundManager.persistToServer(userId);
                        setDialogState(() {});
                        },
                        ),
                        const SizedBox(height: 8),
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text("Music", style: GoogleFonts.pixelifySans(fontSize: 12)),
                        Switch(
                          value: soundManager.bgMusicEnabled,
                          onChanged: (val) async {
                            await soundManager.setBgMusicEnabled(val);
                            await soundManager.persistToServer(userId);
                            setDialogState(() {});
                          },
                          activeThumbColor: Colors.green,
                        ),
                        ],
                        ),
                        const SizedBox(height: 8),
                        _buildVolumeControl(
                          label: "Music Volume",
                          value: soundManager.bgVolume,
                          onChanged: (value) async {
                            await soundManager.setBgVolume(value);
                            await soundManager.persistToServer(userId);
                            setDialogState(() {});
                          },
                        ),
                        const Divider(color: Colors.black54),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Colorblind Mode", style: GoogleFonts.pixelifySans(fontSize: 12)),
                            Switch(
                              value: soundManager.colorblindMode,
                              onChanged: (val) async {
                                await soundManager.setColorblindMode(val);
                                await soundManager.persistToServer(userId);
                                setDialogState(() {});
                              },
                              activeThumbColor: Colors.blue,
                            ),
                          ],
                        ),                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || !isPaused) return;

    switch (action) {
      case _PauseDialogAction.home:
        await _showExitConfirmation(returnToPauseMenu: true);
        break;
      case _PauseDialogAction.resume:
      case null:
        _resumeGame();
        break;
    }
  }

  Widget _buildIconBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black, size: 32),
          onPressed: onTap,
        ),
        Text(label, style: GoogleFonts.pixelifySans(fontSize: 12)),
      ],
    );
  }

  Widget _buildVolumeControl({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.pixelifySans(fontSize: 12)),
            Text(
              "${(value * 100).round()}%",
              style: GoogleFonts.pixelifySans(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          activeColor: Colors.green,
          inactiveColor: Colors.black26,
          onChanged: onChanged,
        ),
      ],
    );
  }

  _DifficultyConfig _getDifficultyConfig(int level) {
    if (level <= 20) {
      return _DifficultyConfig(rows: 2, cols: 2, colors: 4, time: 12, label: "Easy");
    } else if (level <= 50) {
      return _DifficultyConfig(rows: 3, cols: 3, colors: 5, time: 15, label: "Normal");
    } else if (level <= 100) {
      return _DifficultyConfig(rows: 5, cols: 5, colors: 5, time: 20, label: "Hard");
    } else {
      return _DifficultyConfig(rows: 5, cols: 5, colors: 8, time: 32, label: "Extreme");
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  int _nextPatternValue(int colorCount, {bool excludeDefault = false}) {
    if (colorCount <= 1) return 0;

    if (excludeDefault) {
      // Pick a random color from 1 to colorCount - 1
      return 1 + _random.nextInt(colorCount - 1);
    }

    // Keep white available, but less frequent than the other colors.
    final weightedPoolSize = 1 + ((colorCount - 1) * 2);
    final roll = _random.nextInt(weightedPoolSize);
    if (roll == 0) return 0;

    return 1 + ((roll - 1) ~/ 2);
  }

  bool _patternsMatch() {
    for (int i = 0; i < targetPattern.length; i++) {
      if (userPattern[i] != targetPattern[i]) {
        return false;
      }
    }
    return true;
  }

  void _handleCellTap(int index, _DifficultyConfig config) {
    if (_isSubmittingLevel || isPaused || isGameOver) return;

    soundManager.playTap();
    setState(() {
      _tapCountThisLevel++;
      userPattern[index] = (userPattern[index] + 1) % config.colors;
    });
  }

  void _checkWin({required bool triggeredByDone}) {
    if (_isSubmittingLevel || isGameOver) return;

    if (_patternsMatch()) {
      timer?.cancel();
      unawaited(_handleWin(triggeredByDone: triggeredByDone));
    } else {
      _madeDoneMistakeThisLevel = true;
      _showTopSnackBar("Not a match!");
    }
  }

  Future<void> _handleWin({required bool triggeredByDone}) async {
    if (_isSubmittingLevel) return;

    _isSubmittingLevel = true;
    _usedDoneButtonThisLevel = triggeredByDone;
    timer?.cancel();
    pauseShuffleTimer?.cancel();
    
    // Celebratory effect
    _confettiController.play();
    
    if (mounted) {
      setState(() {});
    }

    final config = _getDifficultyConfig(currentLevel);
    final payload = {
      'level': currentLevel,
      'difficulty': config.label,
      'seconds_left': secondsLeft,
      'used_done_button': _usedDoneButtonThisLevel,
      'perfect_run': _tapCountThisLevel == _optimalTapCount && !_madeDoneMistakeThisLevel,
      'boxes_tapped': _tapCountThisLevel,
      'run_score_before_level': currentScore,
    };

    try {
      final response = await _client.put(
        Uri.parse('http://localhost:8000/complete-level/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected status code ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final scoreBreakdown = (data['score_breakdown'] as Map<String, dynamic>?) ?? {};
      final earnedScore = (scoreBreakdown['total_earned'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          currentScore += earnedScore;
          highestScore = (data['highest_score'] as int?) ?? highestScore;
          achievementCount = (data['achievement_count'] as int?) ?? achievementCount;
        });
      }
    } catch (e) {
      debugPrint("Error recording score: $e");
      if (mounted) {
        await _showTopSnackBar("Level cleared, but score sync failed.");
      }
    } finally {
      _isSubmittingLevel = false;
      if (mounted) {
        setState(() {});
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 3)),
        title: Text("LEVEL COMPLETE!", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        content: Text(
          "You've cleared Level $currentLevel!\nScore: $currentScore\nAchievements: $achievementCount",
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(),
        ),
        actions: [
          Center(
            child: _buildButton("Next Level", () {
              Navigator.pop(ctx);
              setState(() => currentLevel++);
              _startLevel();
            }),
          )
        ],
      ),
    );
  }

  Future<void> _showTopSnackBar(String message) async {
    _topSnackBarTimer?.cancel();
    _topSnackBarMessage = message;

    if (_topSnackBarEntry == null) {
      final animation = CurvedAnimation(
        parent: _topSnackBarController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );

      _topSnackBarEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final offsetY = (-70 * (1 - animation.value)).clamp(-70, 0).toDouble();
                return Opacity(
                  opacity: animation.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, offsetY),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2B9D1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _topSnackBarMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_topSnackBarEntry!);
    } else {
      _topSnackBarEntry!.markNeedsBuild();
    }

    await _topSnackBarController.forward(from: 0);
    _topSnackBarTimer = Timer(const Duration(milliseconds: 650), () async {
      await _topSnackBarController.reverse();
      _topSnackBarEntry?.remove();
      _topSnackBarEntry = null;
    });
  }

  void _handleGameOver(bool quit) {
    timer?.cancel();
    final finalScore = currentScore;
    if (mounted) {
      setState(() {
        isGameOver = true;
        currentScore = 0;
      });
    }

    if (quit) {
      _showExitConfirmation();
      return;
    }

    _showGameOverDialog(finalScore);
  }

  Future<void> _showGameOverDialog(int finalScore) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogWidth = (screenWidth * 0.92).clamp(320.0, 1100.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: dialogWidth,
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB7C9F1), Color(0xFF7E91B4)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        highestScore.toString(),
                        style: GoogleFonts.pixelifySans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD24D),
                          shadows: const [
                            Shadow(offset: Offset(1, 1), color: Colors.black),
                          ],
                        ),
                      ),
                      Text(
                        'Highest Score',
                        style: GoogleFonts.pixelifySans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(1, 1), color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 22),
                    _buildOutlinedDialogText(
                      'Game Over',
                      fontSize: 54,
                      fill: const Color(0xFFEE4B2B),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildGameOverAction(
                          icon: Icons.replay_circle_filled_rounded,
                          label: 'Retry',
                          iconColor: const Color(0xFF8AE234),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              currentLevel = 1;
                              currentScore = 0;
                            });
                            _startLevel();
                          },
                        ),
                        const SizedBox(width: 24),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              finalScore.toString(),
                              style: GoogleFonts.pixelifySans(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD24D),
                                shadows: const [
                                  Shadow(offset: Offset(1, 1), color: Colors.black),
                                ],
                              ),
                            ),
                            Text(
                              'Total Score',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(offset: Offset(1, 1), color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        _buildGameOverAction(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          iconColor: const Color(0xFF8AE234),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlinedDialogText(
    String text, {
    required double fontSize,
    required Color fill,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: fontSize,
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
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: fill,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.pixelifySans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(offset: Offset(1, 1), color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    timer?.cancel();
    pauseShuffleTimer?.cancel();
    _topSnackBarTimer?.cancel();
    _topSnackBarEntry?.remove();
    _topSnackBarController.dispose();
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getDifficultyConfig(currentLevel);

    return Scaffold(
      body: Container(
        decoration: buildThemeDecoration(
          selectedTheme,
          radial: false,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          opacityStart: 0.8,
          opacityEnd: 0.5,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _isLoading
                  ? const Center(
                      child: Text(
                        "Loading...",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    )
                  : _buildGameContent(config),

              // Celebratory Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    Colors.yellow,
                    Colors.red,
                  ],
                  createParticlePath: _drawStar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(_DifficultyConfig config) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          top: 20,
          child: _buildScoreBar(),
        ),
        Positioned(
          right: 20,
          top: 20,
          child: Row(
            children: [
              Text(
                "Level: $currentLevel (${config.label})",
                style: GoogleFonts.pixelifySans(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: _showPauseDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.pause, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGrid(
                  targetPattern,
                  false,
                  "Target",
                  config,
                  tutorialKey: _targetGridKey,
                ),
                const SizedBox(width: 20),
                _buildCenterUI(),
                const SizedBox(width: 20),
                _buildGrid(
                  userPattern,
                  !isGameOver && !isPaused && !_isSubmittingLevel,
                  "Your Grid",
                  config,
                  tutorialKey: _userGridKey,
                ),
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
    );
  }

  Widget _buildCenterUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(secondsLeft),
          style: GoogleFonts.pixelifySans(
              fontSize: 32,
              color: secondsLeft <= 5 ? Colors.red : Colors.white),
        ),
        const Icon(Icons.timer_outlined, color: Colors.black, size: 48),
        const SizedBox(height: 30),
        Container(
          key: _doneButtonKey,
          child: _buildButton(
            "Done",
            (isGameOver || isPaused || _isSubmittingLevel)
                ? () {}
                : () => _checkWin(triggeredByDone: true),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar() {
    return Container(
      key: _scoreBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Score",
            style: GoogleFonts.pixelifySans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            currentScore.toString(),
            style: GoogleFonts.pixelifySans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            "High Score: $highestScore",
            style: GoogleFonts.pixelifySans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<int> gridData,
    bool isInteractive,
    String label,
    _DifficultyConfig config, {
    Key? tutorialKey,
  }) {
    double boxSize = 260 / max(config.rows, config.cols);
    if (boxSize > 60) boxSize = 60;

    return Column(
      key: tutorialKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.pixelifySans(color: Colors.white70)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26, width: 2),
          ),
          child: Column(
            children: List.generate(config.rows, (r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(config.cols, (c) {
                  int index = r * config.cols + c;
                  return GestureDetector(
                    onTap: isInteractive
                        ? () => _handleCellTap(index, config)
                        : null,
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getColorForValue(gridData[index]),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: soundManager.colorblindMode
                          ? Center(
                              child: Icon(
                                _getSymbolForValue(gridData[index]),
                                size: boxSize * 0.6,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(text,
          style: GoogleFonts.pixelifySans(
              color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  Color _getColorForValue(int value) {
    switch (value) {
      case 0:
        return Colors.white;
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.orange;
      case 6:
        return Colors.purple;
      case 7:
        return Colors.cyan;
      default:
        return Colors.white;
    }
  }

  IconData? _getSymbolForValue(int value) {
    switch (value) {
      case 1:
        return Icons.favorite;
      case 2:
        return Icons.cloud;
      case 3:
        return Icons.eco;
      case 4:
        return Icons.star;
      case 5:
        return Icons.diamond;
      case 6:
        return Icons.bolt;
      case 7:
        return Icons.hexagon;
      default:
        return null;
    }
  }

  Path _drawStar(Size size) {
    // Star drawing logic
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(-90);

    path.moveTo(size.width / 2, 0);

    for (int step = 0; degToRad(step.toDouble()) < degToRad(360); step += (360 ~/ numberOfPoints)) {
      path.lineTo(halfWidth + externalRadius * cos(degToRad(step.toDouble()) + fullAngle),
          halfWidth + externalRadius * sin(degToRad(step.toDouble()) + fullAngle));
      path.lineTo(halfWidth + internalRadius * cos(degToRad(step.toDouble()) + halfDegreesPerStep + fullAngle),
          halfWidth + internalRadius * sin(degToRad(step.toDouble()) + halfDegreesPerStep + fullAngle));
    }
    path.close();
    return path;
  }
}

enum _PauseDialogAction {
  home,
  resume,
}

class _DifficultyConfig {
  final int rows;
  final int cols;
  final int colors;
  final int time;
  final String label;

  _DifficultyConfig({
    required this.rows,
    required this.cols,
    required this.colors,
    required this.time,
    required this.label,
  });
  
}
