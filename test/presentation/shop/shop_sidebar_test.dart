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
    // Default success response
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'banked_points': 1000,
            'selected_theme': '#A9A9A9',
            'unlocked_themes': [],
            'unlocked_tap_sounds': [],
            'unlocked_bg_music': [],
          }),
          200,
        ));
  });

  testWidgets('Clicking BGs sidebar button updates the active tab label', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ShopPage(httpClient: mockClient)));
    await tester.pump(); // Trigger data load

    // Initial state check (Themes active)
    expect(find.text('Themes'), findsOneWidget);

    // Tap BGs icon
    await tester.tap(find.byIcon(Icons.image));
    await tester.pumpAndSettle();

    // Verify BGs label is now visible
    expect(find.text('BGs'), findsOneWidget);
    expect(find.text('Themes'), findsNothing);
  });

  testWidgets('Sidebar buttons show correct icons', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ShopPage(httpClient: mockClient)));
    
    expect(find.byIcon(Icons.palette), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });
}
