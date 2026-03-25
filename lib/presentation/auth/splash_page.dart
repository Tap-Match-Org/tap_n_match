import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/infrastructure/soundmanager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  void _goToLogin() {
    if (mounted) {
      soundManager.playBgMusic();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = screenWidth > screenHeight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goToLogin,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
              radius: 1.0,
              center: Alignment(0, -0.2),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoGrid(context),
                    SizedBox(height: isLandscape ? screenHeight * 0.04 : 20),
                    _buildOutlinedText('Tap & Match', isLandscape ? 45 : 55, const Color(0xFFFCA016)),
                    const SizedBox(height: 4),
                    _buildOutlinedText('The Color Game', isLandscape ? 18 : 20, const Color(0xFF20DEFF)),
                    SizedBox(height: isLandscape ? screenHeight * 0.05 : 24),
                    
                    SizedBox(
                      width: isLandscape ? screenWidth * 0.4 : screenWidth * 0.7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 1.0,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    Text('100%', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 4),

                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: Text(
                        'Tap to play',
                        style: GoogleFonts.pixelifySans(
                          color: const Color.fromARGB(255, 172, 160, 160),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedText(String text, double size, Color fill) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: size,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: fill,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoGrid(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLandscape = screenWidth > screenHeight;
    double sq = isLandscape ? screenHeight * 0.10 : screenHeight * 0.12;
    sq = sq.clamp(30.0, 50.0);
    final List<Color> colors = [
      Colors.red, Colors.blue, Colors.greenAccent,
      Colors.yellow, Colors.white, Colors.yellow,
      Colors.greenAccent, Colors.red, Colors.blue,
    ];
    return SizedBox(
      width: (sq * 3) + 20,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (context, index) => Container(
          height: sq,
          width: sq,
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }
}
