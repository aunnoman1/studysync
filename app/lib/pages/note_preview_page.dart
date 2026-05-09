import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../objectbox.dart';
import '../services/note_transfer_models.dart';
import '../services/note_transfer_service.dart';
import '../theme.dart';
import '../models/note_record.dart';
import '../widgets/note_digital_view.dart';
import 'dart:ui' as ui;

class NotePreviewPage extends StatefulWidget {
  final Uint8List bytes;
  final ObjectBox db;

  const NotePreviewPage({super.key, required this.bytes, required this.db});

  @override
  State<NotePreviewPage> createState() => _NotePreviewPageState();
}

class _NotePreviewPageState extends State<NotePreviewPage> {
  NoteExportArchive? _archive;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  void _decode() {
    try {
      final service = NoteTransferService(db: widget.db);
      _archive = service.decodeArchive(widget.bytes);
    } catch (e) {
      _error = 'Failed to preview note: $e';
    }
  }

  Future<void> _importNote() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final service = NoteTransferService(db: widget.db);
      final result = service.importFromBytes(widget.bytes);
      if (result.importedCount > 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Note imported to your library successfully!')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Note was already in your library or failed to import.')),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview Note')),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_archive == null || _archive!.notes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview Note')),
        body: const Center(child: Text('No notes found in attachment.')),
      );
    }

    final noteDto = _archive!.notes.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(noteDto.title.isNotEmpty ? noteDto.title : 'Preview Note'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importNote,
        icon: const Icon(Icons.download),
        label: const Text('Import to My Notes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              noteDto.title.isNotEmpty ? noteDto.title : 'Untitled Note',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (noteDto.course.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  noteDto.course.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (noteDto.textContent != null && noteDto.textContent!.isNotEmpty) ...[
              const Text(
                'Content',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  noteDto.textContent!,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (noteDto.images.isNotEmpty) ...[
              const Text(
                'Attached Photos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...noteDto.images.map((img) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DigitalImagePreview(imgDto: img),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DigitalImagePreview extends StatefulWidget {
  final NoteImageDto imgDto;
  const _DigitalImagePreview({required this.imgDto});
  @override
  State<_DigitalImagePreview> createState() => _DigitalImagePreviewState();
}

class _DigitalImagePreviewState extends State<_DigitalImagePreview> {
  int _srcW = 0;
  int _srcH = 0;
  bool _dimensionsResolved = false;
  bool _showDigital = true;
  late Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    try {
      _imageBytes = base64Decode(widget.imgDto.imageBytesBase64);
      _resolveImageDimensions();
    } catch (_) {
      _dimensionsResolved = true;
    }
  }

  Future<void> _resolveImageDimensions() async {
    try {
      final codec = await ui.instantiateImageCodec(_imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _srcW = frame.image.width;
          _srcH = frame.image.height;
          _dimensionsResolved = true;
        });
      }
      frame.image.dispose();
    } catch (_) {
      if (mounted) {
        setState(() {
          _dimensionsResolved = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dimensionsResolved) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasDigitalData = widget.imgDto.ocrBlocks.isNotEmpty || widget.imgDto.diagrams.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasDigitalData)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Digital View', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Switch(
                value: _showDigital,
                onChanged: (val) => setState(() => _showDigital = val),
                activeColor: AppTheme.blue,
              ),
            ],
          ),
        const SizedBox(height: 4),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (_showDigital && hasDigitalData && _srcW > 0 && _srcH > 0)
                ? NoteDigitalView(
                    ocrBlocks: widget.imgDto.ocrBlocks.map((b) => OcrBlock(
                      text: b.text,
                      quad: base64Decode(b.quadBase64),
                      page: b.page,
                      readingOrder: b.readingOrder,
                    )).toList(),
                    diagrams: widget.imgDto.diagrams.map((d) => NoteDiagram(
                      imageBytes: base64Decode(d.imageBytesBase64),
                      quad: base64Decode(d.quadBase64),
                      explanation: d.explanation,
                    )).toList(),
                    sourceWidth: _srcW,
                    sourceHeight: _srcH,
                    maxHeight: 400,
                  )
                : Image.memory(
                    _imageBytes,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ],
    );
  }
}
