import 'package:firebase_auth/firebase_auth.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        return AuthResponse.success(
          userId: 0, // Firebase uses UID (String), we need to decide how to map this to our int userId
          username: userCredential.user!.displayName ?? email.split('@')[0],
        );
      }
      return AuthResponse.error("Login failed");
    } on FirebaseAuthException catch (e) {
      return AuthResponse.error(e.message ?? "An error occurred during login");
    } catch (e) {
      return AuthResponse.error("An unexpected error occurred");
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(username);
        return AuthResponse.success(
          userId: 0,
          username: username,
        );
      }
      return AuthResponse.error("Firebase: User creation returned null");
    } on FirebaseAuthException catch (e) {
      return AuthResponse.error("Firebase Error (${e.code}): ${e.message}");
    } catch (e) {
      return AuthResponse.error("Firebase Unexpected Error: $e");
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
