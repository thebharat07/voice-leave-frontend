import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? "supabase_url",
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'supabase_anon_key',
  );

  runApp(const VoiceLeave());
}
