import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_n_match/presentation/auth/login_page.dart';
import 'package:tap_n_match/repository/auth_repository.dart';
import 'package:tap_n_match/infrastructure/firebase_auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFirebaseAuthRepo extends Mock implements FirebaseAuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    // Ensure SharedPreferences is clean
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shows banned message and does not save user data on banned login', (WidgetTester tester) async {
    // Arrange: mock login to return a banned response
    when(() => mockAuth.login(any(), any())).thenAnswer(
      (_) async => AuthResponse.banned(banReason: 'Violation'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authRepository: mockAuth, firebaseAuthRepository: MockFirebaseAuthRepo()),
      ),
    );

    // Act: Go through the login steps: select standard, enter username, next, enter password, login
    await tester.tap(find.text('Standard Login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'banned_user');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    // Enter password
    // The first TextField on step 3 is the password field
    final passwordField = find.byType(TextField).first;
    await tester.enterText(passwordField, 'somepassword');

    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    // Assert: SnackBar shown with banned message
    expect(find.text('Account banned'), findsOneWidget);

    // Assert: SharedPreferences still has no user data
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('user_id'), isNull);
    expect(prefs.getString('username'), isNull);
  });
}
