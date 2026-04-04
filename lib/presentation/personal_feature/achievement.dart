import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';
import 'achievement_list.dart'; 

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

const String _defaultAchievementTheme = "#A9A9A9";

class _AchievementPageState extends State<AchievementPage> {
  int userId = 1; // Default fallback
  String selectedTheme = _defaultAchievementTheme;
  bool _didInitialize = false;
  bool _isLoadingTheme = true;
  bool _isLoadingAchievements = true;
  List<Map<String, dynamic>> _achievements = [];
  String? _claimingId;
  int _claimableRewardCount = 0;
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;
  final GlobalKey _rewardSummaryKey = GlobalKey();
  final GlobalKey _achievementListKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('user_id')) {
      userId = args['user_id'];
    }
    if (_didInitialize) return;
    _didInitialize = true;
    _loadUserData();
    _loadAchievements();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingTheme = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          selectedTheme = data['selected_theme'] ?? _defaultAchievementTheme;
        });
        _queueTutorialIfNeeded(data);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTheme = false);
      }
    }
  }

  List<TutorialStep> get _tutorialSteps => [
        TutorialStep(
          targetKey: _rewardSummaryKey,
          title: 'Reward Summary',
          description:
              'This bar shows how many achievement rewards are ready to claim and whether you currently have anything waiting.',
          cardPosition: TutorialCardPosition.topCenter,
        ),
        TutorialStep(
          targetKey: _achievementListKey,
          title: 'Achievement Rewards',
          description:
              'Scroll this list to review your progress. When an achievement unlocks, you can claim its reward directly from here.',
          cardPosition: TutorialCardPosition.bottomCenter,
        ),
      ];

  void _queueTutorialIfNeeded(Map<String, dynamic> data) {
    if (_tutorialQueued || !hasPendingTutorial(data, TutorialIds.achievements)) {
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
      _rewardSummaryKey,
      _achievementListKey,
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
        tutorialId: TutorialIds.achievements,
      );
    } catch (error) {
      _showSnack(
        error.toString().replaceFirst('Exception: ', ''),
        color: Colors.redAccent,
      );
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

  Future<void> _loadAchievements() async {
    setState(() => _isLoadingAchievements = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/achievements/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = (data['achievements'] as List<dynamic>?) ?? [];
        final achievements = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (!mounted) return;
        setState(() {
          _achievements = achievements;
          _claimableRewardCount = data['claimable_reward_count'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading achievements: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingAchievements = false);
      }
    }
  }

  Future<void> _claimAchievement(String achievementId) async {
    setState(() => _claimingId = achievementId);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/claim-achievement/$userId/$achievementId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnack(
          "Reward claimed: ${data['reward_name'] ?? 'Unlocked'}",
          color: Colors.green,
        );
        await _loadAchievements();
      } else {
        _showSnack("Unable to claim reward yet.", color: Colors.redAccent);
      }
    } catch (e) {
      debugPrint("Claim error: $e");
      _showSnack("Unable to claim reward right now.", color: Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _claimingId = null);
      }
    }
  }

  void _showSnack(String message, {Color color = Colors.black87}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final bool isLoading = _isLoadingTheme || _isLoadingAchievements;
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
                    Padding(
                      key: _rewardSummaryKey,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            'Claimable rewards: $_claimableRewardCount',
                            style: GoogleFonts.pixelifySans(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (!isLoading)
                            Text(
                              _claimableRewardCount > 0 ? 'You have rewards' : 'No claimable rewards',
                              style: GoogleFonts.pixelifySans(fontSize: 12, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else
                      Expanded(
                        child: Container(
                          key: _achievementListKey,
                          child: AchievementList(
                            achievements: _achievements,
                            claimingId: _claimingId,
                            onClaim: _claimAchievement,
                          ),
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
}