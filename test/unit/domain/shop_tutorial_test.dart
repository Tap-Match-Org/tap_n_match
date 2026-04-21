import 'package:flutter_test/flutter_test.dart';
import 'package:tap_n_match/domain/shop/shop_rules.dart';

void main() {
  group('Shop Tutorial Domain Logic', () {
    test('ShopInventoryState.fromUserData should parse pending_tutorials', () {
      final userData = {
        'banked_points': 500,
        'selected_theme': '#A9A9A9',
        'unlocked_themes': ['#50C878'],
        'unlocked_tap_sounds': [],
        'unlocked_bg_music': [],
        'pending_tutorials': ['shop_intro', 'points_guide'],
      };

      final state = ShopInventoryState.fromUserData(userData);

      expect(state.pendingTutorials, containsAll(['shop_intro', 'points_guide']));
    });

    test('ShopInventoryState.fromUserData should default to empty list for pending_tutorials', () {
      final userData = {
        'banked_points': 500,
        'selected_theme': '#A9A9A9',
      };

      final state = ShopInventoryState.fromUserData(userData);

      expect(state.pendingTutorials, isEmpty);
    });

    test('applyPurchasedItem should preserve pendingTutorials', () {
      const state = ShopInventoryState(
        bankedPoints: 1000,
        selectedTheme: '#A9A9A9',
        unlockedThemes: [],
        unlockedTapSounds: [],
        unlockedBgMusic: [],
        pendingTutorials: ['shop_intro'],
      );

      final updated = state.applyPurchasedItem(
        updatedBankedPoints: 600,
        itemType: 'theme',
        itemId: '#50C878',
      );

      expect(updated.pendingTutorials, contains('shop_intro'));
    });
  });
}
