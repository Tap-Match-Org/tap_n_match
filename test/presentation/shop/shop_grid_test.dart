import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
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
  });

  testWidgets('ShopPage shows progress indicator while loading data', (WidgetTester tester) async {
    // We delay the response to ensure the loading state is visible
    when(() => mockClient.get(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      return http.Response(
        jsonEncode({
          'banked_points': 1000,
          'selected_theme': '#A9A9A9',
          'unlocked_themes': [],
          'unlocked_tap_sounds': [],
          'unlocked_bg_music': [],
        }),
        200,
      );
    });

    await tester.pumpWidget(MaterialApp(home: ShopPage(httpClient: mockClient)));
    
    // Check for progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for data to load
    await tester.pumpAndSettle();
    
    // Progress indicator should be gone
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
