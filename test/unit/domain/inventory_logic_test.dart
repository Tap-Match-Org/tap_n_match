import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

void main() {
  group('Shop inventory rules', () {
    const baseInventory = ShopInventoryState(
      bankedPoints: 1000,
      selectedTheme: '#A9A9A9',
      unlockedThemes: ['#50C878'],
      unlockedTapSounds: [],
      unlockedBgMusic: [],
    );

    test('owned items are detected from the matching inventory bucket', () {
      expect(
        baseInventory.isUnlocked(itemType: 'theme', itemId: '#50C878'),
        isTrue,
      );
      expect(
        baseInventory.isUnlocked(itemType: 'tap_sound', itemId: '#50C878'),
        isFalse,
      );
    });

    test('purchased items are added to the correct unlocked list only once', () {
      final withTheme = baseInventory.applyPurchasedItem(
        updatedBankedPoints: 600,
        itemType: 'theme',
        itemId: '#87CEEB',
      );
      final withTapSound = withTheme.applyPurchasedItem(
        updatedBankedPoints: 600,
        itemType: 'tap_sound',
        itemId: 'genshin_tap',
      );
      final duplicateTheme = withTapSound.applyPurchasedItem(
        updatedBankedPoints: 600,
        itemType: 'theme',
        itemId: '#87CEEB',
      );

      expect(withTapSound.unlockedThemes, contains('#87CEEB'));
      expect(withTapSound.unlockedTapSounds, contains('genshin_tap'));
      expect(
        duplicateTheme.unlockedThemes.where((id) => id == '#87CEEB').length,
        1,
      );
    });
  });
}
