import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OcrBlockDto {
  final String text;
  final List<int> quad; // [x1,y1,x2,y2,x3,y3,x4,y4] in px
  OcrBlockDto({required this.text, required this.quad});
}

class OcrService {
  OcrService({required this.baseUrl});
  final String baseUrl; // e.g., http://localhost:8000

  Future<List<OcrBlockDto>> detect(
    Uint8List imageBytes, {
    String filename = 'note.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl/ocr');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: http.MediaType('image', 'jpeg'),
      ),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('OCR failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final blocks = (data['blocks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final text = (m['text'] as String? ?? '').trim();
          final quadRaw = (m['quad'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt())
              .toList();
          // Ensure quad has 8 ints
          if (quadRaw.length != 8) {
            throw Exception('Invalid quad length: ${quadRaw.length}');
          }
          return OcrBlockDto(text: text, quad: quadRaw);
        })
        .toList();
    return blocks;
  }
}
