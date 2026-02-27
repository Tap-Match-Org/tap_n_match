import 'package:flutter/material.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  int _score = 0;
  int _matches = 0;
  bool _gameStarted = false;

  final List<Color> _colors = [
    const Color(0xFFFF4444), // Red
    const Color(0xFF0000FF), // Blue
    const Color(0xFF00FF00), // Green
    const Color(0xFFFFFF00), // Yellow
    Colors.white,
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFF00FF00), // Green
    const Color(0xFFFF4444), // Red
    const Color(0xFF0000FF), // Blue
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD946EF),
              Color(0xFFD946EF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Color Grid
                _buildColorGrid(),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Tap & Match',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFDD00),
                    shadows: [
                      const Shadow(
                        offset: Offset(3, 3),
                        color: Colors.black87,
                        blurRadius: 0,
                      ),
                      const Shadow(
                        offset: Offset(2, 2),
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'The Color Game',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF90EE90),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // Progress Bar
                _buildProgressBar(),
                const SizedBox(height: 12),
                // Percentage
                Text(
                  '${(100 * _matches ~/ 9).clamp(0, 100)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Tap to Play Button
                GestureDetector(
                  onTap: _startGame,
                  child: ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Text(
                      'Tap to play',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Score Display
                if (_gameStarted)
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: _gameStarted
                ? () {
                    setState(() {
                      _score += 10;
                      _matches++;
                    });
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: _colors[index],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black87,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _gameStarted
                      ? () {
                          setState(() {
                            _score += 10;
                            _matches++;
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = (_matches / 9).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
