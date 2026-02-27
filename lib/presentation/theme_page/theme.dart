import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF606060),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('SELECT THEME', style: GoogleFonts.pixelifySans(color: Colors.white)),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        children: [
          _themeOption("Classic Purple", Colors.purple),
          _themeOption("Retro Grey", Colors.grey),
          _themeOption("Neon Night", Colors.black),
          _themeOption("Forest", Colors.green),
        ],
      ),
    );
  }

  Widget _themeOption(String name, Color color) {
    return Card(
      color: color,
      child: Center(
        child: Text(name, 
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}