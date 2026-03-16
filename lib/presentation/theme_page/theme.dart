import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  int userId = 1; // Default fallback
  List<String> unlockedColors = ["#A9A9A9"];
  bool isLoading = true;

  final Map<String, String> colorNames = {
    "#A9A9A9": "Default",
    "#98EE99": "Mint",
    "#2E1A47": "Amethyst",
    "#1A3A5F": "Ocean",
    "#FFA500": "Orange",
    "#FFC0CB": "Pink",
    "#00FF00": "Lime",
    "#00FFFF": "Cyan",
    "#FFD700": "Gold", 
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _fetchUnlockedThemes();
  }

  Future<void> _fetchUnlockedThemes() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String themesString = data['unlocked_themes'] ?? "";
        setState(() {
          unlockedColors = themesString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.center, radius: 1.2, colors: [Color(0xFFB0B0B0), Color(0xFF606060)]),
        ),
        child: Stack(
          children: [
            Positioned(left: 20, top: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: _buildIconButton(Icons.arrow_back_ios_new))),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 65, bottom: 45),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (isLoading)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: Row(
                            children: [
                              _buildThemeColumn("Background", const Color(0xFFAEC6FF), unlockedColors.map((hex) => _themeItem(hex)).toList()),
                              const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                              _buildThemeColumn("Tap Sound", const Color(0xFFFFF9B0), []),
                              const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                              _buildThemeColumn("Music", const Color(0xFFB4FF91), []),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFE59A5A), borderRadius: BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)), border: Border(bottom: BorderSide(color: Colors.black, width: 3))),
      child: Text('THEMES', textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFE08CF4), shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)])),
    );
  }

  Widget _buildThemeColumn(String title, Color headerColor, List<Widget> items) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: headerColor.withOpacity(0.3), border: const Border(bottom: BorderSide(color: Colors.black, width: 2))),
            child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(child: items.isEmpty ? Center(child: Text("None", style: GoogleFonts.pixelifySans(color: Colors.grey, fontSize: 12))) : ListView(padding: const EdgeInsets.all(8), children: items)),
        ],
      ),
    );
  }

  Widget _themeItem(String hexCode) {
    Color itemColor = Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    return Container(
      margin: const EdgeInsets.only(bottom: 8), height: 45,
      decoration: BoxDecoration(color: itemColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 1.5)),
      child: Center(child: Text(colorNames[hexCode] ?? "Unknown", style: GoogleFonts.pixelifySans(fontSize: 14, color: itemColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Icon(icon, color: Colors.black, size: 22));
  }
}
