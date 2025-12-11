import 'package:objectbox/objectbox.dart' as obx; // library
import '../objectbox.dart'; // your helper class
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

  /// 1. Embeds the query using the remote service.
  /// 2. Performs a nearest neighbor search on local TextChunks.
  /// 3. Returns unique notes sorted by relevance score.
  /// [maxDistance] - Filter results. Lower is stricter (0.0 = exact match).
  /// For normalized vectors (Cosine/Euclidean):
  /// 0.0 = Identical, ~1.0 = 60 degrees apart, ~1.414 = Orthogonal (90 deg).
  /// A threshold of 1.3-1.4 usually captures relevant semantic matches.
  Future<List<SearchResult>> searchNotes(String query, {int limit = 10, double maxDistance = 1.4}) async {
    if (query.trim().isEmpty) return [];

    print('[Search] Searching for: "$query"');

    // 0. Check if we have any chunks at all
    final totalChunks = db.textChunkBox.count();
    print('[Search] Total text chunks in DB: $totalChunks');
    if (totalChunks == 0) {
      print('[Search] DB is empty, nothing to search.');
      return [];
    }

    // 1. Get embedding for the query
    final queryVector = await embeddingService.embed(query);
    print('[Search] Generated query vector of length: ${queryVector.length}');

    // 2. Query ObjectBox using nearest neighbor search
    // Note: We search for more chunks than the final limit to account for
    // multiple chunks belonging to the same note.
    final q = db.textChunkBox.query(
      TextChunk_.embedding.nearestNeighborsF32(
        queryVector,
        limit * 5, // Fetch even more candidates before filtering
      ),
    ).build();

    final chunks = q.findWithScores(); // Returns List<ObjectWithScore<TextChunk>>
    print('[Search] Raw nearest neighbor results found: ${chunks.length}');
    
    // Log top 3 scores to see what range we are dealing with
    for (var i = 0; i < chunks.length && i < 3; i++) {
      print('[Search] Result $i: Score=${chunks[i].score}, Chunk="${chunks[i].object.chunkText.substring(0, 20)}..."');
    }

    q.close();

    // 3. Deduplicate by Note ID, keeping the highest score (smallest distance)
    final Map<int, SearchResult> bestMatches = {};

    for (final result in chunks) {
      // Filter out low-relevance results
      if (result.score > maxDistance) {
        // print('[Search] Filtering out result with score ${result.score} > $maxDistance');
        continue;
      }

      final chunk = result.object;
      final note = chunk.note.target;
      
      // Skip if note is deleted or null
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
    print('[Search] Final results after deduplication & filtering: ${results.length}');
    
    // Sort by score (ascending distance = descending relevance)
    results.sort((a, b) => a.score.compareTo(b.score));

    return results.take(limit).toList();
  }
}

