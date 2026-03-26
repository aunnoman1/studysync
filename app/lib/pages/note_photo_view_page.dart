import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../models/note_record.dart';
import '../theme.dart';
import '../widgets/note_digital_view.dart';

class NotePhotoViewPage extends StatefulWidget {
  final NoteRecord note;
  final VoidCallback onBack;
  final void Function(NoteRecord note, String newTitle) onRename;
  final void Function(NoteRecord note, String newCourse) onUpdateCourse;
  final void Function(NoteRecord note, String? newText) onUpdateText;
  /// Same delete prompts as My Notes (local / cloud / synced).
  final Future<void> Function() onDelete;
  final bool isOcrProcessing;
  final bool isOcrFailed;
  final int ocrBlockCount;
  final VoidCallback onRetryOcr;
  final List<NoteImage> images;
  final int currentIndex;
  final void Function(List<Uint8List> images) onAddImages;
  final VoidCallback? onDeleteCurrentImage;
  final bool isEmbProcessing;
  final bool isEmbFailed;
  final int embChunkCount;
  final VoidCallback onRetryEmbeddings;
  final VoidCallback? onPrevImage;
  final VoidCallback? onNextImage;
  /// Fetches OCR blocks for a given image.
  final List<OcrBlock> Function(NoteImage image) fetchOcrBlocks;
  const NotePhotoViewPage({
    super.key,
    required this.note,
    required this.onBack,
    required this.onRename,
    required this.onUpdateCourse,
    required this.onUpdateText,
    required this.onDelete,
    required this.isOcrProcessing,
    required this.isOcrFailed,
    required this.ocrBlockCount,
    required this.onRetryOcr,
    required this.images,
    required this.currentIndex,
    required this.onAddImages,
    required this.onDeleteCurrentImage,
    required this.isEmbProcessing,
    required this.isEmbFailed,
    required this.embChunkCount,
    required this.onRetryEmbeddings,
    required this.onPrevImage,
    required this.onNextImage,
    required this.fetchOcrBlocks,
  });

  @override
  State<NotePhotoViewPage> createState() => _NotePhotoViewPageState();
}

class _NotePhotoViewPageState extends State<NotePhotoViewPage> {
  /// true = digital reconstruction, false = original raw image.
  bool _showDigital = true;

  /// Cached source image dimensions for the current page.
  int _srcWidth = 0;
  int _srcHeight = 0;
  bool _dimensionsResolved = false;

  @override
  void initState() {
    super.initState();
    _resolveImageDimensions();
  }

  @override
  void didUpdateWidget(covariant NotePhotoViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.images != widget.images) {
      _dimensionsResolved = false;
      _resolveImageDimensions();
    }
  }

  Future<void> _resolveImageDimensions() async {
    if (widget.images.isEmpty) return;
    final bytes = widget.images[widget.currentIndex].imageBytes;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _srcWidth = frame.image.width;
          _srcHeight = frame.image.height;
          _dimensionsResolved = true;
        });
      }
      frame.image.dispose();
    } catch (_) {
      if (mounted) {
        setState(() {
          _srcWidth = 0;
          _srcHeight = 0;
          _dimensionsResolved = true;
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _addFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;
    final list = await Future.wait(files.map((f) => f.readAsBytes()));
    widget.onAddImages(list);
  }

  bool get _hasOcrData => widget.ocrBlockCount > 0;

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightInputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            icon: Icons.auto_awesome_outlined,
            label: 'Digital',
            selected: _showDigital,
            onTap: () => setState(() => _showDigital = true),
          ),
          _ToggleChip(
            icon: Icons.image_outlined,
            label: 'Original',
            selected: !_showDigital,
            onTap: () => setState(() => _showDigital = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalView() {
    if (!_dimensionsResolved) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final currentImage = widget.images[widget.currentIndex];
    final ocrBlocks = widget.fetchOcrBlocks(currentImage);
    final diagrams = currentImage.diagrams.toList();

    if (ocrBlocks.isEmpty && diagrams.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.text_snippet_outlined,
                size: 48,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No OCR data for this page yet',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Switch to "Original" to view the raw image',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NoteDigitalView(
      ocrBlocks: ocrBlocks,
      diagrams: diagrams,
      sourceWidth: _srcWidth,
      sourceHeight: _srcHeight,
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Rename',
                onPressed: () async {
                  final controller = TextEditingController(text: widget.note.title);
                  final newTitle = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text(
                          'Rename note',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter new title',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(controller.text.trim()),
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                  if (newTitle != null && newTitle.isNotEmpty) {
                    widget.onRename(widget.note, newTitle);
                  }
                },
                icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  await widget.onDelete();
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${_formatDate(widget.note.createdAt)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              // Course selector
              Row(
                children: [
                  const Text(
                    'Course: ',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  DropdownButton<String>(
                    value: widget.note.course,
                    dropdownColor: AppTheme.surface,
                    items: const ['PF', 'OOP', 'DSA', 'DB']
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null && val != widget.note.course) {
                        widget.onUpdateCourse(widget.note, val);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  if (widget.isOcrProcessing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'OCR processing...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ] else if (widget.isOcrFailed) ...[
                    OutlinedButton(
                      onPressed: widget.onRetryOcr,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.refresh, size: 16),
                          SizedBox(width: 6),
                          Text('Retry OCR'),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14532D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OCR processed (${widget.ocrBlockCount})',
                        style: const TextStyle(
                          color: Color(0xFFBBF7D0),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.images.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Previous image',
                        onPressed: widget.onPrevImage,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Page ${widget.currentIndex + 1} of ${widget.images.length}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next image',
                        onPressed: widget.onNextImage,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View toggle (Digital / Original)
                      _buildViewToggle(),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () async {
                          await _addFromGallery();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add),
                            SizedBox(width: 6),
                            Text('Add Image(s)'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.onDeleteCurrentImage != null)
                        OutlinedButton(
                          onPressed: widget.onDeleteCurrentImage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.delete_outline,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 6),
                              Text('Delete Current'),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Content area: digital view or raw image
                  if (_showDigital)
                    _buildDigitalView()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          widget.images[widget.currentIndex].imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ] else ...[
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppTheme.lightInputFill,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No images',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () async {
                            await _addFromGallery();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined),
                              SizedBox(width: 6),
                              Text('Add Image(s)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((widget.note.textContent ?? '').isNotEmpty) ...[
                  if (widget.images.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Note',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () async {
                          final controller = TextEditingController(
                            text: widget.note.textContent ?? '',
                          );
                          final updatedText = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text(
                                'Edit note',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              content: SizedBox(
                                width: 480,
                                child: TextField(
                                  controller: controller,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: 'Write your note...',
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pop(controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (updatedText != null) {
                            widget.onUpdateText(
                              widget.note,
                              updatedText.trim().isEmpty ? null : updatedText,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit),
                            SizedBox(width: 6),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightInputFill,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.note.textContent!,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ] else ...[
                  if (widget.images.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Note',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () async {
                          final controller = TextEditingController(text: '');
                          final newText = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text(
                                'Add note',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              content: SizedBox(
                                width: 480,
                                child: TextField(
                                  controller: controller,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: 'Write your note...',
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pop(controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (newText != null && newText.trim().isNotEmpty) {
                            widget.onUpdateText(widget.note, newText.trim());
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add),
                            SizedBox(width: 6),
                            Text('Add'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Embeddings:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    if (widget.isEmbProcessing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'processing...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ] else if (widget.isEmbFailed) ...[
                      OutlinedButton(
                        onPressed: widget.onRetryEmbeddings,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.refresh, size: 16),
                            SizedBox(width: 6),
                            Text('Retry'),
                          ],
                        ),
                      ),
                    ] else if (widget.note.embeddingProcessed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ready (${widget.embChunkCount})',
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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

/// Small toggle chip for Digital / Original view switch.
class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
