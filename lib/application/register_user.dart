import 'package:tap_n_match/repository/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<AuthResponse> execute({
    required String username,
    required String email,
    required String password,
    required String code,
  }) {
    return repository.register(
      username: username,
      email: email,
      password: password,
      code: code,
    );
  }
}
