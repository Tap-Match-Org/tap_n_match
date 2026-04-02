import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/core/theme_background.dart';

class SupportMenuPage extends StatelessWidget {
  final int userId;
  final String selectedTheme;

  const SupportMenuPage({
    super.key,
    required this.userId,
    required this.selectedTheme,
  });

  void _openSupport(BuildContext context, String route) {
    Navigator.of(context).pushNamed(
      route,
      arguments: {
        'user_id': userId,
        'selected_theme': selectedTheme,
      },
    );
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
            // Back Button
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
            // Main Content
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
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
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSupportOption(
                        context,
                        icon: Icons.report_problem,
                        title: 'Report Player',
                        description: 'Report inappropriate player behavior',
                        color: Colors.red.shade400,
                        route: '/support/report_player',
                      ),
                      const SizedBox(height: 16),
                      _buildSupportOption(
                        context,
                        icon: Icons.feedback,
                        title: 'Player Feedback',
                        description: 'Share suggestions and concerns',
                        color: Colors.blue.shade400,
                        route: '/support/player_feedback',
                      ),
                      const SizedBox(height: 16),
                      _buildSupportOption(
                        context,
                        icon: Icons.bug_report,
                        title: 'Bug Reports',
                        description: 'Report bugs with screenshots',
                        color: Colors.orange.shade400,
                        route: '/support/bug_report',
                      ),
                      const SizedBox(height: 16),
                      _buildSupportOption(
                        context,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => _openSupport(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
