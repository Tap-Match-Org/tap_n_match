import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
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
    "#C0C0C0": "Silver Star",
    "#800000": "Maroon Velvet",
    "#191970": "Midnight Blue",
    "#FF7F50": "Coral Reef",
    "#40E0D0": "Turquoise Dream",
    "#708090": "Slate Stone",
    "#000080": "Navy Commander",
    "#50C878": "Emerald Green",
    "#CD7F32": "Bronze Age",
    "#FF69B4": "Hot Pink",
    "#39FF14": "Neon Green",
    "#E0E0E0": "Pearl White",
    "#A020F0": "Rainbow Prism",
    "#F8F8FF": "Perfect White",
    "asset:assets/background_color/minecraft_bgColor.jpg": "Minecraft Grass",
  };

  final Map<String, String> soundNames = {
    _defaultTapSoundAsset: "Default Tap",
    "audio/tap_sounds/genshin_tap_sound.mp3": "Genshin Tap",
    "audio/tap_sounds/minecraft_tap_sound.mp3": "Minecraft Tap",
  };

  final Map<String, String> musicNames = {
    _defaultBgMusicAsset: "Default Music",
    "audio/background_music/genshin_bgMusic.mp3": "Genshin BGM",
    "audio/background_music/minecraft_bgMusic.mp3": "Minecraft BGM",
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
          selectedTheme = data['selected_theme'] ?? _defaultThemeKey;
          unlockedSounds = sounds;
          selectedSound = data['selected_tap_sound'] ?? _defaultTapSoundAsset;
          unlockedMusic = musics;
          selectedMusic = data['selected_bg_music'] ?? _defaultBgMusicAsset;
          seenRewards = seen;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsSeen(String rewardId) async {
    if (seenRewards.contains(rewardId)) return;
    
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/mark-reward-seen/$userId/${Uri.encodeComponent(rewardId)}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          seenRewards.add(rewardId);
        });
      }
    } catch (e) {
      debugPrint("Error marking reward as seen: $e");
    }
  }

  Future<void> _selectTheme(String themeKey) async {
    _markAsSeen(themeKey);
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/select-theme/$userId?theme_color=${Uri.encodeComponent(themeKey)}'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => selectedTheme = themeKey);
        _showTopSnackBar("Theme changed to ${colorNames[themeKey] ?? themeKey}!");
      }
    } catch (e) {
      debugPrint("Error selecting theme: $e");
    }
  }

  Future<void> _selectSound(String assetPath) async {
    _markAsSeen(assetPath);
    try {
      final response = await http.put(Uri.parse(
        'http://localhost:8000/select-tap-sound/$userId?asset_path=${Uri.encodeComponent(assetPath)}',
      ));
      if (response.statusCode == 200) {
        await soundManager.setSelectedTapSound(assetPath);
        await soundManager.playTap();
        if (!mounted) return;
        setState(() => selectedSound = assetPath);
        _showTopSnackBar("Tap sound changed to ${soundNames[assetPath] ?? 'a new sound'}!");
      }
    } catch (e) {
      debugPrint("Error selecting tap sound: $e");
    }
  }

  Future<void> _selectMusic(String assetPath) async {
    _markAsSeen(assetPath);
    try {
      final response = await http.put(Uri.parse(
        'http://localhost:8000/select-bg-music/$userId?asset_path=${Uri.encodeComponent(assetPath)}',
      ));
      if (response.statusCode == 200) {
        await soundManager.setSelectedBgMusic(assetPath);
        if (!mounted) return;
        setState(() => selectedMusic = assetPath);
        _showTopSnackBar("Music changed to ${musicNames[assetPath] ?? 'a new track'}!");
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

  Widget _themeItem(String themeKey) {
    final assetPath = assetThemePath(themeKey);
    final bool isAsset = assetPath != null;
    final bool isSelected = selectedTheme == themeKey;
    final String name = colorNames[themeKey] ?? (isAsset ? "Image Theme" : themeKey);
    final Color backgroundColor = isAsset ? Colors.black45 : parseThemeColor(themeKey);
    final bool isNew = !seenRewards.contains(themeKey) && !isSelected && themeKey != _defaultThemeKey;

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
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
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
    final bool isNew = !seenRewards.contains(assetPath) && !isSelected && assetPath != _defaultTapSoundAsset;

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
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
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
    final bool isNew = !seenRewards.contains(assetPath) && !isSelected && assetPath != _defaultBgMusicAsset;

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
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
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
