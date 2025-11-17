import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import '../theme.dart';

class NoteCapturePage extends StatefulWidget {
  final void Function(
    List<Uint8List> imageBytesList,
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
        setState(() {
          _images.add(bytes);
        });
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
        final list = await Future.wait(files.map((f) => f.readAsBytes()));
        setState(() {
          _images.addAll(list);
        });
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
        final list = await Future.wait(files.map((f) => f.readAsBytes()));
        setState(() {
          _images.addAll(list);
        });
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  bool _isSaving = false;

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
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Create Note (Photo)',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Title',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Discrete Math - Lecture 4',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Course',
                  style: TextStyle(color: AppTheme.textSecondary),
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
                Container(
                  height: 360,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _images.isEmpty
                      ? const Text(
                          'No images selected',
                          style: TextStyle(color: AppTheme.textSecondary),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(12),
                          itemCount: _images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final img = _images[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    img,
                                    height: 336,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _images.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note (optional)',
                  style: TextStyle(color: AppTheme.textSecondary),
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

                                widget.onSave(
                                  _images,
                                  title,
                                  _selectedCourse,
                                  manualText,
                                );
                              } finally {
                                setState(() => _isSaving = false);
                              }
                            },
                      // Show a spinner or the text
                      child: _isSaving
                          ? const CircularProgressIndicator()
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
