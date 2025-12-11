import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get serverUrl =>
      dotenv.env['SERVER_URL'] ?? 'http://localhost:8000';

  static String get embeddingUrl =>
      dotenv.env['EMBED_URL'] ?? 'http://localhost:8001';

  static String get askUrl =>
      dotenv.env['ASK_URL'] ?? 'http://localhost:8002';

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://project-id.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
