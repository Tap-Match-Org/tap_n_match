import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';
import 'package:tap_n_match/core/api_config.dart';
const String _defaultThemeKey = '#A9A9A9';
const String _defaultTapSoundAsset = 'audio/tap_sounds/default_tapSounds.mp3';
const String _defaultBgMusicAsset = 'audio/background_music/stal_default.mp3';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> with TickerProviderStateMixin {
  int userId = 1; // Default fallback
  List<String> unlockedColors = [_defaultThemeKey];
  String selectedTheme = _defaultThemeKey;
  bool isLoading = true;
  bool _didInitialize = false;
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;

  List<String> unlockedSounds = [_defaultTapSoundAsset];
  String selectedSound = _defaultTapSoundAsset;

  List<String> unlockedMusic = [_defaultBgMusicAsset];
  String selectedMusic = _defaultBgMusicAsset;

  Set<String> seenRewards = {};

  Timer? _topSnackBarTimer;
  OverlayEntry? _topSnackBarEntry;
  late final AnimationController _topSnackBarController;
  late final AnimationController _newBadgeController;
  String _topSnackBarMessage = "";
  final GlobalKey _backgroundColumnKey = GlobalKey();
  final GlobalKey _soundColumnKey = GlobalKey();
  final GlobalKey _musicColumnKey = GlobalKey();

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
    "#87CEEB": "Sky Blue",
    "#228B22": "Forest Green",
    "#301934": "Deep Purple",
    "#FF4500": "Sunset Orange",
    "#DC143C": "Crimson Red",
    "#BF00FF": "Electric Purple",
    "#800000": "Maroon Velvet",
    "#191970": "Midnight Blue",
    "#FF7F50": "Coral Reef",
    "#40E0D0": "Turquoise Dream",
    "#000080": "Navy Commander",
    "#50C878": "Emerald Green",
    "#FF69B4": "Hot Pink",
    "#39FF14": "Neon Green",
    "#E0E0E0": "Pearl White",
    "#A020F0": "Rainbow Prism",
    "#F8F8FF": "Perfect White",
    "#FFFFFF": "White",
    "#4B0082": "Indigo",
    "#480082": "Dark Indigo",
    "#C0C0C0": "Silver",
    "#708090": "Slate Gray",
    "#CD7F32": "Bronze",
    "asset:assets/background/minecraft_bgColor.jpg": "Minecraft Grass",
    "asset:assets/background/harvest_moon_background.jpeg": "Harvest Moon",
    "asset:assets/background/genshin_background.jpeg": "Genshin",
    "asset:assets/background/snowfall_background.jpeg": "Snowfall",
  };

  String _getThemeName(String themeKey) {
    final trimmedKey = themeKey.trim();
    // Try exact match first
    if (colorNames.containsKey(trimmedKey)) {
      return colorNames[trimmedKey]!;
    }
    // Try case-insensitive match
    for (final entry in colorNames.entries) {
      if (entry.key.toLowerCase() == trimmedKey.toLowerCase()) {
        return entry.value;
      }
    }
    // Fallback
    if (assetThemePath(trimmedKey) != null) {
      return "Special Background";
    }
    if (trimmedKey.startsWith('#')) {
      return "Point Theme ($trimmedKey)";
    }
    return trimmedKey;
  }

  final Map<String, String> soundNames = {
    _defaultTapSoundAsset: "Default Tap",
    "audio/tap_sounds/genshin_tap_sound.mp3": "Genshin Tap",
    "audio/tap_sounds/minecraft_tap_sound.mp3": "Minecraft Tap",
    "audio/tap_sounds/snowfall_tap_sound.mp3": "Snowfall Tap",
  };

  final Map<String, String> musicNames = {
    _defaultBgMusicAsset: "Default Music",
    "audio/background_music/genshin_bgMusic.mp3": "Genshin BGM",
    "audio/background_music/minecraft_bgMusic.mp3": "Minecraft BGM",
    "audio/background_music/harvestMoon.mp3": "Harvest Moon BGM",
    "audio/background_music/snowfall_bgMusic.mp3": "Snowfall BGM",
  };

  @override
  void initState() {
    super.initState();
    _topSnackBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _newBadgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _topSnackBarTimer?.cancel();
    _topSnackBarEntry?.remove();
    _topSnackBarController.dispose();
    _newBadgeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(ApiConfig.getUri('/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final colors = (data['unlocked_themes'] as List<dynamic>?)
                ?.map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toList() ??
            [];
        if (!colors.contains(_defaultThemeKey)) {
          colors.insert(0, _defaultThemeKey);
        }

        final sounds = (data['unlocked_tap_sounds'] as List<dynamic>?)
                ?.map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toList() ??
            [];
        if (sounds.isEmpty) {
          sounds.add(_defaultTapSoundAsset);
        }

        final musics = (data['unlocked_bg_music'] as List<dynamic>?)
                ?.map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toList() ??
            [];
        if (musics.isEmpty) {
          musics.add(_defaultBgMusicAsset);
        }

        final seen = (data['seen_rewards'] as String?)
                ?.split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet() ??
            {};

        setState(() {
          unlockedColors = colors;
          selectedTheme = (data['selected_theme'] as String?)?.trim() ?? _defaultThemeKey;
          unlockedSounds = sounds;
          selectedSound = (data['selected_tap_sound'] as String?)?.trim() ?? _defaultTapSoundAsset;
          unlockedMusic = musics;
          selectedMusic = (data['selected_bg_music'] as String?)?.trim() ?? _defaultBgMusicAsset;
          seenRewards = seen;
          isLoading = false;
        });

        // Sync SoundManager settings to ensure local singleton matches server state
        await soundManager.setTapSoundEnabled(data['tap_sound_enabled'] == true || data['tap_sound_enabled'] == 1 || data['tap_sound_enabled'] == null);
        await soundManager.setBgMusicEnabled(data['bg_music_enabled'] == true || data['bg_music_enabled'] == 1 || data['bg_music_enabled'] == null);
        await soundManager.setTapVolume((data['tap_volume'] as num?)?.toDouble() ?? 1.0);
        await soundManager.setBgVolume((data['bg_volume'] as num?)?.toDouble() ?? 0.5);
        await soundManager.setColorblindMode(data['colorblind_mode'] == true || data['colorblind_mode'] == 1);
        
        await soundManager.updateSettings(
          tapSound: data['selected_tap_sound'],
          bgMusic: data['selected_bg_music'],
        );

        _queueTutorialIfNeeded(data);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<TutorialStep> get _tutorialSteps => [
        TutorialStep(
          targetKey: _backgroundColumnKey,
          title: 'Background Themes',
          description:
              'Use this column to switch your background theme. Newly unlocked themes can show a NEW badge until you inspect them.',
          cardPosition: TutorialCardPosition.topLeft,
        ),
        TutorialStep(
          targetKey: _soundColumnKey,
          title: 'Tap Sounds',
          description:
              'This column changes the sound that plays when you tap in the game. Select one to preview and equip it.',
          cardPosition: TutorialCardPosition.topCenter,
        ),
        TutorialStep(
          targetKey: _musicColumnKey,
          title: 'Background Music',
          description:
              'Choose your background music here. Your selected track becomes the music used around the game.',
          cardPosition: TutorialCardPosition.topRight,
        ),
      ];

  void _queueTutorialIfNeeded(Map<String, dynamic> data) {
    if (_tutorialQueued || !hasPendingTutorial(data, TutorialIds.themes)) {
      return;
    }

    _tutorialQueued = true;
    _showTutorialWhenReady();
  }

  void _showTutorialWhenReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_areTutorialTargetsReady()) {
        WidgetsBinding.instance.scheduleFrame();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _showTutorialWhenReady();
        });
        return;
      }

      setState(() {
        _tutorialStepIndex = 0;
        _showTutorial = true;
      });
    });
  }

  bool _areTutorialTargetsReady() {
    final targets = [
      _backgroundColumnKey,
      _soundColumnKey,
      _musicColumnKey,
    ];

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
      await markTutorialComplete(
        userId: userId,
        tutorialId: TutorialIds.themes,
      );
    } catch (error) {
      await _showTopSnackBar(error.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _markAsSeen(String rewardId) async {
    final id = rewardId.trim();
    if (seenRewards.contains(id)) return;
    
    try {
      final response = await http.put(
        ApiConfig.getUri('/mark-reward-seen/$userId/${Uri.encodeComponent(id)}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          seenRewards.add(id);
        });
      }
    } catch (e) {
      debugPrint("Error marking reward as seen: $e");
    }
  }
Future<void> _selectTheme(String themeKey) async {
  final trimmedKey = themeKey.trim();
  soundManager.playTap();
  _markAsSeen(trimmedKey);
  try {
    final response = await http.put(
      ApiConfig.getUri('/select-theme/$userId?theme_color=${Uri.encodeComponent(trimmedKey)}'),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      setState(() => selectedTheme = trimmedKey);
      _showTopSnackBar("Theme changed to ${_getThemeName(trimmedKey)}!");
    }
  } catch (e) {
    debugPrint("Error selecting theme: $e");
  }
}

  Future<void> _selectSound(String assetPath) async {
    final trimmedPath = assetPath.trim();
    soundManager.playTap();
    _markAsSeen(trimmedPath);
    try {
      final response = await http.put(
        ApiConfig.getUri('/select-tap-sound/$userId?asset_path=${Uri.encodeComponent(trimmedPath)}'),
      );

      if (response.statusCode == 200) {
        await soundManager.setSelectedTapSound(trimmedPath);
        if (!mounted) return;
        setState(() => selectedSound = trimmedPath);
        _showTopSnackBar("Tap sound changed to ${soundNames[trimmedPath] ?? 'a new sound'}!");
      }
    } catch (e) {
      debugPrint("Error selecting tap sound: $e");
    }
  }

  Future<void> _selectMusic(String assetPath) async {
    final trimmedPath = assetPath.trim();
    soundManager.playTap();
    _markAsSeen(trimmedPath);
    try {
      final response = await http.put(
        ApiConfig.getUri('/select-bg-music/$userId?asset_path=${Uri.encodeComponent(trimmedPath)}'),
      );

      if (response.statusCode == 200) {
        await soundManager.setSelectedBgMusic(trimmedPath);
        if (!mounted) return;
        setState(() => selectedMusic = trimmedPath);
        _showTopSnackBar("Music changed to ${musicNames[trimmedPath] ?? 'a new track'}!");
      }
    } catch (e) {
      debugPrint("Error selecting music: $e");
    }
  }

  Future<void> _showTopSnackBar(String message) async {
    _topSnackBarTimer?.cancel();
    _topSnackBarMessage = message;

    if (_topSnackBarEntry == null) {
      final animation = CurvedAnimation(
        parent: _topSnackBarController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );

      _topSnackBarEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final offsetY = (-70 * (1 - animation.value)).clamp(-70, 0).toDouble();
                return Opacity(
                  opacity: animation.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, offsetY),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2B9D1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _topSnackBarMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_topSnackBarEntry!);
    } else {
      _topSnackBarEntry!.markNeedsBuild();
    }

    await _topSnackBarController.forward(from: 0);
    _topSnackBarTimer = Timer(const Duration(milliseconds: 650), () async {
      await _topSnackBarController.reverse();
      _topSnackBarEntry?.remove();
      _topSnackBarEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(selectedTheme),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () {
                  soundManager.playTap();
                  Navigator.pop(context);
                },
                child: _buildIconButton(Icons.arrow_back_ios_new),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 65, bottom: 45),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(color: const Color(0xFFD9D9D9).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (isLoading)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: Row(
                            children: [
                              _buildThemeColumn(
                                "Background",
                                const Color(0xFFAEC6FF),
                                unlockedColors.map((hex) => _themeItem(hex)).toList(),
                                columnKey: _backgroundColumnKey,
                              ),
                              const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                              _buildThemeColumn(
                                "Tap Sound",
                                const Color(0xFFFFF9B0),
                                unlockedSounds.map((name) => _soundItem(name)).toList(),
                                columnKey: _soundColumnKey,
                              ),
                              const VerticalDivider(color: Colors.black, thickness: 2, width: 0),
                              _buildThemeColumn(
                                "Music",
                                const Color(0xFFB4FF91),
                                unlockedMusic.map((name) => _musicItem(name)).toList(),
                                columnKey: _musicColumnKey,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFE59A5A), borderRadius: BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)), border: Border(bottom: BorderSide(color: Colors.black, width: 3))),
      child: Text('THEMES', textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFE08CF4), shadows: [const Shadow(offset: Offset(2, 2), color: Colors.black)])),
    );
  }

  Widget _buildThemeColumn(
    String title,
    Color headerColor,
    List<Widget> items, {
    Key? columnKey,
  }) {
    return Expanded(
      child: Column(
        key: columnKey,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: headerColor.withValues(alpha: 0.3), border: const Border(bottom: BorderSide(color: Colors.black, width: 2))),
            child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(child: items.isEmpty ? Center(child: Text("None", style: GoogleFonts.pixelifySans(color: Colors.grey, fontSize: 12))) : ListView(padding: const EdgeInsets.all(8), children: items)),
        ],
      ),
    );
  }

  Widget _themeItem(String themeKey) {
    final assetPath = assetThemePath(themeKey);
    final bool isAsset = assetPath != null;
    final bool isSelected = selectedTheme == themeKey;
    final String name = _getThemeName(themeKey);
    final Color backgroundColor = isAsset ? Colors.black45 : parseThemeColor(themeKey);
    final bool isNew = !seenRewards.contains(themeKey.trim()) && !isSelected && themeKey != _defaultThemeKey;


    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _selectTheme(themeKey),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              image: assetPath != null
                  ? DecorationImage(
                      image: AssetImage(assetPath),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                isSelected ? "$name (ACTIVE)" : name,
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: isSelected || isAsset || backgroundColor.computeLuminance() < 0.4 ? Colors.white : Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (isNew)
          Positioned(
            top: -4,
            right: -4,
            child: _NewBadge(controller: _newBadgeController),
          ),
      ],
    );
  }

  Widget _soundItem(String assetPath) {
    final bool isSelected = selectedSound == assetPath;
    final String label = soundNames[assetPath] ?? assetPath.split('/').last;
    final bool isNew = !seenRewards.contains(assetPath.trim()) && !isSelected && assetPath != _defaultTapSoundAsset;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _selectSound(assetPath),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9B0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: Center(
              child: Text(
                isSelected ? "$label (ACTIVE)" : label,
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (isNew)
          Positioned(
            top: -4,
            right: -4,
            child: _NewBadge(controller: _newBadgeController),
          ),
      ],
    );
  }

  Widget _musicItem(String assetPath) {
    final bool isSelected = selectedMusic == assetPath;
    final String label = musicNames[assetPath] ?? assetPath.split('/').last;
    final bool isNew = !seenRewards.contains(assetPath.trim()) && !isSelected && assetPath != _defaultBgMusicAsset;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _selectMusic(assetPath),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFB4FF91),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: Center(
              child: Text(
                isSelected ? "$label (ACTIVE)" : label,
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (isNew)
          Positioned(
            top: -4,
            right: -4,
            child: _NewBadge(controller: _newBadgeController),
          ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Icon(icon, color: Colors.black, size: 22));
  }
}

class _NewBadge extends StatelessWidget {
  final AnimationController controller;
  const _NewBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          'NEW',
          style: GoogleFonts.pixelifySans(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
