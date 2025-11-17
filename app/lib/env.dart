import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get serverUrl =>
      dotenv.env['SERVER_URL'] ?? 'http://localhost:8000';
}
