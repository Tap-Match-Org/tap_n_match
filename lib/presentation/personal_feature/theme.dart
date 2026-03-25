import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/infrastructure/soundmanager.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  int userId = 1; // Default fallback
  List<String> unlockedColors = ["#A9A9A9"];
  String selectedTheme = "#A9A9A9";
  bool isLoading = true;

  String selectedSound = "Default";
  List<String> unlockedSounds = ["Default"];

  String selectedMusic = "Default";
  List<String> unlockedMusic = ["Default"];

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
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String themesString = data['unlocked_themes'] ?? "";
        setState(() {
          unlockedColors = themesString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (!unlockedColors.contains("#A9A9A9")) {
            unlockedColors.insert(0, "#A9A9A9");
          }
          selectedTheme = data['selected_theme'] ?? "#A9A9A9";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectTheme(String hex) async {
    try {
      final response = await http.put(Uri.parse('http://localhost:8000/select-theme/$userId?theme_color=${Uri.encodeComponent(hex)}'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => selectedTheme = hex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Theme changed to ${colorNames[hex] ?? hex}!")),
        );
      }
    } catch (e) {
      debugPrint("Error selecting theme: $e");
    }
  }

  Future<void> _selectSound(String soundName) async {
    // For now, only "Default" is available. In the future, this can be synced with backend.
    if (soundName == "Default") {
      await soundManager.playTap();
    }
    if (!mounted) return;
    setState(() => selectedSound = soundName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tap Sound changed to $soundName!")),
    );
  }

  Future<void> _selectMusic(String musicName) async {
    // For now, only "Default" is available. In the future, this can be synced with backend.
    if (musicName == "Default") {
      await soundManager.setSelectedBgMusic('audio/background_music/default_bgMusic.mp3');
    }
    if (!mounted) return;
    setState(() => selectedMusic = musicName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Music changed to $musicName!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Color(int.parse(selectedTheme.replaceFirst('#', '0xFF')));
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              themeColor.withOpacity(0.8),
              themeColor.withOpacity(0.4),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(left: 20, top: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: _buildIconButton(Icons.arrow_back_ios_new))),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 65, bottom: 45),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(color: const Color(0xFFD9D9D9).withOpacity(0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
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
                              _buildThemeColumn("Tap Sound", const Color(0xFFFFF9B0), unlockedSounds.map((name) => _soundItem(name)).toList()),
                              const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                              _buildThemeColumn("Music", const Color(0xFFB4FF91), unlockedMusic.map((name) => _musicItem(name)).toList()),
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
    bool isSelected = selectedTheme == hexCode;
    String name = colorNames[hexCode] ?? hexCode;
    
    // Check luminance to decide if text should be white or black for readability
    bool useWhiteText = itemColor.computeLuminance() < 0.4 || isSelected;

    return GestureDetector(
      onTap: () => _selectTheme(hexCode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), height: 45,
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? Colors.white : Colors.black, width: isSelected ? 3 : 1.5),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
        ),
        child: Center(
          child: Text(
            isSelected ? "$name (ACTIVE)" : name,
            style: GoogleFonts.pixelifySans(
              color: useWhiteText ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold
            )
          )
        ),
      ),
    );
  }

  Widget _soundItem(String name) {
    bool isSelected = selectedSound == name;
    return GestureDetector(
      onTap: () => _selectSound(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9B0), 
          borderRadius: BorderRadius.circular(6), 
          border: Border.all(color: isSelected ? Colors.white : Colors.black, width: isSelected ? 3 : 1.5),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
        ),
        child: Center(
          child: Text(
            name, 
            style: GoogleFonts.pixelifySans(
              fontSize: 14, 
              color: Colors.black, 
              fontWeight: FontWeight.bold
            )
          )
        ),
      ),
    );
  }

  Widget _musicItem(String name) {
    bool isSelected = selectedMusic == name;
    return GestureDetector(
      onTap: () => _selectMusic(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFB4FF91), 
          borderRadius: BorderRadius.circular(6), 
          border: Border.all(color: isSelected ? Colors.white : Colors.black, width: isSelected ? 3 : 1.5),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
        ),
        child: Center(
          child: Text(
            name, 
            style: GoogleFonts.pixelifySans(
              fontSize: 14, 
              color: Colors.black, 
              fontWeight: FontWeight.bold
            )
          )
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Icon(icon, color: Colors.black, size: 22));
  }
}
