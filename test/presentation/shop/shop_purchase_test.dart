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

    when(() => mockRepo.fetchInventory(any())).thenAnswer(
      (_) async => const ShopInventoryState(
        bankedPoints: 1000,
        selectedTheme: '#A9A9A9',
        unlockedThemes: [],
        unlockedTapSounds: [],
        unlockedBgMusic: [],
      ),
    );

    when(() => mockRepo.purchaseItem(
      userId: any(named: 'userId'),
      itemType: any(named: 'itemType'),
      itemId: any(named: 'itemId'),
      price: any(named: 'price'),
    )).thenAnswer((_) async => 500);
  });

  testWidgets('buying an item updates points and marks the item as owned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: ShopPage(shopRepository: mockRepo)));
    await tester.pumpAndSettle();

    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('OWNED'), findsNothing);

    await tester.tap(find.text('500'));
    await tester.pumpAndSettle();

    // Verify UI updates
    expect(find.text('500'), findsOneWidget);
    expect(find.text('OWNED'), findsOneWidget);

    // Verify repository was called correctly
    verify(() => mockRepo.purchaseItem(
      userId: 1,
      itemType: 'theme',
      itemId: '#50C878',
      price: 500,
    )).called(1);
  });
}
