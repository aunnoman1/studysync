import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'local_embedding/local_minilm_embedder.dart';

class ChunkEmbedding {
  final String chunkText;
  final Float32List vector;
  ChunkEmbedding({required this.chunkText, required this.vector});
}

/// Remote embedding API with automatic fallback to on-device ONNX MiniLM
/// (same model family as `sentence-transformers/all-MiniLM-L6-v2`).
class EmbeddingService {
  EmbeddingService({required this.baseUrl});
  final String baseUrl; // e.g., http://localhost:8001
  static const Duration _remoteTimeout = Duration(seconds: 2);

  Future<T> _runWithLocalFallback<T>({
    required Future<T> Function() remote,
    required Future<T> Function(LocalMinilmEmbedder local) local,
    required String context,
  }) async {
    Object? remoteError;
    try {
      return await remote();
    } catch (e) {
      remoteError = e;
    }

    final localEmbedder = await LocalMinilmEmbedder.tryLoad();
    if (localEmbedder != null) {
      return local(localEmbedder);
    }

    final localError =
        LocalMinilmEmbedder.lastLoadError ?? 'unknown local ONNX init error';
    throw Exception(
      '$context failed. Remote error: $remoteError. '
      'Offline fallback unavailable: $localError. '
      'Ensure `assets/onnx/minilm/model.onnx` exists and fully restart the app.',
    );
  }

  Future<List<ChunkEmbedding>> chunkAndEmbed(
    String text, {
    int chunkSize = 700,
    int chunkOverlap = 120,
  }) async {
    return _runWithLocalFallback(
      context: 'Chunk embedding',
      remote: () async {
        final uri = Uri.parse('$baseUrl/embedding/chunk-and-embed');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'text': text,
                'chunk_size': chunkSize,
                'chunk_overlap': chunkOverlap,
              }),
            )
            .timeout(_remoteTimeout);
        if (res.statusCode != 200) {
          throw Exception('Embedding failed: ${res.statusCode} ${res.body}');
        }
        final data = json.decode(res.body) as Map<String, dynamic>;
        return (data['embeddings'] as List<dynamic>? ?? [])
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
      },
      local: (local) async {
        final parts = local.chunkAndEmbed(
          text,
          chunkSize: chunkSize,
          chunkOverlap: chunkOverlap,
        );
        return parts
            .map((p) => ChunkEmbedding(chunkText: p.chunkText, vector: p.vector))
            .toList(growable: false);
      },
    );
  }

  Future<Float32List> embed(String text) async {
    return _runWithLocalFallback(
      context: 'Query embedding',
      remote: () async {
        final uri = Uri.parse('$baseUrl/embedding/embed');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'text': text}),
            )
            .timeout(_remoteTimeout);
        if (res.statusCode != 200) {
          throw Exception('Embedding failed: ${res.statusCode} ${res.body}');
        }
        final data = json.decode(res.body) as Map<String, dynamic>;
        final vecList = (data['vector'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(growable: false);
        return Float32List.fromList(vecList);
      },
      local: (local) async => local.embed(text),
    );
  }
}
