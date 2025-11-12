import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';

/// Root note entity. Holds metadata and relations to OCR blocks and text chunks.
@Entity()
class NoteRecord {
  @Id()
  int id = 0;

  String title;
  String course;

  /// Optional, manually written content by the user.
  String? textContent;

  /// Optional raw image bytes of the note (e.g., captured/uploaded photo).
  @Property(type: PropertyType.byteVector)
  Uint8List? imageBytes;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  /// Processing flags
  /// Whether this note has been processed by the OCR pipeline.
  bool ocrProcessed;

  /// Whether this note has been embedded (chunking + vector embeddings).
  bool embeddingProcessed;

  /// Relations
  final ocrBlocks = ToMany<OcrBlock>();
  final textChunks = ToMany<TextChunk>();

  NoteRecord({
    required this.title,
    required this.course,
    this.textContent,
    this.imageBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ocrProcessed = false,
    this.embeddingProcessed = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
}

/// OCR detection block. Represents a detected text region with quadrilateral
/// coordinates suitable for digital reconstruction.
@Entity()
class OcrBlock {
  @Id()
  int id = 0;

  /// Back-link to owning note.
  final note = ToOne<NoteRecord>();

  /// The raw text detected in this block.
  String text;

  /// Page index (0-based) if multi-page capture; otherwise 0.
  int page = 0;

  /// Ordering within a page (0-based), to keep stable reconstruction order.
  int readingOrder = 0;

  /// Quadrilateral coordinates of the text region in image space.
  /// Packed as 8 float32 values (x1, y1, x2, y2, x3, y3, x4, y4) in pixels.
  @Property(type: PropertyType.byteVector)
  Uint8List quad;

  OcrBlock({
    required this.text,
    required this.quad,
    this.page = 0,
    this.readingOrder = 0,
  });
}

/// Embedding chunk for semantic search / RAG. Chunking is independent of OCR.
@Entity()
class TextChunk {
  @Id()
  int id = 0;

  /// Back-link to owning note.
  final note = ToOne<NoteRecord>();

  /// The chunked text used to generate the embedding.
  String chunkText;

  /// Embedding vector; adjust dimensions to match your model (e.g., 384).
  @HnswIndex(dimensions: 384)
  @Property(type: PropertyType.floatVector)
  Float32List embedding;

  /// Optional ordering field to preserve original text order if needed.
  int orderIndex = 0;

  TextChunk({
    required this.chunkText,
    required this.embedding,
    this.orderIndex = 0,
  });
}
