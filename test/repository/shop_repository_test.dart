import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/repository/shop_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late ShopRepository shopRepository;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:8000/users/1'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    shopRepository = ShopRepository(client: mockHttpClient);
  });

  group('ShopRepository - fetchInventory', () {
    test('returns ShopInventoryState on success (200)', () async {
      final userData = {
        'banked_points': 1000,
        'selected_theme': '#A9A9A9',
        'unlocked_themes': ['#50C878'],
        'unlocked_tap_sounds': [],
        'unlocked_bg_music': [],
      };
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(userData), 200),
      );

      final result = await shopRepository.fetchInventory(1);

      expect(result, isNotNull);
      expect(result!.bankedPoints, 1000);
      expect(result.unlockedThemes, contains('#50C878'));
    });

    test('returns null on failure', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      final result = await shopRepository.fetchInventory(1);

      expect(result, isNull);
    });
  });

  group('ShopRepository - purchaseItem', () {
    test('returns updated points on success (200)', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode({'banked_points': 500}), 200));

      final result = await shopRepository.purchaseItem(
        userId: 1,
        itemType: 'theme',
        itemId: '#50C878',
        price: 500,
      );

      expect(result, 500);
    });
  });

  group('ShopRepository - updateSelectedTheme', () {
    test('returns true on success (200)', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 200));

      final result = await shopRepository.updateSelectedTheme(1, '#50C878');

      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 400));

      final result = await shopRepository.updateSelectedTheme(1, '#50C878');

      expect(result, isFalse);
    });
  });
}
