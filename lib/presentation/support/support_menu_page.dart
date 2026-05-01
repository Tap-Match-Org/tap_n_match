import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/core/theme_background.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/core/tutorial_progress.dart';

class SupportMenuPage extends StatefulWidget {
  const SupportMenuPage({
    super.key,
    required this.userId,
    required this.selectedTheme,
  });

  final int userId;
  final String selectedTheme;

  @override
  State<SupportMenuPage> createState() => _SupportMenuPageState();
}

class _SupportMenuPageState extends State<SupportMenuPage> {
  bool _showTutorial = false;
  bool _isSavingTutorial = false;
  bool _tutorialQueued = false;
  int _tutorialStepIndex = 0;
  final GlobalKey _feedbackKey = GlobalKey();
  final GlobalKey _bugReportKey = GlobalKey();
  final GlobalKey _banAppealKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTutorialState();
  }

  void _openSupport(BuildContext context, String route) {
    Navigator.of(context).pushNamed(
      route,
      arguments: {
        'user_id': widget.userId,
        'selected_theme': widget.selectedTheme,
      },
    );
  }

  Future<void> _loadTutorialState() async {
    try {
      final response = await http.get(
        ApiConfig.getUri('/users/${widget.userId}'),
      );
      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _queueTutorialIfNeeded(data);
    } catch (e) {
      debugPrint('Error loading support tutorial state: $e');
    }
  }

  List<TutorialStep> get _tutorialSteps => [
        TutorialStep(
          targetKey: _feedbackKey,
          title: 'Player Feedback',
          description:
              'Send suggestions, balance ideas, or general feedback here when you want to help improve the game.',
          cardPosition: TutorialCardPosition.centerRight,
        ),
        TutorialStep(
          targetKey: _bugReportKey,
          title: 'Bug Reports',
          description:
              'Use this option for broken features, glitches, or crashes, especially if you can describe how the issue happened.',
          cardPosition: TutorialCardPosition.centerRight,
        ),
        TutorialStep(
          targetKey: _banAppealKey,
          title: 'Ban Appeal',
          description:
              'This section is only for appealing account suspensions. It should not be used for general support concerns.',
          cardPosition: TutorialCardPosition.topRight,
        ),
      ];

  void _queueTutorialIfNeeded(Map<String, dynamic> data) {
    if (_tutorialQueued || !hasPendingTutorial(data, TutorialIds.support)) {
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
    final targets = [
      _feedbackKey,
      _bugReportKey,
      _banAppealKey,
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
        userId: widget.userId,
        tutorialId: TutorialIds.support,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(widget.selectedTheme),
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
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Player Support',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSupportOption(
                        context,
                        key: _feedbackKey,
                        icon: Icons.feedback,
                        title: 'Player Feedback',
                        description: 'Share suggestions and concerns',
                        color: Colors.blue.shade400,
                        route: '/support/player_feedback',
                      ),
                      const SizedBox(height: 12),
                      _buildSupportOption(
                        context,
                        key: _bugReportKey,
                        icon: Icons.bug_report,
                        title: 'Bug Reports',
                        description: 'Report bugs with screenshots',
                        color: Colors.orange.shade400,
                        route: '/support/bug_report',
                      ),
                      const SizedBox(height: 12),
                      _buildSupportOption(
                        context,
                        key: _banAppealKey,
                        icon: Icons.gavel,
                        title: 'Ban Appeal',
                        description: 'Appeal your account suspension',
                        color: Colors.purple.shade400,
                        route: '/support/ban_appeal',
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

  Widget _buildSupportOption(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        soundManager.playTap();
        _openSupport(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}


