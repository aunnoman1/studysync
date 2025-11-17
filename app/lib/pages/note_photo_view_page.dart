import 'package:flutter/material.dart';
import '../models/note_record.dart';
import '../theme.dart';

class NotePhotoViewPage extends StatelessWidget {
  final NoteRecord note;
  final VoidCallback onBack;
  final void Function(NoteRecord note, String newTitle) onRename;
  final void Function(NoteRecord note, String newCourse) onUpdateCourse;
  final void Function(NoteRecord note) onDelete;
  final bool isOcrProcessing;
  final bool isOcrFailed;
  final int ocrBlockCount;
  final VoidCallback onRetryOcr;
  const NotePhotoViewPage({
    super.key,
    required this.note,
    required this.onBack,
    required this.onRename,
    required this.onUpdateCourse,
    required this.onDelete,
    required this.isOcrProcessing,
    required this.isOcrFailed,
    required this.ocrBlockCount,
    required this.onRetryOcr,
  });

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
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
                        title: const Text('Rename note'),
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
                      title: const Text('Delete note?'),
                      content: const Text('This action cannot be undone.'),
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
                    dropdownColor: const Color(0xFF374151),
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
                    OutlinedButton.icon(
                      onPressed: onRetryOcr,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry OCR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ] else if (note.ocrProcessed) ...[
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
                if (note.imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(note.imageBytes!, fit: BoxFit.contain),
                  ),
                if ((note.textContent ?? '').isNotEmpty) ...[
                  if (note.imageBytes != null) const SizedBox(height: 12),
                  const Text(
                    'Note',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.textContent!,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
