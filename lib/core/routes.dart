import 'package:flutter/material.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/login/login_page.dart';
import '../presentation/register/register_page.dart';
import '../presentation/main_menu/main_menu_page.dart';
import '../presentation/profile_page/profile.dart';
import '../presentation/achievement_page/achievement.dart';
import '../presentation/leaderboards_page/leaderboards.dart';
import '../presentation/theme_page/theme.dart';
import '../presentation/game/main_menu.dart';

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

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashPage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    mainMenu: (context) => const MainMenuPage(),
    profile: (context) => const ProfilePage(),
    achievements: (context) => const AchievementPage(),
    leaderboards: (context) => const LeaderboardsPage(),
    theme: (context) => const ThemePage(),
    game: (context) => const MainMenu(),
  };
}