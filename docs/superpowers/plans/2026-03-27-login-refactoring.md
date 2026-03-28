# Login Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor login logic to follow Clean Architecture principles using GetIt for dependency injection.

**Architecture:** Moving from direct HTTP calls in the UI to a layered approach: UI -> Use Case -> Repository Interface -> Data Source (HTTP). Dependency injection via GetIt will decouple the layers.

**Tech Stack:** Flutter, Dart, GetIt, HTTP.

---

### Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add get_it to pubspec.yaml**

```yaml
dependencies:
  ...
  get_it: ^7.6.0
```

- [ ] **Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: Success

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: add get_it dependency"
```

### Task 2: Implement Domain Entity

**Files:**
- Modify: `lib/domain/entities/user.dart`

- [ ] **Step 1: Define User entity**

```dart
class User {
  final int id;
  final String username;

  User({required this.id, required this.username});
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/entities/user.dart
git commit -m "feat: add User entity"
```

### Task 3: Implement Repository Interface

**Files:**
- Modify: `lib/repository/auth_repository.dart`

- [ ] **Step 1: Define AuthRepository interface**

```dart
import '../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/repository/auth_repository.dart
git commit -m "feat: add AuthRepository interface"
```

### Task 4: Implement Infrastructure Repository

**Files:**
- Create: `lib/infrastructure/fastapi_auth_repository.dart`

- [ ] **Step 1: Implement FastApiAuthRepository**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/user.dart';
import '../repository/auth_repository.dart';

class FastApiAuthRepository implements AuthRepository {
  final String baseUrl = 'http://localhost:8000';

  @override
  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User(
        id: (data['user_id'] as num).toInt(),
        username: data['username'],
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Invalid username or password');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/infrastructure/fastapi_auth_repository.dart
git commit -m "feat: add FastApiAuthRepository implementation"
```

### Task 5: Implement Application Use Case

**Files:**
- Modify: `lib/application/login_user.dart`

- [ ] **Step 1: Implement LoginUser use case**

```dart
import '../domain/entities/user.dart';
import '../repository/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<User> execute(String username, String password) {
    return repository.login(username, password);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/application/login_user.dart
git commit -m "feat: add LoginUser use case"
```

### Task 6: Setup Dependency Injection

**Files:**
- Create: `lib/injection_container.dart`

- [ ] **Step 1: Implement InjectionContainer**

```dart
import 'package:get_it/get_it.dart';
import 'application/login_user.dart';
import 'infrastructure/fastapi_auth_repository.dart';
import 'repository/auth_repository.dart';

final sl = GetIt.instance;

void init() {
  // Use Cases
  sl.registerLazySingleton(() => LoginUser(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => FastApiAuthRepository());
}
```

- [ ] **Step 2: Initialize in main.dart**

Modify `lib/main.dart` to call `init()`:

```dart
import 'injection_container.dart' as di;

void main() {
  di.init();
  runApp(const MyApp());
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/injection_container.dart lib/main.dart
git commit -m "feat: setup dependency injection with GetIt"
```

### Task 7: Refactor LoginPage

**Files:**
- Modify: `lib/presentation/auth/login_page.dart`

- [ ] **Step 1: Update imports and _loginUser method**

```dart
import '../../injection_container.dart';
import '../../application/login_user.dart';
// Remove http and json imports if no longer needed for other things
```

Update `_loginUser`:

```dart
  Future<void> _loginUser() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter username and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await sl<LoginUser>().execute(username, password);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/menu',
          arguments: {'user_id': user.id},
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/auth/login_page.dart
git commit -m "refactor: use LoginUser use case in LoginPage"
```

### Task 8: Verification

- [ ] **Step 1: Run Flutter build or analyze**

Run: `flutter analyze`
Expected: No issues related to refactoring.

- [ ] **Step 2: Manual Test (if possible)**

Ensure FastAPI is running and login still works as expected.
