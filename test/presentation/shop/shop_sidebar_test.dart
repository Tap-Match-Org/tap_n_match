import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/presentation/shop/shop_page.dart';
import 'package:tap_n_match/repository/shop_repository.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late MockShopRepository mockRepo;

  setUp(() {
    mockRepo = MockShopRepository();
    
    when(() => mockRepo.fetchInventory(any())).thenAnswer((_) async => const ShopInventoryState(
          bankedPoints: 1000,
          selectedTheme: '#A9A9A9',
          unlockedThemes: [],
          unlockedTapSounds: [],
          unlockedBgMusic: [],
        ));
  });

  testWidgets('Clicking BGs sidebar button updates the active tab label', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ShopPage(shopRepository: mockRepo)));
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
    await tester.pumpWidget(MaterialApp(home: ShopPage(shopRepository: mockRepo)));
    
    expect(find.byIcon(Icons.palette), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });
}
