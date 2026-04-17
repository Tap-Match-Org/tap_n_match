import 'package:tap_n_match/domain/auth/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<Map<String, dynamic>> execute(String email, String password) {
    return repository.login(email, password);
  }
}
