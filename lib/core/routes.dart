import 'package:flutter/material.dart';
import '../presentation/auth/splash_page.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/auth/register_page.dart';
import '../presentation/main_menu/main_menu_page.dart';
import '../presentation/personal_feature/profile.dart';
import '../presentation/personal_feature/achievement.dart';
import '../presentation/community_features/leaderboards.dart';
import '../presentation/personal_feature/theme.dart';
import '../presentation/shop/shop_page.dart';
import '../presentation/auth/banned_page.dart';
import '../presentation/game/daily_challenge_page.dart';
import '../presentation/game/play.dart';
import '../presentation/support/support_menu_page.dart';
import '../presentation/support/player_feedback_page.dart';
import '../presentation/support/bug_report_page.dart';
import '../presentation/support/ban_appeal_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const banned = '/banned';
  static const mainMenu = '/menu';
  static const profile = '/profile';
  static const achievements = '/achievements';
  static const leaderboards = '/leaderboards';
  static const theme = '/theme';
  static const game = '/game';
  static const dailyChallenge = '/daily_challenge';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    banned: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return BannedPage(reason: args?['reason']);
    },
    mainMenu: (context) => const MainMenuPage(),
    profile: (context) => const ProfilePage(),
    achievements: (context) => const AchievementPage(),
    leaderboards: (context) => const LeaderboardsPage(),
    theme: (context) => const ThemePage(),
    '/shop': (context) => const ShopPage(),
    game: (context) => const GamePage(),
    dailyChallenge: (context) => const DailyChallengePage(),
    '/support': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return SupportMenuPage(
        userId: args?['user_id'] ?? 1,
        selectedTheme: args?['selected_theme'] ?? '#A9A9A9',
      );
    },
    '/support/player_feedback': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return PlayerFeedbackPage(
        userId: args?['user_id'] ?? 1,
        selectedTheme: args?['selected_theme'] ?? '#A9A9A9',
      );
    },
    '/support/bug_report': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return BugReportPage(
        userId: args?['user_id'] ?? 1,
        selectedTheme: args?['selected_theme'] ?? '#A9A9A9',
      );
    },
    '/support/ban_appeal': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return BanAppealPage(
        userId: args?['user_id'] ?? 1,
        selectedTheme: args?['selected_theme'] ?? '#A9A9A9',
      );
    },
  };
}
