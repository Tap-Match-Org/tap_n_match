import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// THIS IMPORT IS REQUIRED TO FIX THE "METHOD NOT DEFINED" ERROR
import 'achievement_list.dart'; 

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFFB0B0B0), Color(0xFF606060)],
          ),
        ),
        child: Stack(
          children: [
            // BACK BUTTON
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                ),
              ),
            ),

            // MAIN PANEL
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: isLandscape ? MediaQuery.of(context).size.height * 0.85 : 550,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAEC6FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                      ),
                      child: Text(
                        'Achievements',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)],
                        ),
                      ),
                    ),
                    
                    // THE LIST CONTENT
                    // REMOVED 'const' HERE TO FIX THE "NOT A CONSTANT EXPRESSION" ERROR
                    const Expanded(
                      child: AchievementList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}