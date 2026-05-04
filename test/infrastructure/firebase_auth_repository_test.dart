import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tap_n_match/infrastructure/firebase_auth_repository.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late FirebaseAuthRepository repository;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    repository = FirebaseAuthRepository(firebaseAuth: mockAuth);

    when(() => mockUserCredential.user).thenReturn(mockUser);
    when(() => mockUser.displayName).thenReturn('testuser');
  });

  group('FirebaseAuthRepository', () {
    test('login returns success when Firebase sign in is successful', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@gmail.com',
            password: 'password123',
          )).thenAnswer((_) async => mockUserCredential);

      final result = await repository.login('test@gmail.com', 'password123');

      expect(result.status, AuthStatus.success);
      expect(result.username, 'testuser');
    });

    test('login returns error when Firebase throws FirebaseAuthException', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@gmail.com',
            password: 'wrong-password',
          )).thenThrow(FirebaseAuthException(code: 'wrong-password', message: 'Invalid password'));

      final result = await repository.login('test@gmail.com', 'wrong-password');

      expect(result.status, AuthStatus.error);
      expect(result.errorMessage, 'Invalid password');
    });

    test('register returns success when Firebase user creation is successful', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: 'new@gmail.com',
            password: 'password123',
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async => {});

      final result = await repository.register(
        email: 'new@gmail.com',
        password: 'password123',
        username: 'newuser',
      );

      expect(result.status, AuthStatus.success);
      expect(result.username, 'newuser');
      verify(() => mockUser.updateDisplayName('newuser')).called(1);
    });
  });
}
