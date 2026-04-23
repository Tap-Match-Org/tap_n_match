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
  });

  testWidgets('ShopPage shows progress indicator while loading data', (WidgetTester tester) async {
    // Delay the response
    when(() => mockRepo.fetchInventory(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      return const ShopInventoryState(
        bankedPoints: 1000,
        selectedTheme: '#A9A9A9',
        unlockedThemes: [],
        unlockedTapSounds: [],
        unlockedBgMusic: [],
      );
    });

    await tester.pumpWidget(MaterialApp(home: ShopPage(shopRepository: mockRepo)));
    
    // Check for progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for data to load
    await tester.pumpAndSettle();
    
    // Progress indicator should be gone
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
