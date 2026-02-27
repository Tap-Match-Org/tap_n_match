import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
              radius: 1.0,
              center: Alignment(0, -0.2),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoGrid(context),
                  const SizedBox(height: 20),
                  _buildOutlinedText('Tap & Match', 55, const Color(0xFFFCA016)),
                  const SizedBox(height: 8),
                  _buildOutlinedText('The Color Game', 20, const Color(0xFF20DEFF)),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 150.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('100%', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to play',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ],
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
    double sq = MediaQuery.of(context).size.height * 0.12;
    sq = sq.clamp(35.0, 55.0);
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
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }
}