import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tap_n_match/application/login_user.dart';
import 'package:tap_n_match/domain/auth/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUser loginUser;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUser = LoginUser(mockAuthRepository);
  });

  test('LoginUser executes correctly through the repository', () async {
    const email = 'test@example.com';
    const password = 'password123';
    final expectedResponse = {'user_id': 1, 'username': 'testuser'};

    when(() => mockAuthRepository.login(email, password))
        .thenAnswer((_) async => expectedResponse);

    final result = await loginUser.execute(email, password);

    expect(result, expectedResponse);
    verify(() => mockAuthRepository.login(email, password)).called(1);
  });
}
