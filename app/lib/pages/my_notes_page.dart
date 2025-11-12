import 'package:flutter/material.dart';
import '../models/note_record.dart';
import '../theme.dart';

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class MyNotesPage extends StatelessWidget {
  final void Function() onCreateNew;
  final List<NoteRecord> capturedNotes;
  final void Function(NoteRecord note) onOpenCaptured;
  final void Function(NoteRecord note) onDeleteCaptured;

  const MyNotesPage({
    super.key,
    required this.onCreateNew,
    required this.capturedNotes,
    required this.onOpenCaptured,
    required this.onDeleteCaptured,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Notes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Notes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                    ElevatedButton(
                      onPressed: onCreateNew,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text('Add New'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: Row(
                          children: const [
                            _HeaderCell('Title', flex: 2),
                            _HeaderCell('Course'),
                            _HeaderCell('Date'),
                            SizedBox(width: 40), // actions column spacer
                          ],
                        ),
                      ),
                      // Render captured photo notes first
                      ...capturedNotes.map(
                        (photo) => InkWell(
                          onTap: () => onOpenCaptured(photo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.border)),
                            ),
                            child: Row(
                              children: [
                                _Cell(photo.title, flex: 2),
                                _Cell(photo.course),
                                _Cell(_formatDate(photo.createdAt)),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => onDeleteCaptured(photo),
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  const _Cell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
    );
  }
}



