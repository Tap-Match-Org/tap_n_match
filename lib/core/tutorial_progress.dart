import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';

class TutorialIds {
  static const welcome = 'welcome';
  static const profile = 'profile';
  static const play = 'play';
  static const dailyChallenge = 'daily_challenge';
  static const leaderboards = 'leaderboards';
  static const achievements = 'achievements';
  static const themes = 'themes';
  static const support = 'support';
}

List<String> extractPendingTutorials(Map<String, dynamic> data) {
  final raw = data['pending_tutorials'];
  if (raw is! List) {
    return const [];
  }

  return raw.whereType<String>().toList();
}

bool hasPendingTutorial(Map<String, dynamic> data, String tutorialId) {
  return extractPendingTutorials(data).contains(tutorialId);
}

Future<void> markTutorialComplete({
  required int userId,
  required String tutorialId,
}) async {
  final response = await http.put(
    ApiConfig.getUri('/tutorials/$userId/$tutorialId/complete'),
  );

  if (response.statusCode == 200) {
    return;
  }

  String message = 'Failed to save tutorial progress.';
  try {
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic> && data['detail'] is String) {
      message = data['detail'] as String;
    }
  } catch (_) {
    // Fall back to the default message when the response body is not JSON.
  }

  throw Exception(message);
}
