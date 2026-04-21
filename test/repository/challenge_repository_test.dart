import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/repository/challenge_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late ChallengeRepository challengeRepository;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:8000/weekly-challenge/1'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    challengeRepository = ChallengeRepository(client: mockHttpClient);
  });

  group('ChallengeRepository - fetchWeeklyChallenge', () {
    test('returns challenge data on success (200)', () async {
      final challengeData = {
        'id': 'week_1',
        'title': 'Match 50 grids',
        'target_count': 50,
        'current_progress': 10,
        'is_complete': false,
      };
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(challengeData), 200),
      );

      final result = await challengeRepository.fetchWeeklyChallenge(1);

      expect(result, isNotNull);
      expect(result!['title'], 'Match 50 grids');
      expect(result['current_progress'], 10);
    });

    test('returns null on failure', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      final result = await challengeRepository.fetchWeeklyChallenge(1);

      expect(result, isNull);
    });
  });

  group('ChallengeRepository - submitProgress', () {
    test('returns true on success (200)', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 200));

      final result = await challengeRepository.submitProgress(1, 5);

      expect(result, isTrue);
    });
  });
}
