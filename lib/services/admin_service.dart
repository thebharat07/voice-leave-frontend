// services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class AdminService extends BaseService {
  static const String _baseUrl = 'https://voice-leave-jntugv.onrender.com';

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String title,
    required String department,
  }) async {
    // 1. Determine Role
    final String role = (title == 'Associate Prof' || title == 'Assistant Prof')
        ? 'faculty'
        : (title == 'Admin')
        ? 'admin'
        : 'authority';

    // 2. Determine Level
    final int level = {
      'Associate Prof': 1,
      'Assistant Prof': 1,
      'HOD': 2,
      'Dean': 3,
      'Principal': 4,
      'Vice Chancellor': 5,
      'Registrar': 6,
      'Admin': 100
    }[title] ?? 1;

    // 3. API Call
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/create-user'),
      headers: authHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
        'title': title,
        'phone': phone,
        'level': level,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }
}