import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/note_record.dart';
import 'pages/auth_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/my_notes_page.dart';
import 'pages/note_capture_page.dart';
import 'pages/note_photo_view_page.dart';
import 'pages/ai_tutor_page.dart';
import 'pages/community_page.dart';
import 'pages/profile_page.dart';
import 'theme.dart';
import 'widgets/sidebar.dart';
import 'objectbox.dart';
import 'services/ocr_service.dart';
import 'dart:typed_data';
import 'objectbox.g.dart';

class StudySyncApp extends StatelessWidget {
  final ObjectBox db;
  const StudySyncApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudySync',
      theme: AppTheme.dark(),
      home: _AppShell(db: db),
    );
  }
}

class _AppShell extends StatefulWidget {
  final ObjectBox db;
  const _AppShell({required this.db});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  bool isAuthenticated = false;
  ActiveTab activeTab = ActiveTab.dashboard;
  bool isCapturingNote = false;
  final List<NoteRecord> _notes = [];
  NoteRecord? _viewingNote;
  final List<NoteImage> _viewingImages = [];
  int _currentImageIndex = 0;
  final Set<int> _ocrInProgress = <int>{};
  final Set<int> _ocrFailed = <int>{};

  @override
  void initState() {
    super.initState();
    // Load persisted notes
    final loaded = widget.db.noteBox.getAll();
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notes.addAll(loaded);
  }

  Future<void> _runOcrForImage(NoteImage image) async {
    try {
      _ocrFailed.remove(image.id);
      _ocrInProgress.add(image.id);
      setState(() {});
      final ocr = OcrService(baseUrl: 'http://localhost:8000');
      final blocks = await ocr.detect(image.imageBytes);
      for (final b in blocks) {
        final quadI32 = Int32List.fromList(b.quad);
        final quadBytes = quadI32.buffer.asUint8List();
        final ob = OcrBlock(text: b.text, quad: quadBytes);
        ob.image.target = image;
        widget.db.ocrBlockBox.put(ob);
      }
      image.ocrProcessed = true;
      widget.db.noteImageBox.put(image);
    } catch (e) {
      print('OCR failed: $e');
      _ocrFailed.add(image.id);
    } finally {
      _ocrInProgress.remove(image.id);
      setState(() {});
    }
  }

  Future<void> _runOcrForPendingImages(NoteRecord note) async {
    final q = widget.db.noteImageBox
        .query(NoteImage_.note.equals(note.id))
        .build();
    final imgs = q.find();
    q.close();
    for (final img in imgs) {
      if (!img.ocrProcessed) {
        await _runOcrForImage(img);
      }
    }
  }

  int _sumOcrBlocksForImages(List<NoteImage> images) {
    int total = 0;
    for (final img in images) {
      final q = widget.db.ocrBlockBox
          .query(OcrBlock_.image.equals(img.id))
          .build();
      total += q.count();
      q.close();
    }
    return total;
  }

  void _openEditorNew() {
    setState(() {
      // Switch to image capture/text flow
      isCapturingNote = true;
      activeTab = ActiveTab.myNotes;
    });
  }

  void _cancelCapture() {
    setState(() {
      isCapturingNote = false;
    });
  }

  // _saveCaptured replaced by inline lambda in NoteCapturePage builder.

  void _openCaptured(NoteRecord note) {
    setState(() {
      _viewingNote = note;
      _viewingImages.clear();
      final q = widget.db.noteImageBox
          .query(NoteImage_.note.equals(note.id))
          .order(NoteImage_.createdAt)
          .build();
      _viewingImages.addAll(q.find());
      q.close();
      _currentImageIndex = 0;
    });
  }

  void _closeCaptured() {
    setState(() {
      _viewingNote = null;
    });
  }

  void _renameCaptured(NoteRecord note, String newTitle) {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      final updated = NoteRecord(
        title: newTitle,
        course: note.course,
        textContent: note.textContent,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        ocrProcessed: note.ocrProcessed,
        embeddingProcessed: note.embeddingProcessed,
      )..id = note.id;
      setState(() {
        _notes[idx] = updated;
        if (_viewingNote?.id == updated.id) {
          _viewingNote = updated;
        }
      });
      widget.db.noteBox.put(updated);
    }
  }

  void _updateCourse(NoteRecord note, String newCourse) {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      final updated = NoteRecord(
        title: note.title,
        course: newCourse,
        textContent: note.textContent,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        ocrProcessed: note.ocrProcessed,
        embeddingProcessed: note.embeddingProcessed,
      )..id = note.id;
      setState(() {
        _notes[idx] = updated;
        if (_viewingNote?.id == updated.id) {
          _viewingNote = updated;
        }
      });
      widget.db.noteBox.put(updated);
    }
  }

  void _deleteCaptured(NoteRecord note) {
    widget.db.noteBox.remove(note.id);
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      if (_viewingNote?.id == note.id) {
        _viewingNote = null;
      }
    });
  }

  Widget _buildContent() {
    if (activeTab == ActiveTab.myNotes && isCapturingNote) {
      return NoteCapturePage(
        onSave: (images, title, course, text) {
          final note = NoteRecord(
            title: title,
            course: course,
            textContent: text,
          );
          widget.db.noteBox.put(note);
          final createdImages = <NoteImage>[];
          for (final Uint8List imgBytes in images) {
            final img = NoteImage(imageBytes: imgBytes);
            img.note.target = note;
            widget.db.noteImageBox.put(img);
            createdImages.add(img);
          }
          setState(() {
            _notes.insert(0, note);
            isCapturingNote = false;
          });
          // Trigger OCR in background if we have an image
          if (createdImages.isNotEmpty) {
            for (final img in createdImages) {
              _runOcrForImage(img);
            }
          }
        },
        onCancel: _cancelCapture,
      );
    }
    if (activeTab == ActiveTab.myNotes && _viewingNote != null) {
      final note = _viewingNote!;
      // Load images for viewer
      final q = widget.db.noteImageBox
          .query(NoteImage_.note.equals(note.id))
          .order(NoteImage_.createdAt)
          .build();
      _viewingImages
        ..clear()
        ..addAll(q.find());
      q.close();
      final totalBlocks = _sumOcrBlocksForImages(_viewingImages);
      final hasProcessing = _viewingImages.any(
        (img) => _ocrInProgress.contains(img.id),
      );
      final hasFailed = _viewingImages.any(
        (img) => _ocrFailed.contains(img.id),
      );
      return NotePhotoViewPage(
        note: note,
        onBack: _closeCaptured,
        onRename: _renameCaptured,
        onUpdateCourse: _updateCourse,
        onDelete: (note) {
          _deleteCaptured(note);
        },
        isOcrProcessing: hasProcessing,
        isOcrFailed: hasFailed,
        ocrBlockCount: totalBlocks,
        onRetryOcr: () => _runOcrForPendingImages(note),
        images: _viewingImages,
        currentIndex: _currentImageIndex,
        onAddImages: (imgs) => _addImagesToNote(note, imgs),
        onDeleteCurrentImage: _viewingImages.isEmpty
            ? null
            : () => _deleteImage(_viewingImages[_currentImageIndex]),
        onPrevImage: _viewingImages.length > 1
            ? () {
                setState(() {
                  _currentImageIndex =
                      (_currentImageIndex - 1 + _viewingImages.length) %
                      _viewingImages.length;
                });
              }
            : null,
        onNextImage: _viewingImages.length > 1
            ? () {
                setState(() {
                  _currentImageIndex =
                      (_currentImageIndex + 1) % _viewingImages.length;
                });
              }
            : null,
      );
    }
    switch (activeTab) {
      case ActiveTab.dashboard:
        return const DashboardPage();
      case ActiveTab.myNotes:
        return MyNotesPage(
          onCreateNew: _openEditorNew,
          capturedNotes: _notes,
          onOpenCaptured: _openCaptured,
          onDeleteCaptured: _deleteCaptured,
        );
      case ActiveTab.aiTutor:
        return const AITutorPage();
      case ActiveTab.community:
        return const CommunityPage();
      case ActiveTab.profile:
        return const ProfilePage();
    }
  }

  // Methods for OCR processing moved to image-level below

  Future<void> _addImagesToNote(NoteRecord note, List<Uint8List> images) async {
    if (images.isEmpty) return;
    final created = <NoteImage>[];
    for (final imgBytes in images) {
      final img = NoteImage(imageBytes: imgBytes)..note.target = note;
      widget.db.noteImageBox.put(img);
      created.add(img);
    }
    if (_viewingNote?.id == note.id) {
      final q = widget.db.noteImageBox
          .query(NoteImage_.note.equals(note.id))
          .order(NoteImage_.createdAt)
          .build();
      _viewingImages
        ..clear()
        ..addAll(q.find());
      q.close();
      setState(() {});
    }
    for (final img in created) {
      await _runOcrForImage(img);
    }
  }

  Future<void> _deleteImage(NoteImage image) async {
    final qb = widget.db.ocrBlockBox
        .query(OcrBlock_.image.equals(image.id))
        .build();
    final blocks = qb.find();
    qb.close();
    if (blocks.isNotEmpty) {
      widget.db.ocrBlockBox.removeMany(blocks.map((e) => e.id).toList());
    }
    widget.db.noteImageBox.remove(image.id);
    _ocrFailed.remove(image.id);
    _ocrInProgress.remove(image.id);
    _viewingImages.removeWhere((img) => img.id == image.id);
    if (_currentImageIndex >= _viewingImages.length &&
        _viewingImages.isNotEmpty) {
      _currentImageIndex = _viewingImages.length - 1;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return AuthPage(onLogin: () => setState(() => isAuthenticated = true));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 768;
        return Scaffold(
          appBar: showSidebar ? null : AppBar(title: const Text('StudySync')),
          drawer: showSidebar
              ? null
              : Drawer(
                  child: Sidebar(
                    activeTab: activeTab,
                    onSelectTab: (tab) {
                      Navigator.of(context).pop();
                      setState(() => activeTab = tab);
                    },
                    onUpload: () {
                      setState(() {
                        activeTab = ActiveTab.myNotes;
                        isCapturingNote = true;
                      });
                    },
                    isInDrawer: true,
                  ),
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSidebar)
                Sidebar(
                  activeTab: activeTab,
                  onSelectTab: (tab) => setState(() => activeTab = tab),
                  onUpload: () {
                    setState(() {
                      activeTab = ActiveTab.myNotes;
                      isCapturingNote = true;
                    });
                  },
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
