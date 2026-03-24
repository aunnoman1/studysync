import '../objectbox.dart';
import '../models/note_record.dart';
import '../objectbox.g.dart';
import 'embedding_service.dart';

class SearchResult {
  final NoteRecord note;
  final double score;
  final String matchingChunk;

  SearchResult({
    required this.note,
    required this.score,
    required this.matchingChunk,
  });
}

class SearchService {
  final ObjectBox db;
  final EmbeddingService embeddingService;

  SearchService({required this.db, required this.embeddingService});

  /// 1. Embeds the query (remote embedding API, or on-device ONNX if offline).
  /// 2. Performs a nearest neighbor search on local TextChunks.
  /// 3. Returns unique notes sorted by relevance score.
  /// [maxDistance] - Filter results. Lower is stricter (0.0 = exact match).
  /// For normalized vectors (Cosine/Euclidean):
  /// 0.0 = Identical, ~1.0 = 60 degrees apart, ~1.414 = Orthogonal (90 deg).
  /// A threshold of 1.3-1.4 usually captures relevant semantic matches.
  Future<List<SearchResult>> searchNotes(
    String query, {
    int limit = 10,
    double maxDistance = 1.4,
  }) async {
    if (query.trim().isEmpty) return [];

    final totalChunks = db.textChunkBox.count();
    if (totalChunks == 0) {
      return [];
    }

    final queryVector = await embeddingService.embed(query);

    final q = db.textChunkBox
        .query(
          TextChunk_.embedding.nearestNeighborsF32(
            queryVector,
            limit * 5,
          ),
        )
        .build();

    final chunks = q.findWithScores();

    q.close();

    final Map<int, SearchResult> bestMatches = {};

    for (final result in chunks) {
      if (result.score > maxDistance) {
        continue;
      }

      final chunk = result.object;
      final note = chunk.note.target;

      if (note == null) continue;

      if (!bestMatches.containsKey(note.id)) {
        bestMatches[note.id] = SearchResult(
          note: note,
          score: result.score,
          matchingChunk: chunk.chunkText,
        );
      }
    }

    final results = bestMatches.values.toList();

    results.sort((a, b) => a.score.compareTo(b.score));

    return results.take(limit).toList();
  }
}
