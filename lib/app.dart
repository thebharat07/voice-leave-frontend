import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voiceleave/screens/admin_screen.dart';
import 'package:voiceleave/screens/authority_home.dart';
import 'package:voiceleave/screens/faculty_home.dart';
import 'package:voiceleave/screens/login_screen.dart';
import 'package:voiceleave/screens/signup_screen.dart';



class VoiceLeave extends StatelessWidget {
  const VoiceLeave({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceLeave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        'login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/faculty': (_) => const FacultyHome(),
        '/authority': (_) => const AuthorityHome()
      },

    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    }

    final role = session.user.userMetadata?['role'];

    print("role: $role");

    switch (role) {
      case 'faculty':
        return const FacultyHome();
      case 'authority':
        return const AuthorityHome();
      case 'admin':
        return const AdminScreen();
      default:
        return const LoginScreen();
    }
  }
}

