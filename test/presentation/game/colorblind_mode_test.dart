import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/presentation/game/play.dart';
import 'package:tap_n_match/core/soundmanager.dart';
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

  testWidgets('Game grid displays symbols when Colorblind Mode is enabled', (WidgetTester tester) async {
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'banked_points': 1000,
            'selected_theme': '#A9A9A9',
            'highest_score': 5000,
            'unlocked_themes': [],
            'unlocked_tap_sounds': [],
            'unlocked_bg_music': [],
            'seen_rewards': [],
            'colorblind_mode': true,
          }),
          200,
        ));

    // Enable colorblind mode in soundManager
    await soundManager.setColorblindMode(true);

    // Build the GamePage (Play)
    // Note: We need to provide userId in arguments because didChangeDependencies reads it
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => GamePage(httpClient: mockClient),
          settings: const RouteSettings(arguments: {'user_id': 1}),
        );
      },
    ));

    await tester.pumpAndSettle(); // Wait for data load and animation

    // Verify at least one Icon from _getSymbolForValue is present in the grid
    // The targetPattern is generated randomly, but _nextPatternValue with excludeDefault: true
    // ensures values 1, 2, 3, etc. are picked.
    
    // We look for Icons.favorite, Icons.cloud, Icons.eco, or Icons.star
    final iconFinder = find.byType(Icon);
    
    // There should be icons for both targetGrid and userGrid
    expect(iconFinder, findsAtLeast(1));
    
    // Specifically check for one of the known symbols
    final symbols = [Icons.favorite, Icons.cloud, Icons.eco, Icons.star];
    bool foundSymbol = false;
    for (var symbol in symbols) {
      if (tester.any(find.byIcon(symbol))) {
        foundSymbol = true;
        break;
      }
    }
    expect(foundSymbol, isTrue, reason: 'At least one colorblind symbol should be visible on the grid');

    // Clean up: Reset colorblind mode
    await soundManager.setColorblindMode(false);
  });

  testWidgets('Game grid does NOT display symbols when Colorblind Mode is disabled', (WidgetTester tester) async {
    when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(
          jsonEncode({
            'banked_points': 1000,
            'selected_theme': '#A9A9A9',
            'highest_score': 5000,
            'unlocked_themes': [],
            'unlocked_tap_sounds': [],
            'unlocked_bg_music': [],
            'seen_rewards': [],
            'colorblind_mode': false,
          }),
          200,
        ));

    await soundManager.setColorblindMode(false);

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => GamePage(httpClient: mockClient),
          settings: const RouteSettings(arguments: {'user_id': 1}),
        );
      },
    ));

    await tester.pumpAndSettle();

    // Symbols are only rendered if colorblindMode is true
    // Icons.arrow_back_ios_new (Back button) might be present, but not game symbols
    final symbols = [Icons.favorite, Icons.cloud, Icons.eco, Icons.star];
    for (var symbol in symbols) {
      expect(find.byIcon(symbol), findsNothing);
    }
  });
}
