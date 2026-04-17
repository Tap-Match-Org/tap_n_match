import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/presentation/shop/shop_page.dart';
import 'package:tap_n_match/core/api_config.dart';

import '../../mocks/mock_http_client.dart';

void main() {
  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(ApiConfig.getUri('/users/1'));
  });

  setUp(() {
    mockClient = MockClient();

    when(() => mockClient.get(any())).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'banked_points': 1000,
          'selected_theme': '#A9A9A9',
          'unlocked_themes': [],
          'unlocked_tap_sounds': [],
          'unlocked_bg_music': [],
        }),
        200,
      ),
    );

    when(
      () => mockClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'banked_points': 500,
        }),
        200,
      ),
    );
  });

  testWidgets('buying an item updates points and marks the item as owned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: ShopPage(httpClient: mockClient)));
    await tester.pumpAndSettle();

    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('OWNED'), findsNothing);

    await tester.tap(find.text('500'));
    await tester.pumpAndSettle();

    expect(find.text('500'), findsOneWidget);
    expect(find.text('OWNED'), findsOneWidget);

    verify(
      () => mockClient.post(
        ApiConfig.getUri('/buy-item/1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_id': '#50C878',
          'item_type': 'theme',
          'price': 500,
        }),
      ),
    ).called(1);
  });
}
