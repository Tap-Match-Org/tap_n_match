import 'package:flutter/material.dart';

const String kDefaultTheme = '#A9A9A9';
const String kAssetThemePrefix = 'asset:';

bool isAssetTheme(String value) => value.startsWith(kAssetThemePrefix);

String? assetThemePath(String value) {
  if (!isAssetTheme(value)) return null;
  final path = value.substring(kAssetThemePrefix.length).trim();
  return path.isEmpty ? null : path;
}

Color parseThemeColor(String value) {
  try {
    final hex = value.startsWith('#') ? value : '#A9A9A9';
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFFA9A9A9);
  }
}

BoxDecoration buildThemeDecoration(
  String selectedTheme, {
  bool radial = true,
  Alignment begin = Alignment.topCenter,
  Alignment end = Alignment.bottomCenter,
  double radius = 1.2,
  double opacityStart = 0.8,
  double opacityEnd = 0.4,
}) {
  final assetPath = assetThemePath(selectedTheme);

  if (assetPath != null) {
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage(assetPath),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.1), BlendMode.darken),
      ),
    );
  }

  final themeColor = parseThemeColor(selectedTheme);
  final gradient = radial
      ? RadialGradient(
          center: Alignment.center,
          radius: radius,
          colors: [
            themeColor.withValues(alpha: opacityStart),
            themeColor.withValues(alpha: opacityEnd),
          ],
        )
      : LinearGradient(
          begin: begin,
          end: end,
          colors: [
            themeColor.withValues(alpha: opacityStart),
            themeColor.withValues(alpha: opacityEnd),
          ],
        );

  return BoxDecoration(gradient: gradient);
}
