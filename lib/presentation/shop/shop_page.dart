import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';
import 'package:tap_n_match/repository/shop_repository.dart';

class ShopPage extends StatefulWidget {
  final ShopRepository? shopRepository;
  const ShopPage({super.key, this.shopRepository});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final ShopRepository _repository;
  int userId = 1;
  int bankedPoints = 0;
  String selectedTheme = "#A9A9A9";
  List<String> unlockedThemes = [];
  List<String> unlockedTapSounds = [];
  List<String> unlockedBgMusic = [];
  bool isLoading = true;
  bool _didInitialize = false;
  int activeTab = 0; 

  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;

  final GlobalKey _pointsDisplayKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _itemGridKey = GlobalKey();

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
    _repository = widget.shopRepository ?? ShopRepository();
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
    final inventory = await _repository.fetchInventory(userId);
    if (inventory != null && mounted) {
      setState(() {
        bankedPoints = inventory.bankedPoints;
        selectedTheme = inventory.selectedTheme;
        unlockedThemes = inventory.unlockedThemes;
        unlockedTapSounds = inventory.unlockedTapSounds;
        unlockedBgMusic = inventory.unlockedBgMusic;
        isLoading = false;
      });
      _queueTutorialIfNeeded(inventory.pendingTutorials);
    } else if (mounted) {
      setState(() => isLoading = false);
    }
  }

  List<TutorialStep> get _tutorialSteps => [
    TutorialStep(
      targetKey: _pointsDisplayKey,
      title: 'Point Shop Currency',
      description: 'Use your Banked Points here to unlock new styles. Your Lifetime Points won\'t be affected!',
      cardPosition: TutorialCardPosition.bottomLeft,
      cardOpacity: 0.7,
    ),
    TutorialStep(
      targetKey: _categoriesKey,
      title: 'Shop Categories',
      description: 'Switch between Themes, Backgrounds, Tap Sounds, and Music to see what\'s available.',
      cardPosition: TutorialCardPosition.centerRight,
      cardOpacity: 0.7,
    ),
    TutorialStep(
      targetKey: _itemGridKey,
      title: 'Unlock Items',
      description: 'Select an item to buy it. Once unlocked, you can equip it from the Themes page!',
      cardPosition: TutorialCardPosition.bottomCenter,
      cardOpacity: 0.7,
    ),
  ];

  void _queueTutorialIfNeeded(List<String> pendingTutorials) {
    if (_tutorialQueued || !pendingTutorials.contains(TutorialIds.shop)) {
      return;
    }

    _tutorialQueued = true;
    _showTutorialWhenReady();
  }

  void _showTutorialWhenReady() {
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;

      if (!_areTutorialTargetsReady()) {
        WidgetsBinding.instance.scheduleFrame();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _showTutorialWhenReady();
        });
        return;
      }

      if (_showTutorial) return;

      setState(() {
        _tutorialStepIndex = 0;
        _showTutorial = true;
      });
    });
  }

  bool _areTutorialTargetsReady() {
    final targets = [_pointsDisplayKey, _categoriesKey, _itemGridKey];
    for (final key in targets) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return false;
      }
    }
    return true;
  }

  Future<void> _finishTutorial() async {
    if (_isSavingTutorial) return;
    setState(() => _isSavingTutorial = true);
    try {
      await markTutorialComplete(userId: userId, tutorialId: TutorialIds.shop);
    } catch (e) {
      debugPrint("Error saving shop tutorial: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTutorial = false;
          _showTutorial = false;
        });
      }
    }
  }

  Future<void> _handleTutorialNext() async {
    if (_tutorialStepIndex < _tutorialSteps.length - 1) {
      setState(() => _tutorialStepIndex++);
      return;
    }
    await _finishTutorial();
  }

  void _handleTutorialBack() {
    if (_tutorialStepIndex == 0) return;
    setState(() => _tutorialStepIndex--);
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

    final updatedPoints = await _repository.purchaseItem(
      userId: userId,
      itemType: item['type'] as String,
      itemId: item['id'] as String,
      price: item['price'] as int,
    );

    if (updatedPoints != null) {
      final updatedInventory = _inventoryState.applyPurchasedItem(
        updatedBankedPoints: updatedPoints,
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
  }

  @override
  void dispose() {
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
        child: Stack(
          children: [
            Center(
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
                            onTap: () {
                              soundManager.playTap();
                              Navigator.pop(context);
                            },
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
                            key: _pointsDisplayKey,
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
                            key: _categoriesKey,
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
                                    child: Container(
                                      key: _itemGridKey,
                                      child: _buildItemGrid(_getCurrentItems()),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTutorial)
              GuidedTutorialOverlay(
                steps: _tutorialSteps,
                currentIndex: _tutorialStepIndex,
                onNext: _handleTutorialNext,
                onBack: _handleTutorialBack,
                onSkip: _finishTutorial,
                isSaving: _isSavingTutorial,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton(String label, IconData icon, int index) {
    bool isActive = activeTab == index;
    return GestureDetector(
      onTap: () {
        soundManager.playTap();
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
            boxShadow: const [BoxShadow(offset: Offset(3, 3), color: Colors.black12)],
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
