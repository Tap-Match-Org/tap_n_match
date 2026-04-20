import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late AuthRepository authRepository;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:8000/login'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    authRepository = AuthRepository(client: mockHttpClient);
  });

  group('AuthRepository - login', () {
    test('returns AuthResponse.success when login is successful (200)', () async {
      // Arrange
      final successResponse = {
        'user_id': 1,
        'username': 'testuser',
      };
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(successResponse), 200));

      // Act
      final result = await authRepository.login('testuser', 'password');

      // Assert
      expect(result.status, AuthStatus.success);
      expect(result.userId, 1);
      expect(result.username, 'testuser');
    });

    test('returns AuthResponse.error when credentials are invalid (401)', () async {
      // Arrange
      final errorResponse = {'detail': 'Invalid username or password'};
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(errorResponse), 401));

      // Act
      final result = await authRepository.login('testuser', 'wrongpassword');

      // Assert
      expect(result.status, AuthStatus.error);
      expect(result.errorMessage, 'Invalid username or password');
    });

    test('returns AuthResponse.banned when user is banned (403)', () async {
      // Arrange
      final bannedResponse = {
        'detail': {'reason': 'Violation of rules'}
      };
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(bannedResponse), 403));

      // Act
      final result = await authRepository.login('banneduser', 'password');

      // Assert
      expect(result.status, AuthStatus.banned);
      expect(result.banReason, 'Violation of rules');
    });

    test('returns AuthResponse.error when server is unreachable', () async {
      // Arrange
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network Error'));

      // Act
      final result = await authRepository.login('testuser', 'password');

      // Assert
      expect(result.status, AuthStatus.error);
      expect(result.errorMessage, contains('Can\'t connect to server'));
    });
  });
}
