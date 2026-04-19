import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

class ShopPage extends StatefulWidget {
  final http.Client? httpClient;
  const ShopPage({super.key, this.httpClient});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final http.Client _client;
  late final bool _ownsClient;
  int userId = 1;
  int bankedPoints = 0;
  String selectedTheme = "#A9A9A9";
  List<String> unlockedThemes = [];
  List<String> unlockedTapSounds = [];
  List<String> unlockedBgMusic = [];
  bool isLoading = true;
  bool _didInitialize = false;
  int activeTab = 0; 

  final List<Map<String, dynamic>> themeItems = [
    {"id": "#50C878", "name": "Emerald", "price": 500, "type": "theme"},
    {"id": "#87CEEB", "name": "Sky Blue", "price": 300, "type": "theme"},
    {"id": "#800000", "name": "Maroon", "price": 400, "type": "theme"},
    {"id": "#FFD700", "name": "Gold", "price": 1000, "type": "theme"},
    {"id": "#FF69B4", "name": "Hot Pink", "price": 600, "type": "theme"},
    {"id": "#4B0082", "name": "Indigo", "price": 700, "type": "theme"},
  ];

  final List<Map<String, dynamic>> backgroundItems = [
    {"id": "asset:assets/background/minecraft_bgColor.jpg", "name": "Minecraft Grass", "price": 1500, "type": "theme"},
    {"id": "asset:assets/background/genshin_background.jpeg", "name": "Genshin", "price": 2000, "type": "theme"},
    {"id": "asset:assets/background/harvest_moon_background.jpeg", "name": "Harvest Moon", "price": 1800, "type": "theme"},
    {"id": "asset:assets/background/snowfall_background.jpeg", "name": "SnowFall", "price": 2500, "type": "theme"},
  ];

  final List<Map<String, dynamic>> tapSoundItems = [
    {"id": "audio/tap_sounds/minecraft_tap_sound.mp3", "name": "Minecraft Tap", "price": 800, "type": "tap_sound"},
    {"id": "audio/tap_sounds/genshin_tap_sound.mp3", "name": "Genshin", "price": 1200, "type": "tap_sound"},
    {"id": "audio/tap_sounds/snowfall_tap_sound.mp3", "name": "SnowFall", "price": 1500, "type": "tap_sound"},
  ];

  final List<Map<String, dynamic>> musicItems = [
    {"id": "audio/background_music/minecraft_bgMusic.mp3", "name": "Minecraft", "price": 2000, "type": "bg_music"},
    {"id": "audio/background_music/genshin_bgMusic.mp3", "name": "Genshin", "price": 3000, "type": "bg_music"},
    {"id": "audio/background_music/harvestMoon.mp3", "name": "Harvest Moon", "price": 2500, "type": "bg_music"},
    {"id": "audio/background_music/snowfall_bgMusic.mp3", "name": "Snowfall", "price": 3500, "type": "bg_music"},
  ];

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.httpClient == null;
    _client = widget.httpClient ?? http.Client();
  }

  ShopInventoryState get _inventoryState => ShopInventoryState(
        bankedPoints: bankedPoints,
        selectedTheme: selectedTheme,
        unlockedThemes: unlockedThemes,
        unlockedTapSounds: unlockedTapSounds,
        unlockedBgMusic: unlockedBgMusic,
      );

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
      final response = await _client.get(ApiConfig.getUri('/users/$userId'));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(
          jsonDecode(response.body) as Map,
        );
        final inventory = ShopInventoryState.fromUserData(data);
        if (mounted) {
          setState(() {
            bankedPoints = inventory.bankedPoints;
            selectedTheme = inventory.selectedTheme;
            unlockedThemes = inventory.unlockedThemes;
            unlockedTapSounds = inventory.unlockedTapSounds;
            unlockedBgMusic = inventory.unlockedBgMusic;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading shop data: $e');
    }
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    if (!canAffordPurchase(
      bankedPoints: bankedPoints,
      itemPrice: item['price'] as int,
    )) {
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
      final response = await _client.post(
        ApiConfig.getUri('/buy-item/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': item['id'],
          'item_type': item['type'],
          'price': item['price'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedInventory = _inventoryState.applyPurchasedItem(
          updatedBankedPoints: (data['banked_points'] as num?)?.toInt() ?? bankedPoints,
          itemType: item['type'] as String,
          itemId: item['id'] as String,
        );
        setState(() {
          bankedPoints = updatedInventory.bankedPoints;
          unlockedThemes = updatedInventory.unlockedThemes;
          unlockedTapSounds = updatedInventory.unlockedTapSounds;
          unlockedBgMusic = updatedInventory.unlockedBgMusic;
        });
        soundManager.playTap();
      }
    } catch (e) {
      debugPrint('Error buying item: $e');
    }
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: isLandscape ? MediaQuery.of(context).size.height * 0.9 : 620,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Point Shop',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFCA016),
                            shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            Text(
                              bankedPoints.toString(),
                              style: GoogleFonts.pixelifySans(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT AREA
                Expanded(
                  child: Row(
                    children: [
                      // SIDEBAR
                      Container(
                        width: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8DA9E6), Color(0xFFBBD5FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          border: Border(right: BorderSide(color: Colors.black, width: 3)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Text(
                                  'CATEGORIES',
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              _buildSidebarButton('Themes', Icons.palette, 0),
                              _buildSidebarButton('BGs', Icons.image, 1),
                              _buildSidebarButton('Taps', Icons.touch_app, 2),
                              _buildSidebarButton('Music', Icons.music_note, 3),
                            ],
                          ),
                        ),
                      ),

                      // SHOP GRID
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarButton(String label, IconData icon, int index) {
    bool isActive = activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => activeTab = index);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 100 : 80,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFCA016) : Colors.white70,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Row(
              mainAxisAlignment: isActive ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.black87, size: 22),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.pixelifySans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  Widget _buildItemGrid(List<Map<String, dynamic>> items) {
    // Check if the current category is BGs (index 1)
    bool isBGsTab = activeTab == 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Use 3 columns for big BG previews, 5 for smaller icons/themes
        crossAxisCount: isBGsTab ? 3 : 5, 
        childAspectRatio: isBGsTab ? 0.85 : 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnlocked = _inventoryState.isUnlocked(
          itemType: item['type'] as String,
          itemId: item['id'] as String,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [const BoxShadow(offset: Offset(3, 3), color: Colors.black12)],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Center(child: _buildItemPreview(item)),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                  border: Border(top: BorderSide(color: Colors.black, width: 1.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.bold, 
                        fontSize: isBGsTab ? 13 : 10 // Smaller text for smaller boxes
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    isUnlocked 
                      ? Text('OWNED', style: GoogleFonts.pixelifySans(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.bold))
                      : GestureDetector(
                          onTap: () => _buyItem(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCA016),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars, size: 10, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  item['price'].toString(), 
                                  style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemPreview(Map<String, dynamic> item) {
    bool isBGsTab = activeTab == 1;
    double iconSize = isBGsTab ? 50 : 35; // Dynamically resize preview content

    if (item['type'] == 'theme') {
      final id = item['id'] as String;
      if (id.startsWith('asset:')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            id.replaceFirst('asset:', ''),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      } else {
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Color(int.parse(id.replaceFirst('#', '0xFF'))),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
        );
      }
    } else {
      IconData icon = item['type'] == 'tap_sound' ? Icons.touch_app_rounded : Icons.music_note_rounded;
      Color color = item['type'] == 'tap_sound' ? const Color(0xFFAEC6FF) : const Color(0xFF2FBF71);
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
        child: Icon(icon, size: iconSize * 0.6, color: Colors.white),
      );
    }
  }
}
