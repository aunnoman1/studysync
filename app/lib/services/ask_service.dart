import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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

  Stream<String> askStream({
    required String question,
    List<Map<String, dynamic>> localChunks = const [],
    int matchCount = 5,
    int? courseId,
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/ask/stream'))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode({
        'question': question,
        'local_chunks': localChunks,
        'match_count': matchCount,
        'course_id': courseId,
      });
    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw Exception('Ask stream failed: ${response.statusCode}');
    }
    await for (final line in response.stream
        .toStringStream()
        .transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6);
      if (payload == '[DONE]') break;
      if (payload.startsWith('[ERROR]')) {
        throw Exception(payload.substring(7).trim());
      }
      yield payload;
    }
  }

  /// Sends a cropped diagram image to the Ollama VLM for explanation.
  /// Optionally includes [context] (e.g. OCR text from the same page).
  Future<String> explainDiagram(Uint8List imageBytes, {String? context}) async {
    final base64Image = base64Encode(imageBytes);
    final uri = Uri.parse('$baseUrl/explain-diagram');
    final body = <String, dynamic>{
      'image_base64': base64Image,
    };
    if (context != null && context.isNotEmpty) {
      body['context'] = context;
    }
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(minutes: 5));
    if (res.statusCode != 200) {
      throw Exception('Explain diagram failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['explanation'] ?? '').toString();
  }
}
