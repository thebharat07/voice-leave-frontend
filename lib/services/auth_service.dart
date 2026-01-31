// services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';

class AuthService extends BaseService {

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}