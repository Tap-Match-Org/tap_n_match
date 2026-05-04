import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/domain/entities/challenge.dart';

class ChallengeRepository {
  final http.Client _client;

  ChallengeRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Challenge?> fetchWeeklyChallenge(int userId) async {
    try {
      final response = await _client.get(ApiConfig.getUri('/weekly-challenge/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Challenge.fromJson(data);
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
