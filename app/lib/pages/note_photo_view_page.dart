import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/note_record.dart';
import '../theme.dart';

class NotePhotoViewPage extends StatelessWidget {
  final NoteRecord note;
  final VoidCallback onBack;
  final void Function(NoteRecord note, String newTitle) onRename;
  final void Function(NoteRecord note, String newCourse) onUpdateCourse;
  final void Function(NoteRecord note, String? newText) onUpdateText;
  final void Function(NoteRecord note) onDelete;
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
  });

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
    onAddImages(list);
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
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title,
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
                  final controller = TextEditingController(text: note.title);
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
                    onRename(note, newTitle);
                  }
                },
                icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text(
                        'Delete note?',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      content: const Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    onDelete(note);
                  }
                },
                icon: const Icon(
                  Icons.delete_outline,
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
                'Created: ${_formatDate(note.createdAt)}',
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
                    value: note.course,
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
                      if (val != null && val != note.course) {
                        onUpdateCourse(note, val);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  if (isOcrProcessing) ...[
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
                  ] else if (isOcrFailed) ...[
                    OutlinedButton(
                      onPressed: onRetryOcr,
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
                        'OCR processed ($ocrBlockCount)',
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
                if (images.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Previous image',
                        onPressed: onPrevImage,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Page ${currentIndex + 1} of ${images.length}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next image',
                        onPressed: onNextImage,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () async {
                          // Desktop: open file selector; mobile/web: multi gallery
                          // Heuristic: if file_selector is available use it; otherwise fallback
                          // We attempt gallery first; users can also use desktop file selector below
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
                      if (onDeleteCurrentImage != null)
                        OutlinedButton(
                          onPressed: onDeleteCurrentImage,
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
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        images[currentIndex].imageBytes,
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
                if ((note.textContent ?? '').isNotEmpty) ...[
                  if (images.isNotEmpty) const SizedBox(height: 12),
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
                            text: note.textContent ?? '',
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
                            onUpdateText(
                              note,
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
                      note.textContent!,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ] else ...[
                  if (images.isNotEmpty) const SizedBox(height: 12),
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
                            onUpdateText(note, newText.trim());
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
                    if (isEmbProcessing) ...[
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
                    ] else if (isEmbFailed) ...[
                      OutlinedButton(
                        onPressed: onRetryEmbeddings,
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
                    ] else if (note.embeddingProcessed) ...[
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
                          'ready ($embChunkCount)',
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
