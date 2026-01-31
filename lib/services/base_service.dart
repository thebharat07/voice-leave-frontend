import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  String get userId => supabase.auth.currentUser?.id ?? '';

  Map<String, String> get authHeaders {
    final token = supabase.auth.currentSession?.accessToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}