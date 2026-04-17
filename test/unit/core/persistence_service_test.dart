import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_n_match/core/persistence_service.dart';

void main() {
  group('PersistenceService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getUserId returns null if not set', () async {
      final userId = await PersistenceService.getUserId();
      expect(userId, isNull);
    });

    test('getUserId returns null if id is 0 (legacy check)', () async {
      SharedPreferences.setMockInitialValues({'user_id': 0});
      final userId = await PersistenceService.getUserId();
      expect(userId, isNull);
    });

    test('saveUserId saves and getUserId retrieves the correct id', () async {
      await PersistenceService.saveUserId(42);
      final userId = await PersistenceService.getUserId();
      expect(userId, 42);
    });

    test('clearUserId removes the saved id', () async {
      await PersistenceService.saveUserId(42);
      await PersistenceService.clearUserId();
      final userId = await PersistenceService.getUserId();
      expect(userId, isNull);
    });

    test('saveUsername saves and getUsername retrieves the correct username', () async {
      await PersistenceService.saveUsername('PlayerOne');
      final username = await PersistenceService.getUsername();
      expect(username, 'PlayerOne');
    });
  });
}
