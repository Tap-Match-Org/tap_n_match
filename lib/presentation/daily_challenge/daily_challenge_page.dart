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

  List<int> userGrid = List.filled(25, 0);
  int _secondsLeft = 20;
  Timer? _timer;
  bool _isGameOver = false;

  late String rewardColorHex;
  late List<int> targetPattern;
  late String rewardName;

  // Configuration for the 7 newbie days
  final List<Map<String, dynamic>> newbieDaysConfig = [
    {
      "color": "#98EE99", "name": "Mint",
      "pattern": [
        1, 1, 1, 1, 1,
        1, 0, 0, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 1,
      ]
    }, // Day 1
    {
      "color": "#2E1A47", "name": "Amethyst",
      "pattern": [
        0, 1, 0, 1, 0,
        1, 1, 1, 1, 1,
        1, 1, 1, 1, 1,
        0, 1, 1, 1, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 2 (Heart)
    {
      "color": "#1A3A5F", "name": "Ocean",
      "pattern": [
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        1, 0, 0, 0, 1,
      ]
    }, // Day 3 (X)
    {
      "color": "#FFA500", "name": "Orange",
      "pattern": [
        0, 0, 1, 0, 0,
        0, 1, 1, 1, 0,
        1, 1, 1, 1, 1,
        0, 1, 1, 1, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 4 (Diamond)
    {
      "color": "#FFC0CB", "name": "Pink",
      "pattern": [
        1, 1, 1, 1, 1,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
      ]
    }, // Day 5 (T)
    {
      "color": "#00FF00", "name": "Lime",
      "pattern": [
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 1, 1, 1, 1,
      ]
    }, // Day 6 (L)
    {
      "color": "#00FFFF", "name": "Cyan",
      "pattern": [
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0
      ]
    }, // Day 7 (Robot/Circle)
  ];

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
  }

  void _setupChallenge() {
    if (isNewbie) {
      int index = (userStreak - 1).clamp(0, 6);
      rewardColorHex = newbieDaysConfig[index]["color"];
      rewardName = newbieDaysConfig[index]["name"];
      targetPattern = newbieDaysConfig[index]["pattern"];
    } else {
      // Weekly challenge behavior
      rewardColorHex = "#FFD700"; // Gold
      rewardName = "Gold";
      targetPattern = newbieDaysConfig[0]["pattern"]; // Example fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
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
      await _unlockColorInBackend();
      _showResultDialog(true);
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
    final url = Uri.parse('http://127.0.0.1:8000/complete-challenge/$userId?reward_color=$encodedColor');

    try {
      final response = await http.put(url);
      if (response.statusCode == 200) {
        debugPrint("Success: Backend updated theme.");
      } else {
        debugPrint("Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
    }
  }

  void _showResultDialog(bool won) {
    setState(() => _isGameOver = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 3), // FIXED: 'side' instead of 'border'
        ),
        title: Text(
          won ? "NEW COLOR UNLOCKED!" : "TIME'S UP!",
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won) ...[
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8E8E8E), Color(0xFF636363)],
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
                    ? () => setState(() =>
                        userGrid[index] = userGrid[index] == 0 ? 1 : 0)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: gridData[index] == 1 ? Colors.orange : Colors.white,
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
}