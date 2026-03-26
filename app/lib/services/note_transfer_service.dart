import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;

import '../objectbox.dart';
import '../objectbox.g.dart';
import '../models/note_record.dart';
import 'note_archive_codec.dart';
import 'note_transfer_models.dart';

class NoteTransferService {
  final ObjectBox db;
  final NoteArchiveCodec _codec;

  NoteTransferService({required this.db, NoteArchiveCodec? codec})
    : _codec = codec ?? NoteArchiveCodec();

  Future<NoteExportResult> exportSelectedNotesToFile(List<int> noteIds) async {
    final exportedPaths = <String>[];
    int skipped = 0;

    for (final noteId in noteIds) {
      final archiveBytes = exportNotesToBytes(<int>[noteId]);
      final exportBaseName = _buildExportBaseName(<int>[noteId]);
      final filePath = await _pickExportPath(exportBaseName);
      if (filePath == null) {
        skipped++;
        continue;
      }
      final file = File(filePath);
      await file.writeAsBytes(archiveBytes, flush: true);
      exportedPaths.add(file.path);
    }

    return NoteExportResult(
      exportedCount: exportedPaths.length,
      skippedCount: skipped,
      filePaths: exportedPaths,
    );
  }

  Future<NoteImportResult?> importFromPickedFile() async {
    final typeGroup = fs.XTypeGroup(
      label: 'StudySync export',
      extensions: <String>['studysync', 'json'],
    );
    final file = await fs.openFile(
      acceptedTypeGroups: <fs.XTypeGroup>[typeGroup],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return importFromBytes(bytes);
  }

  NoteImportResult importFromBytes(Uint8List bytes) {
    final archive = _codec.decode(bytes);
    int imported = 0;
    int failed = 0;

    final existingTitles = db.noteBox.getAll().map((e) => e.title).toSet();

    for (final dto in archive.notes) {
      try {
        final noteTitle = _resolveDuplicateTitle(dto.title, existingTitles);
        existingTitles.add(noteTitle);

        final note = NoteRecord(
          title: noteTitle,
          course: dto.course,
          textContent: dto.textContent,
          createdAt: _parseDateOrNow(dto.createdAt),
          updatedAt: _parseDateOrNow(dto.updatedAt),
          ocrProcessed: dto.ocrProcessed,
          embeddingProcessed: dto.embeddingProcessed,
        );
        db.noteBox.put(note);

        for (final imageDto in dto.images) {
          final image = NoteImage(
            imageBytes: base64Decode(imageDto.imageBytesBase64),
            createdAt: _parseDateOrNow(imageDto.createdAt),
            ocrProcessed: imageDto.ocrProcessed,
          )..note.target = note;
          db.noteImageBox.put(image);

          for (final blockDto in imageDto.ocrBlocks) {
            final block = OcrBlock(
              text: blockDto.text,
              quad: base64Decode(blockDto.quadBase64),
              page: blockDto.page,
              readingOrder: blockDto.readingOrder,
            )..image.target = image;
            db.ocrBlockBox.put(block);
          }

          for (final diagramDto in imageDto.diagrams) {
            final diagram = NoteDiagram(
              imageBytes: base64Decode(diagramDto.imageBytesBase64),
              quad: base64Decode(diagramDto.quadBase64),
              explanation: diagramDto.explanation,
              embedding: diagramDto.embedding.isNotEmpty
                  ? Float32List.fromList(diagramDto.embedding)
                  : null,
            )..image.target = image;
            db.noteDiagramBox.put(diagram);
          }
        }

        for (final chunkDto in dto.textChunks) {
          final chunk = TextChunk(
            chunkText: chunkDto.chunkText,
            embedding: Float32List.fromList(chunkDto.embedding),
            orderIndex: chunkDto.orderIndex,
          )..note.target = note;
          db.textChunkBox.put(chunk);
        }

        imported++;
      } catch (_) {
        failed++;
      }
    }

    return NoteImportResult(importedCount: imported, failedCount: failed);
  }

  Uint8List exportNotesToBytes(List<int> noteIds) {
    final notes = noteIds
        .map(_buildNoteExportDto)
        .whereType<NoteExportDto>()
        .toList();
    final archive = NoteExportArchive(
      schemaVersion: NoteArchiveCodec.schemaVersion,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      appName: 'StudySync',
      notes: notes,
    );
    return _codec.encode(archive);
  }

  NoteExportArchive decodeArchive(Uint8List bytes) => _codec.decode(bytes);

  void deleteNoteTree(int noteId) {
    final qImgs = db.noteImageBox.query(NoteImage_.note.equals(noteId)).build();
    final images = qImgs.find();
    qImgs.close();

    for (final image in images) {
      final qBlocks = db.ocrBlockBox
          .query(OcrBlock_.image.equals(image.id))
          .build();
      final blocks = qBlocks.find();
      qBlocks.close();
      if (blocks.isNotEmpty) {
        db.ocrBlockBox.removeMany(blocks.map((b) => b.id).toList());
      }
      final qDiagrams = db.noteDiagramBox
          .query(NoteDiagram_.image.equals(image.id))
          .build();
      final diagrams = qDiagrams.find();
      qDiagrams.close();
      if (diagrams.isNotEmpty) {
        db.noteDiagramBox.removeMany(diagrams.map((d) => d.id).toList());
      }
    }
    if (images.isNotEmpty) {
      db.noteImageBox.removeMany(images.map((i) => i.id).toList());
    }

    final qChunks = db.textChunkBox
        .query(TextChunk_.note.equals(noteId))
        .build();
    final chunks = qChunks.find();
    qChunks.close();
    if (chunks.isNotEmpty) {
      db.textChunkBox.removeMany(chunks.map((c) => c.id).toList());
    }

    db.noteBox.remove(noteId);
  }

  NoteExportDto? _buildNoteExportDto(int noteId) {
    final note = db.noteBox.get(noteId);
    if (note == null) return null;

    final qImages = db.noteImageBox
        .query(NoteImage_.note.equals(note.id))
        .build();
    final images = qImages.find();
    qImages.close();

    final imageDtos = <NoteImageDto>[];
    for (final image in images) {
      final qBlocks = db.ocrBlockBox
          .query(OcrBlock_.image.equals(image.id))
          .build();
      final blocks = qBlocks.find();
      qBlocks.close();
      blocks.sort((a, b) => a.readingOrder.compareTo(b.readingOrder));
      final qDiagrams = db.noteDiagramBox
          .query(NoteDiagram_.image.equals(image.id))
          .build();
      final diagrams = qDiagrams.find();
      qDiagrams.close();
      imageDtos.add(
        NoteImageDto(
          imageBytesBase64: base64Encode(image.imageBytes),
          createdAt: image.createdAt.toUtc().toIso8601String(),
          ocrProcessed: image.ocrProcessed,
          ocrBlocks: blocks
              .map(
                (b) => OcrBlockDto(
                  text: b.text,
                  page: b.page,
                  readingOrder: b.readingOrder,
                  quadBase64: base64Encode(b.quad),
                ),
              )
              .toList(),
          diagrams: diagrams
              .map(
                (d) => NoteDiagramDto(
                  imageBytesBase64: base64Encode(d.imageBytes),
                  quadBase64: base64Encode(d.quad),
                  explanation: d.explanation,
                  embedding: d.embedding?.map((e) => e.toDouble()).toList() ?? [],
                ),
              )
              .toList(),
        ),
      );
    }

    final qChunks = db.textChunkBox
        .query(TextChunk_.note.equals(note.id))
        .build();
    final chunks = qChunks.find();
    qChunks.close();
    chunks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return NoteExportDto(
      sourceId: note.id,
      title: note.title,
      course: note.course,
      textContent: note.textContent,
      createdAt: note.createdAt.toUtc().toIso8601String(),
      updatedAt: note.updatedAt.toUtc().toIso8601String(),
      ocrProcessed: note.ocrProcessed,
      embeddingProcessed: note.embeddingProcessed,
      images: imageDtos,
      textChunks: chunks
          .map(
            (c) => TextChunkDto(
              chunkText: c.chunkText,
              embedding: c.embedding.map((e) => e.toDouble()).toList(),
              orderIndex: c.orderIndex,
            ),
          )
          .toList(),
    );
  }

  DateTime _parseDateOrNow(String raw) {
    if (raw.isEmpty) return DateTime.now();
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
  }

  String _resolveDuplicateTitle(String rawTitle, Set<String> existingTitles) {
    final base = rawTitle.trim().isEmpty ? 'Imported Note' : rawTitle.trim();
    if (!existingTitles.contains(base)) return base;
    int n = 2;
    while (existingTitles.contains('$base$n')) {
      n++;
    }
    return '$base$n';
  }

  String _buildExportBaseName(List<int> noteIds) {
    final notes = noteIds.map(db.noteBox.get).whereType<NoteRecord>().toList();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    if (notes.isEmpty) return 'studysync-notes-$stamp';

    final firstTitle = _sanitizeForFilename(notes.first.title);
    if (notes.length == 1) {
      return 'studysync-$firstTitle-$stamp';
    }

    final moreCount = notes.length - 1;
    return 'studysync-$firstTitle-and-$moreCount-more-$stamp';
  }

  String _sanitizeForFilename(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return 'note';
    value = value.replaceAll(RegExp(r'\s+'), '-').toLowerCase();
    value = value.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    value = value.replaceAll(RegExp(r'-+'), '-');
    value = value.replaceAll(RegExp(r'^[-_.]+|[-_.]+$'), '');
    if (value.isEmpty) return 'note';
    return value.length <= 60 ? value : value.substring(0, 60);
  }

  Future<String?> _pickExportPath(String exportBaseName) async {
    try {
      final location = await fs.getSaveLocation(
        suggestedName: '$exportBaseName.studysync',
        acceptedTypeGroups: <fs.XTypeGroup>[
          fs.XTypeGroup(
            label: 'StudySync export',
            extensions: <String>['studysync'],
          ),
        ],
      );
      return location?.path;
    } catch (_) {
      return null;
    }
  }
}
