import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme.dart';

class NoteEditorPage extends StatefulWidget {
  final bool isNew;
  final Note? note;
  final VoidCallback onBack;
  const NoteEditorPage({
    super.key,
    required this.isNew,
    required this.onBack,
    this.note,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController titleController;
  late final TextEditingController courseController;
  late final TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.isNew ? '' : widget.note?.title ?? '');
    courseController = TextEditingController(text: widget.isNew ? '' : widget.note?.course ?? '');
    contentController = TextEditingController(text: widget.isNew ? '' : widget.note?.content ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    courseController.dispose();
    contentController.dispose();
    super.dispose();
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
              Text(
                widget.isNew ? 'Create New Note' : 'Edit Note',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
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
                  children: [
                    Expanded(
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(hintText: 'Note Title'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: courseController,
                        decoration: const InputDecoration(hintText: 'Course Code (e.g., CS201)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: TextField(
                    controller: contentController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(hintText: 'Start typing your digitized note here...'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onBack,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Save'),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}


