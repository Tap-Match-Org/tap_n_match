import 'package:flutter/material.dart';
import '../presentation/auth/splash_page.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/auth/register_page.dart';
import '../presentation/main_menu/main_menu_page.dart';
import '../presentation/personal_feature/profile.dart';
import '../presentation/personal_feature/achievement.dart';
import '../presentation/community_features/leaderboards.dart';
import '../presentation/personal_feature/theme.dart';
import '../presentation/game/play.dart';
import '../presentation/game/daily_challenge_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const mainMenu = '/menu';
  static const profile = '/profile';
  static const achievements = '/achievements';
  static const leaderboards = '/leaderboards';
  static const theme = '/theme';
  static const game = '/game';
  static const dailyChallenge = '/daily_challenge';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    mainMenu: (context) => MainMenuPage(),
    profile: (context) => const ProfilePage(),
    achievements: (context) => const AchievementPage(),
    leaderboards: (context) => const LeaderboardsPage(),
    theme: (context) => const ThemePage(),
    game: (context) => const GamePage(),
    dailyChallenge: (context) => const DailyChallengePage(),
  };
}
