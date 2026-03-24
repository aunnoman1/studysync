import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get serverUrl =>
      dotenv.env['SERVER_URL'] ?? 'http://localhost:8000';

  static String get embeddingUrl =>
      dotenv.env['EMBED_URL'] ?? 'http://localhost:8001';

  static String get askUrl => dotenv.env['ASK_URL'] ?? 'http://localhost:8002';

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://project-id.supabase.co';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String? get googleDesktopClientId {
    final v = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static String? get googleDesktopClientSecret {
    final v = dotenv.env['GOOGLE_DESKTOP_CLIENT_SECRET']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static String? get googleWebClientId {
    final v = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static String? get googleServerClientId {
    final v = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
