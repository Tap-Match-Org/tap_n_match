# Tap & Match - Project Status & Context

This file serves as the source of truth for the current state of the Tap & Match project. Read this at the start of every session to maintain context.

## 🚀 Recent Achievements & Implemented Features

### 1. Persistence & Account System
- **Local & Backend Sync:** Implemented a robust system using `shared_preferences` and a Python/FastAPI backend to isolate settings (audio, theme, accessibility) per account.
- **Auto-Login:** The game now remembers the last logged-in user.
- **Banked vs. Lifetime Points:**
  - `banked_points`: The spending currency (decreases when buying from Shop).
  - `lifetime_points`: The prestige currency (used for Leaderboard ranking, never decreases).

### 2. Accessibility & Gameplay "Juice"
- **Colorblind Mode:** Added unique symbols (Favorite, Cloud, Eco, Star) to grid boxes, toggleable in settings.
- **Level-Clear Juice:** Integrated `confetti` animations (explosive star-shaped) upon clearing levels or daily challenges.
- **Audio Refinement:** Added satisfying tap sounds to grid boxes and restricted global tap sounds to only trigger on interactive elements.

### 3. The Shop System
- **Restructured UI:** A compact, tabbed Shop UI with 4 categories:
  - **Themes:** Solid color options.
  - **BGs:** Special background images (Minecraft, Genshin, etc.).
  - **Taps:** Custom tap sound effects.
  - **Music:** Unlockable background tracks.
- **Purchase Logic:** Deducts `banked_points` and persists unlocked items to the backend inventory.

### 4. Admin Dashboard Enhancements
- **User Management:** Admins can now view `Banked` and `Lifetime` points.
- **Manual Point Adjustment:** Added a "Pts" button for admins to manually set or gift points to players.
- **Moderation:** Streamlined Ban/Unban and Progress Reset tools.

### 5. UI/UX Refinement
- **Sidebar Scaling:** Resized sidebar icons and reduced spacing (8px) to prevent overlapping on small/landscape screens.
- **Settings Dialog:** Fixed a 32px overlap in the settings menu by wrapping the column in a `SingleChildScrollView`.
- **Target Patterns:** Updated the difficulty engine to exclude white (index 0) boxes from target patterns for a better challenge.

### 6. TDD & Testing Infrastructure
- **Flutter Refactoring:** Decoupled business logic from UI by introducing the `AuthRepository` and `RegisterUser` use cases, enabling isolated unit testing.
- **Unit Testing:** Added `mocktail` and implemented comprehensive unit tests for `AuthRepository` (`test/repository/auth_repository_test.dart`).
- **Backend Testing:** Established a formal `pytest` suite for the FastAPI backend (`backend/test_main.py`), using a mock database for isolated endpoint verification.

### 7. Registration Wizard Redesign
- **Multi-Step Flow:** Refactored the registration process into a 4-screen wizard (Gmail -> Verify Code -> Username -> Password).
- **UI/UX:** Implemented adaptive card heights and smooth transitions using `AnimatedSwitcher`.
- **Consistency:** Maintained the pixelated theme and added a step-by-step progress indicator.
- **Architecture:** Moved registration logic into a dedicated `RegisterUser` use case in the application layer.

### 8. Bug Fixes & Test Stability
- **Shop Tutorial Tests:** Fixed compilation errors in `shop_tutorial_test.dart` by correctly passing `ShopRepository` instead of `httpClient` to `ShopPage`. Verified that all shop-related presentation and unit tests are passing.

## 🛠️ Current Project State
- **Backend:** `backend/main.py` is updated with all point systems and shop endpoints. Tested via `pytest`.
- **Database:** `users.db` schema includes all new fields (`banked_points`, `lifetime_points`, `unlocked_bg_music`).
- **Flutter:** Architecture refactoring in progress (Auth & Registration completed). Critical paths now have automated tests.

## 📌 Pending Tasks / Next Steps
- [ ] Refactor Shop & Points logic into repositories to expand test coverage.
- [ ] Add integration tests for the "Weekly Challenge" logic before implementation.
- [ ] Add more assets (Images/Audio) to the `assets/` folder.
- [ ] Register new assets in `lib/presentation/shop/shop_page.dart` catalog.
- [ ] Finalize "Weekly Challenge" logic (transitioning from 7-day newbie cycle).


---
*Last Updated: Tuesday, April 7, 2026*
