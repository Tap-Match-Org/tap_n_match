# Shop Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable and trigger the tutorial overlay in the Point Shop.

**Architecture:** Use the existing Repository Pattern to fetch tutorial status and trigger the `GuidedTutorialOverlay` component.

**Tech Stack:** Flutter, Dart, Repository Pattern.

---

### Task 1: Update Domain Model

**Files:**
- Modify: `lib/domain/shop/shop_rules.dart`

- [ ] **Step 1: Add pendingTutorials to ShopInventoryState**

Update the class to include the tutorial status list.

```dart
class ShopInventoryState {
  final int bankedPoints;
  final String selectedTheme;
  final List<String> unlockedThemes;
  final List<String> unlockedTapSounds;
  final List<String> unlockedBgMusic;
  final List<String> pendingTutorials; // Add this

  const ShopInventoryState({
    required this.bankedPoints,
    required this.selectedTheme,
    required this.unlockedThemes,
    required this.unlockedTapSounds,
    required this.unlockedBgMusic,
    required this.pendingTutorials, // Add this
  });

  factory ShopInventoryState.fromUserData(Map<String, dynamic> data) {
    return ShopInventoryState(
      bankedPoints: (data['banked_points'] as num?)?.toInt() ?? 0,
      selectedTheme: data['selected_theme'] ?? "#A9A9A9",
      unlockedThemes: List<String>.from(data['unlocked_themes'] ?? []),
      unlockedTapSounds: List<String>.from(data['unlocked_tap_sounds'] ?? []),
      unlockedBgMusic: List<String>.from(data['unlocked_bg_music'] ?? []),
      pendingTutorials: List<String>.from(data['pending_tutorials'] ?? []), // Add this
    );
  }
}
```

- [ ] **Step 2: Update applyPurchasedItem in ShopInventoryState**

Ensure the tutorials are preserved when state is updated.

```dart
  ShopInventoryState applyPurchasedItem({
    required int updatedBankedPoints,
    required String itemType,
    required String itemId,
  }) {
    // ... (keep existing logic to update lists)
    return ShopInventoryState(
      bankedPoints: updatedBankedPoints,
      selectedTheme: selectedTheme,
      unlockedThemes: nextThemes,
      unlockedTapSounds: nextTapSounds,
      unlockedBgMusic: nextBgMusic,
      pendingTutorials: pendingTutorials, // Add this
    );
  }
```

- [ ] **Step 3: Commit**

```bash
git add lib/domain/shop/shop_rules.dart
git commit -m "feat: add pendingTutorials to ShopInventoryState"
```

---

### Task 2: Trigger Tutorial in ShopPage

**Files:**
- Modify: `lib/presentation/shop/shop_page.dart`

- [ ] **Step 1: Update _loadData to trigger tutorial**

Call `_queueTutorialIfNeeded` after data is loaded.

```dart
  Future<void> _loadData() async {
    final inventory = await _repository.fetchInventory(userId);
    if (inventory != null && mounted) {
      setState(() {
        bankedPoints = inventory.bankedPoints;
        selectedTheme = inventory.selectedTheme;
        unlockedThemes = inventory.unlockedThemes;
        unlockedTapSounds = inventory.unlockedTapSounds;
        unlockedBgMusic = inventory.unlockedBgMusic;
        isLoading = false;
      });
      // Trigger tutorial check
      _queueTutorialIfNeeded(inventory.pendingTutorials);
    }
  }
```

- [ ] **Step 2: Update _queueTutorialIfNeeded signature**

Change the parameter from `Map<String, dynamic>` to `List<String>`.

```dart
  void _queueTutorialIfNeeded(List<String> pendingTutorials) {
    if (_tutorialQueued || !pendingTutorials.contains(TutorialIds.shop)) {
      return;
    }

    _tutorialQueued = true;
    _showTutorialWhenReady();
  }
```

- [ ] **Step 3: Verify and Commit**

Run: `flutter test`
Expected: ALL PASS

```bash
git add lib/presentation/shop/shop_page.dart
git commit -m "feat: trigger tutorial overlay in ShopPage"
```

---

### Task 4: Push to Scrum Shop branch

- [ ] **Step 1: Commit any remaining changes**

```bash
git add .
git commit -m "feat: final shop improvements and tutorial integration"
```

- [ ] **Step 2: Push to remote**

```bash
git push origin develop
```
