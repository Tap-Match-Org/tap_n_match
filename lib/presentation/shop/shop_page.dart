import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int userId = 1;
  int bankedPoints = 0;
  String selectedTheme = "#A9A9A9";
  List<String> unlockedThemes = [];
  List<String> unlockedTapSounds = [];
  List<String> unlockedBgMusic = [];
  bool isLoading = true;
  bool _didInitialize = false;
  int activeTab = 0; // 0: Themes, 1: Backgrounds, 2: Tap Sounds, 3: Music

  final List<Map<String, dynamic>> themeItems = [
    {"id": "#50C878", "name": "Emerald", "price": 500, "type": "theme"},
    {"id": "#87CEEB", "name": "Sky Blue", "price": 300, "type": "theme"},
    {"id": "#800000", "name": "Maroon", "price": 400, "type": "theme"},
    {"id": "#FFD700", "name": "Gold", "price": 1000, "type": "theme"},
    {"id": "#FF69B4", "name": "Hot Pink", "price": 600, "type": "theme"},
    {"id": "#4B0082", "name": "Indigo", "price": 700, "type": "theme"},
  ];

  final List<Map<String, dynamic>> backgroundItems = [
    {"id": "asset:assets/background/minecraft_bgColor.jpg", "name": "MC Grass", "price": 1500, "type": "theme"},
    {"id": "asset:assets/background/genshin_background.jpeg", "name": "Genshin", "price": 2000, "type": "theme"},
    {"id": "asset:assets/background/harvest_moon_background.jpeg", "name": "Harvest", "price": 1800, "type": "theme"},
    {"id": "asset:assets/background/snowfall_background.jpeg", "name": "Snowfall", "price": 2500, "type": "theme"},
  ];

  final List<Map<String, dynamic>> tapSoundItems = [
    {"id": "audio/tap_sounds/minecraft_tap_sound.mp3", "name": "MC Tap", "price": 800, "type": "tap_sound"},
    {"id": "audio/tap_sounds/genshin_tap_sound.mp3", "name": "Genshin", "price": 1200, "type": "tap_sound"},
    {"id": "audio/tap_sounds/snowfall_tap_sound.mp3", "name": "Snowfall", "price": 1500, "type": "tap_sound"},
  ];

  final List<Map<String, dynamic>> musicItems = [
    {"id": "audio/background_music/minecraft_bgMusic.mp3", "name": "MC Theme", "price": 2000, "type": "bg_music"},
    {"id": "audio/background_music/genshin_bgMusic.mp3", "name": "Genshin", "price": 3000, "type": "bg_music"},
    {"id": "audio/background_music/harvest_moon_bgMusic.mp3", "name": "Harvest", "price": 2500, "type": "bg_music"},
    {"id": "audio/background_music/snowfall_bgMusic.mp3", "name": "Snowfall", "price": 3500, "type": "bg_music"},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            bankedPoints = data['banked_points'] ?? 0;
            selectedTheme = data['selected_theme'] ?? "#A9A9A9";
            unlockedThemes = List<String>.from(data['unlocked_themes'] ?? []);
            unlockedTapSounds = List<String>.from(data['unlocked_tap_sounds'] ?? []);
            unlockedBgMusic = List<String>.from(data['unlocked_bg_music'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading shop data: $e');
    }
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    if (bankedPoints < item['price']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points!', style: GoogleFonts.pixelifySans()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/buy-item/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': item['id'],
          'item_type': item['type'],
          'price': item['price'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bankedPoints = data['banked_points'];
          if (item['type'] == 'theme') {
            unlockedThemes.add(item['id']);
          } else if (item['type'] == 'tap_sound') {
            unlockedTapSounds.add(item['id']);
          } else if (item['type'] == 'bg_music') {
            unlockedBgMusic.add(item['id']);
          }
        });
        soundManager.playTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked ${item['name']}!', style: GoogleFonts.pixelifySans()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = jsonDecode(response.body)['detail'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.pixelifySans()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error buying item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
        child: Stack(
          children: [
            // BACK BUTTON
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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

            // MAIN SHOP PANEL
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: isLandscape ? MediaQuery.of(context).size.height * 0.85 : 620,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  children: [
                    // HEADER ROW (Point balance moved inside header)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAEC6FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()), // Spacer
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Point Shop',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFCA016),
                                shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)],
                              ),
                            ),
                          ),
                          // BALANCE DISPLAY INSIDE HEADER
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      bankedPoints.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.pixelifySans(
                                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TAB SELECTOR (4 TABS)
                    Container(
                      color: const Color(0xFFBBD5FF),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 10),
                            _buildTabButton('Themes', 0),
                            const SizedBox(width: 10),
                            _buildTabButton('BGs', 1),
                            const SizedBox(width: 10),
                            _buildTabButton('Taps', 2),
                            const SizedBox(width: 10),
                            _buildTabButton('Music', 3),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ),

                    // SHOP CONTENT
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                              padding: const EdgeInsets.all(12),
                              child: _buildItemGrid(_getCurrentItems()),
                            ),
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

  List<Map<String, dynamic>> _getCurrentItems() {
    switch (activeTab) {
      case 0: return themeItems;
      case 1: return backgroundItems;
      case 2: return tapSoundItems;
      case 3: return musicItems;
      default: return themeItems;
    }
  }

  Widget _buildTabButton(String label, int index) {
    bool isActive = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFCA016) : Colors.white70,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.pixelifySans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildItemGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isUnlocked;
        if (item['type'] == 'theme') {
          isUnlocked = unlockedThemes.contains(item['id']);
        } else if (item['type'] == 'tap_sound') {
          isUnlocked = unlockedTapSounds.contains(item['id']);
        } else {
          isUnlocked = unlockedBgMusic.contains(item['id']);
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildItemPreview(item),
              const SizedBox(height: 5),
              Text(
                item['name'],
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              const SizedBox(height: 5),
              isUnlocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(6)),
                      child: Text('OWNED', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 8)),
                    )
                  : GestureDetector(
                      onTap: () => _buyItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCA016),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars, size: 9, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              item['price'].toString(),
                              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemPreview(Map<String, dynamic> item) {
    if (item['type'] == 'theme') {
      final id = item['id'] as String;
      if (id.startsWith('asset:')) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black54),
            image: DecorationImage(image: AssetImage(id.replaceFirst('asset:', '')), fit: BoxFit.cover),
          ),
        );
      } else {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(int.parse(id.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black54),
          ),
        );
      }
    } else if (item['type'] == 'tap_sound') {
      return const Icon(Icons.touch_app_rounded, size: 35, color: Color(0xFFAEC6FF));
    } else {
      return const Icon(Icons.music_note_rounded, size: 35, color: Color(0xFF2FBF71));
    }
  }
}
