import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.success(
          userId: (data['user_id'] as num).toInt(),
          username: data['username'] as String,
        );
      } else if (response.statusCode == 403) {
        final detail = data['detail'];
        String? reason;
        if (detail is Map) {
          reason = detail['reason'];
        }
        return AuthResponse.banned(banReason: reason);
      } else {
        return AuthResponse.error(data['detail'] ?? 'Invalid username or password');
      }
    } catch (e) {
      return AuthResponse.error("Can't connect to server. Is FastAPI running?");
    }
  }

  Future<AuthResponse> loginWithCode(String email, String code) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/login-with-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.success(
          userId: (data['user_id'] as num).toInt(),
          username: data['username'] as String,
        );
      } else if (response.statusCode == 403) {
        final detail = data['detail'];
        String? reason;
        if (detail is Map) {
          reason = detail['reason'];
        }
        return AuthResponse.banned(banReason: reason);
      } else {
        return AuthResponse.error(data['detail'] ?? 'Invalid code or account not found');
      }
    } catch (e) {
      return AuthResponse.error("Server Error");
    }
  }

  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/send-code'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.getUri('/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "code": code,
        }),
      );

      if (response.statusCode == 200) {
        return AuthResponse.success(
          userId: 0, // Register doesn't always return ID immediately in current backend
          username: username,
        );
      } else {
        final error = jsonDecode(response.body);
        return AuthResponse.error(error['detail'] ?? "Error creating account");
      }
    } catch (e) {
      return AuthResponse.error("Server Error");
    }
  }
}

enum AuthStatus { success, banned, error }

class AuthResponse {
  final AuthStatus status;
  final int? userId;
  final String? username;
  final String? errorMessage;
  final String? banReason;

  AuthResponse.success({required this.userId, required this.username})
      : status = AuthStatus.success,
        errorMessage = null,
        banReason = null;

  AuthResponse.banned({this.banReason})
      : status = AuthStatus.banned,
        userId = null,
        username = null,
        errorMessage = null;

  AuthResponse.error(this.errorMessage)
      : status = AuthStatus.error,
        userId = null,
        username = null,
        banReason = null;
}
