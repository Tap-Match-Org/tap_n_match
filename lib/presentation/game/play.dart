import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/infrastructure/soundmanager.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int userId = 1;
  String selectedTheme = "#A9A9A9";
  int currentLevel = 1;
  bool isGameOver = false;
  bool isPaused = false;
  bool _isLoading = true;
  bool _didInitialize = false;

  late List<int> targetPattern;
  late List<int> userPattern;
  late int secondsLeft;
  Timer? timer;
  Timer? pauseShuffleTimer;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
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

  Future<void> _initializeGame() async {
    await _loadUserData();
    _startLevel();

    if (mounted) {
      setState(() => _isLoading = false);
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
      debugPrint("Error loading theme: $e");
    }
  }

  void _startLevel() {
    final config = _getDifficultyConfig(currentLevel);
    int totalBoxes = config.rows * config.cols;

    timer?.cancel();
    pauseShuffleTimer?.cancel();
    targetPattern = List.generate(totalBoxes, (index) => _nextPatternValue(config.colors));
    userPattern = List.filled(totalBoxes, 0);
    secondsLeft = config.time;
    isGameOver = false;
    isPaused = false;

    _startTimer();
    if (mounted) setState(() {});
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || isPaused || isGameOver) return;

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
            (index) => _nextPatternValue(config.colors)
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
                            setDialogState(() {});
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildVolumeControl(
                      label: "Tap Volume",
                      value: soundManager.tapVolume,
                      onChanged: (value) async {
                        await soundManager.setTapVolume(value);
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
                            setDialogState(() {});
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildVolumeControl(
                      label: "Music Volume",
                      value: soundManager.bgVolume,
                      onChanged: (value) async {
                        await soundManager.setBgVolume(value);
                        setDialogState(() {});
                      },
                    ),
                  ],
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
      return _DifficultyConfig(rows: 2, cols: 2, colors: 4, time: 10, label: "Easy");
    } else if (level <= 50) {
      return _DifficultyConfig(rows: 3, cols: 3, colors: 5, time: 20, label: "Normal");
    } else if (level <= 100) {
      return _DifficultyConfig(rows: 3, cols: 6, colors: 5, time: 32, label: "Hard");
    } else {
      return _DifficultyConfig(rows: 3, cols: 6, colors: 8, time: 60, label: "Extreme");
    }
  }

  int _nextPatternValue(int colorCount) {
    if (colorCount <= 1) return 0;

    // Keep white available, but less frequent than the other colors.
    final weightedPoolSize = 1 + ((colorCount - 1) * 2);
    final roll = _random.nextInt(weightedPoolSize);
    if (roll == 0) return 0;

    return 1 + ((roll - 1) ~/ 2);
  }

  void _checkWin() {
    bool isMatch = true;
    for (int i = 0; i < targetPattern.length; i++) {
      if (userPattern[i] != targetPattern[i]) {
        isMatch = false;
        break;
      }
    }

    if (isMatch) {
      timer?.cancel();
      _handleWin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not a match!"), duration: Duration(milliseconds: 500)),
      );
    }
  }

  void _handleWin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 3)),
        title: Text("LEVEL COMPLETE!", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        content: Text("You've cleared Level $currentLevel!", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans()),
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

  void _handleGameOver(bool quit) {
    timer?.cancel();
    if (mounted) setState(() => isGameOver = true);
    
    if (quit) {
      _showExitConfirmation();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 3)),
        title: Text("GAME OVER!", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        content: Text("You failed Level $currentLevel.\nProgress has been reset to Level 1.", textAlign: TextAlign.center, style: GoogleFonts.pixelifySans()),
        actions: [
          Center(
            child: Column(
              children: [
                _buildButton("Retry (Level 1)", () {
                  Navigator.pop(ctx);
                  setState(() => currentLevel = 1);
                  _startLevel();
                }),
                const SizedBox(height: 10),
                _buildButton("Back to Menu", () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    pauseShuffleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Color(int.parse(selectedTheme.replaceFirst('#', '0xFF')));
    final config = _getDifficultyConfig(currentLevel);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeColor.withOpacity(0.8), themeColor.withOpacity(0.5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Text(
                    "Loading...",
                    style: GoogleFonts.pixelifySans(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Row(
                        children: [
                          Text(
                            "Level: $currentLevel (${config.label})",
                            style: GoogleFonts.pixelifySans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
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
                            _buildGrid(targetPattern, false, "Target", config),
                            const SizedBox(width: 20),
                            _buildCenterUI(),
                            const SizedBox(width: 20),
                            _buildGrid(userPattern, !isGameOver && !isPaused, "Your Grid", config),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCenterUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "00:${secondsLeft.toString().padLeft(2, '0')}",
          style: GoogleFonts.pixelifySans(
              fontSize: 32,
              color: secondsLeft <= 5 ? Colors.red : Colors.white),
        ),
        const Icon(Icons.timer_outlined, color: Colors.black, size: 48),
        const SizedBox(height: 30),
        _buildButton("Done", (isGameOver || isPaused) ? () {} : _checkWin),
      ],
    );
  }

  Widget _buildGrid(List<int> gridData, bool isInteractive, String label, _DifficultyConfig config) {
    double boxSize = 260 / max(config.rows, config.cols);
    if (boxSize > 60) boxSize = 60;

    return Column(
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
                        ? () => setState(() {
                              userPattern[index] = (userPattern[index] + 1) % config.colors;
                            })
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
      case 0: return Colors.white;
      case 1: return Colors.red;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.yellow;
      case 5: return Colors.orange;
      case 6: return Colors.purple;
      case 7: return Colors.pink;
      default: return Colors.white;
    }
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
