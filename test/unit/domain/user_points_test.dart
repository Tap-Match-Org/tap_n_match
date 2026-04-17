import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

void main() {
  group('User point rules', () {
    test('purchase affordability is based on banked points', () {
      expect(
        canAffordPurchase(bankedPoints: 1000, itemPrice: 400),
        isTrue,
      );
      expect(
        canAffordPurchase(bankedPoints: 399, itemPrice: 400),
        isFalse,
      );
    });

    test('successful purchase updates banked points from the backend response', () {
      const current = ShopInventoryState(
        bankedPoints: 1000,
        selectedTheme: '#A9A9A9',
        unlockedThemes: [],
        unlockedTapSounds: [],
        unlockedBgMusic: [],
      );

      final updated = current.applyPurchasedItem(
        updatedBankedPoints: 600,
        itemType: 'theme',
        itemId: '#50C878',
      );

      expect(updated.bankedPoints, 600);
      expect(updated.unlockedThemes, contains('#50C878'));
      expect(current.bankedPoints, 1000);
    });
  });
}
