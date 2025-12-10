import 'dart:convert';
import 'package:http/http.dart' as http;

class AskResult {
  final String message;  // LLM-generated response
  AskResult({required this.message});
}

class AskService {
  final String baseUrl; // should point to embedding backend (serving /ask)
  AskService({required this.baseUrl});

  Future<AskResult> ask({
    required String question,
    List<Map<String, dynamic>> localChunks = const [],
    int matchCount = 5,
    int? courseId,
  }) async {
    final uri = Uri.parse('$baseUrl/ask');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'question': question,
        'local_chunks': localChunks,
        'match_count': matchCount,
        'course_id': courseId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Ask failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final message = (data['message'] ?? '').toString();
    return AskResult(message: message);
  }
}

