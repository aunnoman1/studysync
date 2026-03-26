class NoteExportArchive {
  final int schemaVersion;
  final String exportedAt;
  final String appName;
  final List<NoteExportDto> notes;

  const NoteExportArchive({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appName,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt,
      'appName': appName,
      'noteCount': notes.length,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }

  static NoteExportArchive fromJson(Map<String, dynamic> json) {
    final rawNotes = (json['notes'] as List<dynamic>? ?? const []);
    return NoteExportArchive(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      exportedAt: (json['exportedAt'] as String?) ?? '',
      appName: (json['appName'] as String?) ?? 'StudySync',
      notes: rawNotes
          .whereType<Map<String, dynamic>>()
          .map(NoteExportDto.fromJson)
          .toList(),
    );
  }
}

class NoteExportDto {
  final String title;
  final String course;
  final String? textContent;
  final String createdAt;
  final String updatedAt;
  final bool ocrProcessed;
  final bool embeddingProcessed;
  final List<NoteImageDto> images;
  final List<TextChunkDto> textChunks;
  final int? sourceId;

  const NoteExportDto({
    required this.title,
    required this.course,
    required this.textContent,
    required this.createdAt,
    required this.updatedAt,
    required this.ocrProcessed,
    required this.embeddingProcessed,
    required this.images,
    required this.textChunks,
    required this.sourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'title': title,
      'course': course,
      'textContent': textContent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'ocrProcessed': ocrProcessed,
      'embeddingProcessed': embeddingProcessed,
      'images': images.map((i) => i.toJson()).toList(),
      'textChunks': textChunks.map((c) => c.toJson()).toList(),
    };
  }

  static NoteExportDto fromJson(Map<String, dynamic> json) {
    final rawImages = (json['images'] as List<dynamic>? ?? const []);
    final rawChunks = (json['textChunks'] as List<dynamic>? ?? const []);
    return NoteExportDto(
      sourceId: (json['sourceId'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? 'Imported Note',
      course: (json['course'] as String?) ?? 'PF',
      textContent: json['textContent'] as String?,
      createdAt: (json['createdAt'] as String?) ?? '',
      updatedAt: (json['updatedAt'] as String?) ?? '',
      ocrProcessed: (json['ocrProcessed'] as bool?) ?? false,
      embeddingProcessed: (json['embeddingProcessed'] as bool?) ?? false,
      images: rawImages
          .whereType<Map<String, dynamic>>()
          .map(NoteImageDto.fromJson)
          .toList(),
      textChunks: rawChunks
          .whereType<Map<String, dynamic>>()
          .map(TextChunkDto.fromJson)
          .toList(),
    );
  }
}

class NoteImageDto {
  final String imageBytesBase64;
  final String createdAt;
  final bool ocrProcessed;
  final List<OcrBlockDto> ocrBlocks;
  final List<NoteDiagramDto> diagrams;

  const NoteImageDto({
    required this.imageBytesBase64,
    required this.createdAt,
    required this.ocrProcessed,
    required this.ocrBlocks,
    this.diagrams = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'imageBytesBase64': imageBytesBase64,
      'createdAt': createdAt,
      'ocrProcessed': ocrProcessed,
      'ocrBlocks': ocrBlocks.map((b) => b.toJson()).toList(),
      'diagrams': diagrams.map((d) => d.toJson()).toList(),
    };
  }

  static NoteImageDto fromJson(Map<String, dynamic> json) {
    final rawBlocks = (json['ocrBlocks'] as List<dynamic>? ?? const []);
    final rawDiagrams = (json['diagrams'] as List<dynamic>? ?? const []);
    return NoteImageDto(
      imageBytesBase64: (json['imageBytesBase64'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
      ocrProcessed: (json['ocrProcessed'] as bool?) ?? false,
      ocrBlocks: rawBlocks
          .whereType<Map<String, dynamic>>()
          .map(OcrBlockDto.fromJson)
          .toList(),
      diagrams: rawDiagrams
          .whereType<Map<String, dynamic>>()
          .map(NoteDiagramDto.fromJson)
          .toList(),
    );
  }
}

class NoteDiagramDto {
  final String imageBytesBase64;
  final String quadBase64;
  final String? explanation;
  final List<double> embedding;

  const NoteDiagramDto({
    required this.imageBytesBase64,
    required this.quadBase64,
    this.explanation,
    this.embedding = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'imageBytesBase64': imageBytesBase64,
      'quadBase64': quadBase64,
      'explanation': explanation,
      'embedding': embedding,
    };
  }

  static NoteDiagramDto fromJson(Map<String, dynamic> json) {
    final rawEmbedding = (json['embedding'] as List<dynamic>? ?? const []);
    return NoteDiagramDto(
      imageBytesBase64: (json['imageBytesBase64'] as String?) ?? '',
      quadBase64: (json['quadBase64'] as String?) ?? '',
      explanation: json['explanation'] as String?,
      embedding: rawEmbedding.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class OcrBlockDto {
  final String text;
  final int page;
  final int readingOrder;
  final String quadBase64;

  const OcrBlockDto({
    required this.text,
    required this.page,
    required this.readingOrder,
    required this.quadBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'page': page,
      'readingOrder': readingOrder,
      'quadBase64': quadBase64,
    };
  }

  static OcrBlockDto fromJson(Map<String, dynamic> json) {
    return OcrBlockDto(
      text: (json['text'] as String?) ?? '',
      page: (json['page'] as num?)?.toInt() ?? 0,
      readingOrder: (json['readingOrder'] as num?)?.toInt() ?? 0,
      quadBase64: (json['quadBase64'] as String?) ?? '',
    );
  }
}

class TextChunkDto {
  final String chunkText;
  final List<double> embedding;
  final int orderIndex;

  const TextChunkDto({
    required this.chunkText,
    required this.embedding,
    required this.orderIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'chunkText': chunkText,
      'embedding': embedding,
      'orderIndex': orderIndex,
    };
  }

  static TextChunkDto fromJson(Map<String, dynamic> json) {
    final rawEmbedding = (json['embedding'] as List<dynamic>? ?? const []);
    return TextChunkDto(
      chunkText: (json['chunkText'] as String?) ?? '',
      embedding: rawEmbedding.map((e) => (e as num).toDouble()).toList(),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class NoteExportResult {
  final int exportedCount;
  final int skippedCount;
  final List<String> filePaths;

  const NoteExportResult({
    required this.exportedCount,
    required this.skippedCount,
    required this.filePaths,
  });
}

class NoteImportResult {
  final int importedCount;
  final int failedCount;

  const NoteImportResult({
    required this.importedCount,
    required this.failedCount,
  });
}
