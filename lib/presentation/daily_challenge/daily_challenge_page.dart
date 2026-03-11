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
  List<int> userGrid = List.filled(25, 0);
  int _secondsLeft = 30;
  Timer? _timer;
  bool _isGameOver = false;

  final String rewardColorHex = "#98EE99"; 

  // Multi-color Map: 0:White, 1:Orange, 2:Blue, 3:Green
  final List<Color> colorMap = [
    Colors.white,
    Colors.orange,
    Colors.blueAccent,
    Colors.greenAccent,
  ];

  // High Difficulty Pattern (Using color IDs 0-3)
  final List<int> targetPattern = [
    0, 1, 1, 1, 0,
    1, 2, 0, 2, 1,
    1, 0, 0, 0, 1,
    1, 3, 3, 3, 1,
    0, 1, 1, 1, 0
  ];

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

  void _onTileTap(int index) {
    if (_isGameOver) return;
    setState(() {
      userGrid[index] = (userGrid[index] + 1) % 4; // Cycles through 4 colors
    });
  }

  Future<void> _notifyBackendWin() async {
    try {
      // Replace '1' with your global logged-in user_id
      await http.put(Uri.parse('http://127.0.0.1:8000/complete-challenge/1?reward_color=$rewardColorHex'));
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  void _checkWin() {
    bool isMatch = true;
    for (int i = 0; i < 25; i++) {
      if (userGrid[i] != targetPattern[i]) {
        isMatch = false;
        break;
      }
    }

    if (isMatch) {
      _timer?.cancel();
      _notifyBackendWin();
      _showResultDialog(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Colors don't match!"), duration: Duration(milliseconds: 400)),
      );
    }
  }

  void _showResultDialog(bool won) {
    setState(() => _isGameOver = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFB2B9D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(width: 3)),
        title: Text(won ? "WINNER!" : "FAILED", style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        content: Text(
          won ? "You unlocked a new background theme!" : "The 30s limit reached. Try tomorrow!",
          style: GoogleFonts.pixelifySans(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("BACK TO MENU", style: GoogleFonts.pixelifySans(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF8E8E8E), Color(0xFF636363)]),
        ),
        child: Stack(
          children: [
            Positioned(top: 20, left: 20, child: _buildBtn("Quit", () => Navigator.pop(context))),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _gridLabel("TARGET", _grid(targetPattern, false)),
                  _timerUI(),
                  _gridLabel("YOUR GRID", _grid(userGrid, true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridLabel(String txt, Widget grid) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [Text(txt, style: GoogleFonts.pixelifySans(color: Colors.white)), const SizedBox(height: 10), grid],
  );

  Widget _timerUI() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text("00:${_secondsLeft.toString().padLeft(2, '0')}", style: GoogleFonts.pixelifySans(fontSize: 30, color: _secondsLeft < 6 ? Colors.red : Colors.white)),
      const Icon(Icons.timer, size: 40),
      const SizedBox(height: 20),
      _buildBtn("DONE", _checkWin),
    ],
  );

  Widget _grid(List<int> data, bool interactive) => SizedBox(
    width: 250, height: 250,
    child: GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: 25,
      itemBuilder: (c, i) => GestureDetector(
        onTap: interactive ? () => _onTileTap(i) : null,
        child: Container(
          decoration: BoxDecoration(color: colorMap[data[i]], border: Border.all(width: 2), borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ),
  );

  Widget _buildBtn(String t, VoidCallback fn) => ElevatedButton(
    onPressed: fn,
    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 2)),
    child: Text(t, style: GoogleFonts.pixelifySans(color: Colors.black)),
  );
}