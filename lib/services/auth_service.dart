// services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';

class AuthService extends BaseService {

  // --- Email/Password Auth ---
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // // --- Phone Auth Step 1: Send OTP ---
  // /// [phone] must be in E.164 format (e.g., +1234567890)
  // Future<void> signInWithPhone(String phone) async {
  //   await supabase.auth.signInWithOtp(
  //     phone: phone,
  //     shouldCreateUser: false, // Set to false if you only want to allow existing users
  //   );
  // }
  //
  // // --- Phone Auth Step 2: Verify OTP ---
  // Future<AuthResponse> verifyOtp(String phone, String token) async {
  //   return await supabase.auth.verifyOTP(
  //     type: OtpType.sms,
  //     phone: phone,
  //     token: token,
  //   );
  // }

  Future<AuthResponse> signInWithPhoneAndPassword(String phone, String password) async {
    return await supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  // Helper to check if user is logged in
  Session? get currentSession => supabase.auth.currentSession;
}