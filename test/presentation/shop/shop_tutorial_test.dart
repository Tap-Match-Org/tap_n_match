import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/core/tutorial_overlay.dart';
import 'package:tap_n_match/presentation/shop/shop_page.dart';
import '../../mocks/mock_http_client.dart';

void main() {
  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(ApiConfig.getUri('/users/1'));
  });

  setUp(() {
    mockClient = MockClient();
  });

  testWidgets('ShopPage triggers tutorial when pendingTutorials contains shop', (WidgetTester tester) async {
    when(() => mockClient.get(any())).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'banked_points': 1000,
          'selected_theme': '#A9A9A9',
          'unlocked_themes': [],
          'unlocked_tap_sounds': [],
          'unlocked_bg_music': [],
          'pending_tutorials': ['shop'],
        }),
        200,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ShopPage(httpClient: mockClient),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => ShopPage(httpClient: mockClient),
            settings: const RouteSettings(arguments: {'user_id': 1}),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GuidedTutorialOverlay), findsOneWidget);
    expect(find.text('Point Shop Currency'), findsOneWidget);
  });
}
