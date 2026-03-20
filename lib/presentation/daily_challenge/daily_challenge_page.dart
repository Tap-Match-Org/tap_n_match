import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> {
  int userId = 1; // Default fallback
  bool isNewbie = true;
  int userStreak = 1;
  String selectedTheme = "#A9A9A9";

  List<int> userGrid = List.filled(25, 0);
  int _secondsLeft = 20;
  Timer? _timer;
  bool _isGameOver = false;
  bool _rewardClaimed = false;

  late String rewardColorHex;
  late List<int> targetPattern;
  late String rewardName;
  late int timeLimit;

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

  @override
  void initState() {
    super.initState();
    // We'll start the timer after checking attempts
  }

  bool _isCheckingAttempts = true;
  bool _hasCheckedAttempts = false;

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
          // Fetch user info to get the current selected theme
          final userResponse = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            if (mounted) {
              setState(() {
                _isCheckingAttempts = false;
                selectedTheme = userData['selected_theme'] ?? "#A9A9A9";
              });
              _startTimer();
            }
          } else {
            if (mounted) {
              setState(() => _isCheckingAttempts = false);
              _startTimer();
            }
          }
        }
      } else {
        // Fallback if backend fails
        if (mounted) {
          setState(() => _isCheckingAttempts = false);
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint("Error checking attempts: $e");
      if (mounted) {
        setState(() => _isCheckingAttempts = false);
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
          "You can only play the daily challenge twice a day. Try again tomorrow!",
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
      isNewbie = args['isNewbie'] ?? true;
      userStreak = args['streak'] ?? 1;
      if (args.containsKey('user_id')) {
        userId = args['user_id'];
      }
    }

    _setupChallenge();
    _checkAndRecordAttempt();
  }

  void _setupChallenge() {
    int index;
    if (isNewbie) {
      index = (userStreak == 0 ? 0 : (userStreak - 1)).clamp(0, 6);
    } else {
      // Rotation based on day of week for non-newbies
      index = (DateTime.now().weekday - 1).clamp(0, 6);
    }
    
    rewardColorHex = newbieDaysConfig[index]["color"];
    rewardName = newbieDaysConfig[index]["name"];
    targetPattern = newbieDaysConfig[index]["pattern"];
    timeLimit = newbieDaysConfig[index]["time"];
    _secondsLeft = timeLimit;
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pattern doesn't match!"),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
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

  void _showResultDialog(bool won, {bool alreadyClaimed = false}) {
    setState(() => _isGameOver = true);
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
                  color: Color(int.parse(rewardColorHex.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.palette, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 15),
              Text("$rewardName theme unlocked!", style: GoogleFonts.pixelifySans()),
            ] else if (alreadyClaimed) ...[
              Text("You already claimed this reward!", style: GoogleFonts.pixelifySans()),
              const SizedBox(height: 10),
              Text("Check your themes page.", style: GoogleFonts.pixelifySans()),
            ] else
              Text(isNewbie ? "Try again tomorrow!" : "Try again next week!", 
                   style: GoogleFonts.pixelifySans()),
          ],
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
  Widget build(BuildContext context) {
    Color themeColor = Color(int.parse(selectedTheme.replaceFirst('#', '0xFF')));
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.withOpacity(0.8),
              themeColor.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
                    ? () => setState(() {
                        userGrid[index] = (userGrid[index] + 1) % 5; // Cycle through 0-4
                      })
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForValue(gridData[index]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
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
}