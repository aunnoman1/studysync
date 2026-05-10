import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:image/image.dart' as img;
import '../theme.dart';
import 'diagram_editor_page.dart';

class DiagramExtraction {
  final Uint8List imageBytes;
  final List<int> quad;
  DiagramExtraction(this.imageBytes, this.quad);
}

class MaskedImageResult {
  /// Image with colored outlines around diagrams (for display in notes).
  final Uint8List displayImageBytes;

  /// Image with diagrams blacked out (sent to OCR).
  final Uint8List ocrImageBytes;
  final List<DiagramExtraction> diagrams;
  MaskedImageResult(this.displayImageBytes, this.ocrImageBytes, this.diagrams);
}

/// Isolate payload
class _ProcessPayload {
  final List<Uint8List> images;
  final List<List<Rect>> rects;
  _ProcessPayload(this.images, this.rects);
}

/// Runs in a background thread to prevent UI freezing while cropping/masking
Future<List<MaskedImageResult>> _processImagesIsolate(
  _ProcessPayload payload,
) async {
  final results = <MaskedImageResult>[];

  for (int i = 0; i < payload.images.length; i++) {
    final bytes = payload.images[i];
    final rects = payload.rects[i];

    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      results.add(MaskedImageResult(bytes, bytes, []));
      continue;
    }

    // Always bake orientation so EXIF rotation is applied to pixels.
    // This prevents the OCR server from receiving sideways images.
    decoded = img.bakeOrientation(decoded);

    if (rects.isEmpty) {
      // Re-encode to ensure consistent formatting
      final jpgBytes = img.encodeJpg(decoded, quality: 90);
      results.add(MaskedImageResult(jpgBytes, jpgBytes, []));
      continue;
    }

    // Make a copy for OCR (will be blacked out)
    final ocrCopy = decoded.clone();

    final extractions = <DiagramExtraction>[];

    // Process each marked diagram
    for (final r in rects) {
      int x = r.left.floor();
      int y = r.top.floor();
      int w = r.width.ceil();
      int h = r.height.ceil();

      // Safety clamp
      x = x < 0 ? 0 : x;
      y = y < 0 ? 0 : y;
      if (x + w > decoded.width) w = decoded.width - x;
      if (y + h > decoded.height) h = decoded.height - y;

      // Crop the diagram from original
      final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      final croppedBytes = img.encodeJpg(cropped, quality: 90);

      // Store it with quad coordinates
      final quad = [x, y, x + w, y, x + w, y + h, x, y + h];
      extractions.add(DiagramExtraction(croppedBytes, quad));

      // Draw colored outline on the DISPLAY image
      final outlineColor = img.ColorRgb8(0, 200, 255); // cyan
      img.drawRect(
        decoded,
        x1: x,
        y1: y,
        x2: x + w,
        y2: y + h,
        color: outlineColor,
        thickness: 3,
      );

      // Black out the OCR copy
      img.fillRect(
        ocrCopy,
        x1: x,
        y1: y,
        x2: x + w,
        y2: y + h,
        color: img.ColorRgb8(0, 0, 0),
      );
    }

    final displayBytes = img.encodeJpg(decoded, quality: 90);
    final ocrBytes = img.encodeJpg(ocrCopy, quality: 90);
    results.add(MaskedImageResult(displayBytes, ocrBytes, extractions));
  }

  return results;
}

class NoteCapturePage extends StatefulWidget {
  final void Function(
    List<MaskedImageResult> processedImages,
    String title,
    String course,
    String? text,
  )
  onSave;
  final VoidCallback onCancel;

  const NoteCapturePage({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<NoteCapturePage> createState() => _NoteCapturePageState();
}

class _NoteCapturePageState extends State<NoteCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _images = [];
  final List<List<Rect>> _diagramRects = [];
  bool _isPicking = false;
  final TextEditingController _titleController = TextEditingController(
    text: '',
  );
  final List<String> _courses = const ['PF', 'OOP', 'DSA', 'DB'];
  String _selectedCourse = 'PF';
  final TextEditingController _textController = TextEditingController(text: '');

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get _supportsCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _addImage(Uint8List bytes) {
    setState(() {
      _images.add(bytes);
      _diagramRects.add([]);
    });
  }

  Future<void> _pick(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        _addImage(bytes);
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  Future<void> _pickMultiFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final files = await _picker.pickMultiImage(imageQuality: 90);
      if (files.isNotEmpty) {
        for (final f in files) {
          final bytes = await f.readAsBytes();
          _addImage(bytes);
        }
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  Future<void> _pickFromFileSystem() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final typeGroup = fs.XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
      );
      final files = await fs.openFiles(
        acceptedTypeGroups: <fs.XTypeGroup>[typeGroup],
      );
      if (files.isNotEmpty) {
        for (final f in files) {
          final bytes = await f.readAsBytes();
          _addImage(bytes);
        }
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  Future<void> _openDiagramEditor(int index) async {
    final rects = await Navigator.of(context).push<List<Rect>>(
      MaterialPageRoute(
        builder: (_) => DiagramEditorPage(
          imageBytes: _images[index],
          initialRects: _diagramRects[index],
        ),
      ),
    );
    if (rects != null && mounted) {
      setState(() {
        _diagramRects[index] = rects;
      });
    }
  }

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(Icons.arrow_back, color: textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Create Note (Photo)',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.cardDecoration(isDark: isDark),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Title',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Discrete Math - Lecture 4',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Course',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCourse,
                  items: _courses
                      .map(
                        (c) =>
                            DropdownMenuItem<String>(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCourse = val);
                    }
                  },
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPicking || !_supportsCamera
                            ? null
                            : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Take Photo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPicking
                            ? null
                            : () => _isDesktop
                                  ? _pickFromFileSystem()
                                  : _pickMultiFromGallery(),
                        icon: const Icon(Icons.upload_file),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Upload Image(s)'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Image preview area ──
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 160,
                    maxHeight: 420,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightInputFill,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: _images.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  'No images selected',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            buildDefaultDragHandles: false,
                            padding: const EdgeInsets.all(10),
                            itemCount: _images.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final img = _images.removeAt(oldIndex);
                                final rects = _diagramRects.removeAt(oldIndex);
                                _images.insert(newIndex, img);
                                _diagramRects.insert(newIndex, rects);
                              });
                            },
                            itemBuilder: (context, index) {
                              final imgBytes = _images[index];
                              final hasMasks = _diagramRects[index].isNotEmpty;
                              return _ImageTile(
                                key: ValueKey('img_${imgBytes.hashCode}_$index'),
                                index: index,
                                imageBytes: imgBytes,
                                hasMasks: hasMasks,
                                isDark: isDark,
                                onEdit: () => _openDiagramEditor(index),
                                onRemove: () {
                                  setState(() {
                                    _images.removeAt(index);
                                    _diagramRects.removeAt(index);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Note (optional)',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 180,
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Write your note...',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      // Disable button if saving
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              try {
                                final title =
                                    _titleController.text.trim().isEmpty
                                    ? (_images.isEmpty
                                          ? 'Text Note'
                                          : 'Photo Note')
                                    : _titleController.text.trim();

                                final manualText =
                                    _textController.text.trim().isEmpty
                                    ? null
                                    : _textController.text.trim();

                                // Process diagram masking in a background isolate!
                                final payload = _ProcessPayload(
                                  _images,
                                  _diagramRects,
                                );
                                final processedImages = await compute(
                                  _processImagesIsolate,
                                  payload,
                                );

                                widget.onSave(
                                  processedImages,
                                  title,
                                  _selectedCourse,
                                  manualText,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to process image masks: $e',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                      // Show a spinner or the text
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text('Save'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single image row in the reorderable list.
/// Shows a thumbnail, index badge, size info, edit/delete actions, and a drag handle.
class _ImageTile extends StatelessWidget {
  final int index;
  final Uint8List imageBytes;
  final bool hasMasks;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ImageTile({
    super.key,
    required this.index,
    required this.imageBytes,
    required this.hasMasks,
    required this.isDark,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final sizeKb = (imageBytes.lengthInBytes / 1024).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // ── Drag handle ──
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(Icons.drag_handle_rounded, color: textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // ── Index badge ──
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Thumbnail ──
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageBytes,
              width: 72,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Image ${index + 1}',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${sizeKb} KB',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    if (hasMasks) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Diagrams marked',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // ── Edit (diagram) button ──
          IconButton(
            tooltip: hasMasks ? 'Edit diagrams' : 'Mark diagrams',
            onPressed: onEdit,
            icon: Icon(
              hasMasks ? Icons.architecture : Icons.crop_free,
              color: hasMasks ? Colors.green : textSecondary,
              size: 20,
            ),
          ),
          // ── Delete button ──
          IconButton(
            tooltip: 'Remove image',
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
