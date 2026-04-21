import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';

class ChallengeRepository {
  final http.Client _client;

  ChallengeRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> fetchWeeklyChallenge(int userId) async {
    try {
      final response = await _client.get(ApiConfig.getUri('/weekly-challenge/$userId'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> submitProgress(int userId, int progress) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/weekly-challenge/submit/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'progress': progress}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
