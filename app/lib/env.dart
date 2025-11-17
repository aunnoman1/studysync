import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get serverUrl =>
      dotenv.env['SERVER_URL'] ?? 'http://localhost:8000';

  static String get embeddingUrl =>
      dotenv.env['EMBED_URL'] ?? 'http://localhost:8001';
}
