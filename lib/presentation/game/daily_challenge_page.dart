import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  int userId = 1; // Default fallback
  bool isNewbie = true;
  int userStreak = 0;
  int completedChallenges = 0;
  String selectedTheme = "#A9A9A9";

  List<int> userGrid = List.filled(25, 0);
  int _secondsLeft = 20;
  Timer? _timer;
  Timer? _topSnackBarTimer;
  OverlayEntry? _topSnackBarEntry;
  late final AnimationController _topSnackBarController;
  String _topSnackBarMessage = "";
  bool _isGameOver = false;
  bool _rewardClaimed = false;

  late String rewardColorHex;
  late List<int> targetPattern;
  late String rewardName;
  late int timeLimit;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _topSnackBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
  }

  // Configuration for the 7 newbie days with 4+ colors
  final List<Map<String, dynamic>> newbieDaysConfig = [
    {
      "color": "#98EE99", "name": "Mint", "time": 20,
      "pattern": [
        1, 2, 1, 2, 1,
        2, 0, 0, 0, 2,
        1, 0, 3, 0, 1,
        2, 0, 0, 0, 2,
        1, 2, 1, 2, 1,
      ]
    }, // Day 1 - Border pattern (4 colors)
    {
      "color": "#2E1A47", "name": "Amethyst", "time": 25,
      "pattern": [
        0, 1, 0, 1, 0,
        1, 2, 1, 2, 1,
        1, 1, 3, 1, 1,
        0, 1, 2, 1, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 2 - Heart (4 colors)
    {
      "color": "#1A3A5F", "name": "Ocean", "time": 20,
      "pattern": [
        1, 0, 2, 0, 1,
        0, 3, 0, 3, 0,
        2, 0, 1, 0, 2,
        0, 3, 0, 3, 0,
        1, 0, 2, 0, 1,
      ]
    }, // Day 3 - Diamond cross (4 colors)
    {
      "color": "#FFA500", "name": "Orange", "time": 25,
      "pattern": [
        0, 0, 1, 0, 0,
        0, 2, 3, 2, 0,
        1, 3, 4, 3, 1,
        0, 2, 3, 2, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 4 - Diamond (5 colors)
    {
      "color": "#FFC0CB", "name": "Pink", "time": 20,
      "pattern": [
        1, 2, 3, 2, 1,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 5 - T with colors (4 colors)
    {
      "color": "#00FF00", "name": "Lime", "time": 25,
      "pattern": [
        1, 0, 0, 0, 0,
        2, 0, 0, 0, 0,
        3, 0, 0, 0, 0,
        4, 0, 0, 0, 0,
        1, 2, 3, 4, 1,
      ]
    }, // Day 6 - L with rainbow (5 colors)
    {
      "color": "#00FFFF", "name": "Cyan", "time": 25,
      "pattern": [
        0, 1, 2, 1, 0,
        1, 0, 0, 0, 1,
        2, 0, 3, 0, 2,
        1, 0, 0, 0, 1,
        0, 1, 2, 1, 0
      ]
    }, // Day 7 - Frame (4 colors)
  ];

  final List<Map<String, dynamic>> weeklyChallengesConfig = [
    {
      "name": "Harvest Moon",
      "time": 30,
      "pattern": [
        1, 2, 3, 4, 1,
        2, 3, 4, 1, 2,
        3, 4, 0, 2, 3,
        4, 1, 2, 3, 4,
        1, 2, 3, 4, 1,
      ],
      "tapSound": "audio/tap_sounds/harvest_moon _tapSound.mp3",
      "background": "asset:assets/background/harvest_moon_background.jpeg",
      "reward": "asset:assets/background/harvest_moon_background.jpeg",
    },
    {
      "name": "Genshin",
      "time": 35,
      "pattern": [
        1, 1, 2, 2, 3,
        1, 4, 4, 3, 3,
        2, 4, 0, 4, 2,
        3, 3, 4, 4, 1,
        3, 2, 2, 1, 1,
      ],
      "reward": "asset:assets/background/genshin_background.jpeg",
    }
  ];

  bool _hasCheckedAttempts = false;
  int _attempts = 0;

  Future<void> _checkAndRecordAttempt() async {
    if (_hasCheckedAttempts) return;
    _hasCheckedAttempts = true;
    try {
      final response = await http.post(Uri.parse('http://localhost:8000/record-attempt/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'limit_reached') {
          if (mounted) {
            _showLimitReachedDialog();
          }
        } else {
          // Store attempts from backend
          if (mounted) {
            setState(() {
              _attempts = data['attempts'] ?? 0;
            });
          }
          
          // Fetch user info to get the current selected theme
          final userResponse = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
              if (mounted) {
                setState(() {
                  selectedTheme = userData['selected_theme'] ?? "#A9A9A9";
                });
              _startTimer();
            }
          } else {
        if (mounted) {
          _startTimer();
        }
      }
        }
      } else {
        // Fallback if backend fails
        if (mounted) {
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint("Error checking attempts: $e");
      if (mounted) {
        _startTimer();
      }
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          "LIMIT REACHED",
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "You have no attempts left, comeback tomorrow for the next challenge",
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(),
        ),
        actions: [
          Center(
            child: _buildButton("Back to Menu", () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Exit Challenge Page
            }),
          )
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      userStreak = args['streak'] ?? 0;
      completedChallenges = args['completedChallenges'] ?? 0;
      // Re-calculate isNewbie to ensure consistency
      isNewbie = completedChallenges < 7;
      
      if (args.containsKey('user_id')) {
        userId = args['user_id'];
      }
    }

    _setupChallenge();
    _checkAndRecordAttempt();
  }

  String _challengeBackground = "";

  void _setupChallenge() {
    Map<String, dynamic> config;
    if (isNewbie) {
      int index = completedChallenges.clamp(0, 6);
      config = newbieDaysConfig[index];
    } else {
      // Weekly challenges for veterans
      // After Day 7, cycle through the veteran rewards daily
      int veteranDay = completedChallenges - 7;
      int rewardIndex = veteranDay % weeklyChallengesConfig.length;
      config = weeklyChallengesConfig[rewardIndex];
      
      // Apply weekly challenge specific assets
      if (config.containsKey("tapSound")) {
        soundManager.setSelectedTapSound(config["tapSound"]);
      }
      if (config.containsKey("background")) {
        _challengeBackground = config["background"];
      }
    }
    
    rewardColorHex = config["reward"] ?? config["color"];
    rewardName = config["name"];
    targetPattern = config["pattern"];
    timeLimit = config["time"];
    _secondsLeft = timeLimit;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    _topSnackBarTimer?.cancel();
    _topSnackBarEntry?.remove();
    _topSnackBarController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _showResultDialog(false);
      }
    });
  }

  void _checkWin() async {
    bool isMatch = true;
    for (int i = 0; i < 25; i++) {
      if (userGrid[i] != targetPattern[i]) {
        isMatch = false;
        break;
      }
    }

    if (isMatch) {
      _timer?.cancel();
      
      // Check if reward already claimed
      if (_rewardClaimed) {
        _showResultDialog(true, alreadyClaimed: true);
        return;
      }
      
      await _unlockColorInBackend();
    } else {
      _showTopSnackBar("Pattern doesn't match!");
    }
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

  Future<void> _unlockColorInBackend() async {
    // IMPORTANT: Encode the '#' in the hex code for the URL
    final String encodedColor = Uri.encodeComponent(rewardColorHex);
    final url = Uri.parse('http://localhost:8000/complete-challenge/$userId?reward_color=$encodedColor');

    try {
      final response = await http.put(url);
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Backend response: $data");
        
        if (data['status'] == 'already_played') {
          _showResultDialog(true, alreadyClaimed: true);
          return; // Don't set rewardClaimed to true
        } else {
          debugPrint("Success: Backend updated theme.");
          // Only set rewardClaimed and show success if backend actually succeeded
          if (mounted) {
            setState(() => _rewardClaimed = true);
            _showResultDialog(true);
          }
        }
      } else {
        debugPrint("Failed: ${response.statusCode}");
        // Don't set rewardClaimed on error
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      // Don't set rewardClaimed on connection error
    }
  }

  void _resetChallenge() {
    setState(() {
      userGrid = List.filled(25, 0);
      _secondsLeft = timeLimit;
      _isGameOver = false;
      _hasCheckedAttempts = false; 
    });
    _checkAndRecordAttempt();
  }

  void _showResultDialog(bool won, {bool alreadyClaimed = false}) {
    setState(() => _isGameOver = true);
    
    if (won) {
      _confettiController.play();
    }

    String failureMessage = "Try again next week!";
    bool canRetry = false;
    if (!won && !alreadyClaimed) {
      if (_attempts == 1) {
        failureMessage = "You have 1 attempt left";
        canRetry = true;
      } else if (_attempts >= 2) {
        failureMessage = "You have no attempts left, comeback tomorrow for the next challenge";
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text(
          alreadyClaimed ? "REWARD ALREADY CLAIMED!" : (won ? "NEW COLOR UNLOCKED!" : "TIME'S UP!"),
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won && !alreadyClaimed) ...[
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: rewardColorHex.startsWith('#')
                      ? Color(int.parse(rewardColorHex.replaceFirst('#', '0xFF')))
                      : Colors.grey[300],
                  image: rewardColorHex.startsWith('asset:')
                      ? DecorationImage(
                          image: AssetImage(rewardColorHex.substring(6)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: rewardColorHex.startsWith('#')
                    ? const Icon(Icons.palette, color: Colors.white, size: 40)
                    : null,
              ),
              const SizedBox(height: 15),
              Text("$rewardName theme unlocked!", style: GoogleFonts.pixelifySans()),
            ]
 else if (alreadyClaimed) ...[
              const Icon(Icons.info_outline, color: Colors.blue, size: 60),
              const SizedBox(height: 15),
              Text("You already claimed this reward!", style: GoogleFonts.pixelifySans()),
              const SizedBox(height: 10),
              Text("Check your themes page.", style: GoogleFonts.pixelifySans()),
            ] else ...[
              const Icon(Icons.timer_off, color: Colors.redAccent, size: 60),
              const SizedBox(height: 15),
              Text(failureMessage, 
                   textAlign: TextAlign.center,
                   style: GoogleFonts.pixelifySans()),
            ],
          ],
        ),
        actions: [
          Center(
            child: Column(
              children: [
                if (canRetry) ...[
                  _buildButton("Retry", () {
                    Navigator.pop(context); // Close Dialog
                    _resetChallenge();
                  }),
                  const SizedBox(height: 10),
                ],
                _buildButton("Back to Menu", () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Exit Challenge Page
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: buildThemeDecoration(
          _challengeBackground.isNotEmpty ? _challengeBackground : selectedTheme,
          radial: false,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          opacityStart: 0.8,
          opacityEnd: 0.5,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 20,
              child: _buildButton("Quit", () => Navigator.pop(context)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGrid(targetPattern, false, "Target"),
                  _buildCenterUI(),
                  _buildGrid(userGrid, !_isGameOver, "Your Grid"),
                ],
              ),
            ),
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
    );
  }

  Widget _buildCenterUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "00:${_secondsLeft.toString().padLeft(2, '0')}",
          style: GoogleFonts.pixelifySans(
              fontSize: 32,
              color: _secondsLeft <= 5 ? Colors.red : Colors.white),
        ),
        const Icon(Icons.timer_outlined, color: Colors.black, size: 48),
        const SizedBox(height: 30),
        _buildButton("Done", _isGameOver ? () {} : _checkWin),
      ],
    );
  }

  Widget _buildGrid(List<int> gridData, bool isInteractive, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.pixelifySans(color: Colors.white70)),
        const SizedBox(height: 10),
        SizedBox(
          width: 260,
          height: 260,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 25,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: isInteractive
                    ? () {
                        soundManager.playTap();
                        setState(() {
                          userGrid[index] = (userGrid[index] + 1) % 5; // Cycle through 0-4
                        });
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForValue(gridData[index]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: soundManager.colorblindMode
                      ? Center(
                          child: Icon(
                            _getSymbolForValue(gridData[index]),
                            size: 20,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        )
                      : null,
                ),
              );
            },
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

  // Color mapping for values 0-4
  Color _getColorForValue(int value) {
    switch (value) {
      case 0: return Colors.white;
      case 1: return Colors.red;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.yellow;
      default: return Colors.white;
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
      default:
        return null;
    }
  }

  Path _drawStar(Size size) {
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
