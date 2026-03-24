# Login Refactoring Design - Clean Architecture with GetIt

## 1. Overview
Refactor the current login implementation in `login_page.dart` to follow Clean Architecture principles (Domain, Application, Infrastructure layers) and use `GetIt` for dependency injection. This will decouple the UI from the HTTP logic and the FastAPI backend.

## 2. Architecture & Components

### 2.1 Domain Layer
*   **`User` Entity (`lib/domain/entities/user.dart`):**
    *   A simple data class representing the authenticated user.
    *   Fields: `int id`, `String username`.
*   **`AuthRepository` Interface (`lib/repository/auth_repository.dart`):**
    *   An abstract class defining the contract for authentication.
    *   Methods: `Future<User> login(String username, String password);`.

### 2.2 Infrastructure Layer
*   **`FastApiAuthRepository` (`lib/infrastructure/fastapi_auth_repository.dart`):**
    *   Implements the `AuthRepository` interface.
    *   Handles HTTP POST requests to `http://localhost:8000/login`.
    *   Parses JSON responses into `User` entities.

### 2.3 Application Layer
*   **`LoginUser` Use Case (`lib/application/login_user.dart`):**
    *   Depends on `AuthRepository` (injected via constructor).
    *   Methods: `Future<User> execute(String username, String password);`.
    *   Provides the business logic for logging in a user.

### 2.4 Dependency Injection
*   **`InjectionContainer` (`lib/injection_container.dart`):**
    *   Uses the `GetIt` package to register dependencies.
    *   Initializes at app startup (in `main.dart`).

## 3. Data Flow
1.  **UI:** `LoginPage` calls `GetIt.I<LoginUser>().execute(username, password)`.
2.  **Use Case:** `LoginUser` calls `AuthRepository.login(username, password)`.
3.  **Repository:** `FastApiAuthRepository` sends HTTP request to FastAPI.
4.  **Response:** `FastApiAuthRepository` returns a `User` entity (or throws an exception).
5.  **Success:** `LoginPage` navigates to `/menu`.
6.  **Failure:** `LoginPage` shows a `SnackBar` with the error message.

## 4. Testing Strategy
*   **Unit Tests:** Create mocks for `AuthRepository` to test `LoginUser` in isolation.
*   **Integration Tests:** Verify the interaction between `LoginPage` and the mock `LoginUser`.

## 5. Security & Error Handling
*   The UI will handle common errors (e.g., connection timeout, invalid credentials) by displaying user-friendly messages.
*   The backend currently handles plain-text password comparison; future updates could include token-based auth (JWT).
