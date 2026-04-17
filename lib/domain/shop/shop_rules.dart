class ShopInventoryState {
  const ShopInventoryState({
    required this.bankedPoints,
    required this.selectedTheme,
    required this.unlockedThemes,
    required this.unlockedTapSounds,
    required this.unlockedBgMusic,
  });

  factory ShopInventoryState.fromUserData(Map<String, dynamic> data) {
    return ShopInventoryState(
      bankedPoints: (data['banked_points'] as num?)?.toInt() ?? 0,
      selectedTheme: data['selected_theme'] as String? ?? '#A9A9A9',
      unlockedThemes: List<String>.from(data['unlocked_themes'] ?? const []),
      unlockedTapSounds: List<String>.from(data['unlocked_tap_sounds'] ?? const []),
      unlockedBgMusic: List<String>.from(data['unlocked_bg_music'] ?? const []),
    );
  }

  final int bankedPoints;
  final String selectedTheme;
  final List<String> unlockedThemes;
  final List<String> unlockedTapSounds;
  final List<String> unlockedBgMusic;

  bool isUnlocked({
    required String itemType,
    required String itemId,
  }) {
    switch (itemType) {
      case 'theme':
        return unlockedThemes.contains(itemId);
      case 'tap_sound':
        return unlockedTapSounds.contains(itemId);
      case 'bg_music':
        return unlockedBgMusic.contains(itemId);
      default:
        return false;
    }
  }

  ShopInventoryState applyPurchasedItem({
    required int updatedBankedPoints,
    required String itemType,
    required String itemId,
  }) {
    final nextThemes = List<String>.from(unlockedThemes);
    final nextTapSounds = List<String>.from(unlockedTapSounds);
    final nextBgMusic = List<String>.from(unlockedBgMusic);

    switch (itemType) {
      case 'theme':
        if (!nextThemes.contains(itemId)) {
          nextThemes.add(itemId);
        }
        break;
      case 'tap_sound':
        if (!nextTapSounds.contains(itemId)) {
          nextTapSounds.add(itemId);
        }
        break;
      case 'bg_music':
        if (!nextBgMusic.contains(itemId)) {
          nextBgMusic.add(itemId);
        }
        break;
    }

    return ShopInventoryState(
      bankedPoints: updatedBankedPoints,
      selectedTheme: selectedTheme,
      unlockedThemes: nextThemes,
      unlockedTapSounds: nextTapSounds,
      unlockedBgMusic: nextBgMusic,
    );
  }
}

bool canAffordPurchase({
  required int bankedPoints,
  required int itemPrice,
}) {
  return bankedPoints >= itemPrice;
}
