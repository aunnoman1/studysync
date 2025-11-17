import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ChunkEmbedding {
  final String chunkText;
  final Float32List vector;
  ChunkEmbedding({required this.chunkText, required this.vector});
}

class EmbeddingService {
  EmbeddingService({required this.baseUrl});
  final String baseUrl; // e.g., http://localhost:8001

  Future<List<ChunkEmbedding>> chunkAndEmbed(
    String text, {
    int chunkSize = 700,
    int chunkOverlap = 120,
  }) async {
    final uri = Uri.parse('$baseUrl/embedding/chunk-and-embed');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'chunk_size': chunkSize,
        'chunk_overlap': chunkOverlap,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Embedding failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final items = (data['embeddings'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final chunkText = (m['chunk_text'] as String? ?? '').trim();
          final vecList = (m['vector'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList(growable: false);
          final vec = Float32List.fromList(vecList);
          return ChunkEmbedding(chunkText: chunkText, vector: vec);
        })
        .toList(growable: false);
    return items;
  }
}
