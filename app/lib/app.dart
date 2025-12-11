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
import 'pages/search_page.dart';
import 'theme.dart';
import 'widgets/sidebar.dart';
import 'objectbox.dart';
import 'services/ocr_service.dart';
import 'services/embedding_service.dart';
import 'services/ask_service.dart';
import 'services/search_service.dart';
import 'dart:typed_data';
import 'objectbox.g.dart';
import 'env.dart';
import 'pages/note_debug_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudySyncApp extends StatelessWidget {
  final ObjectBox db;
  const StudySyncApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudySync',
      theme: AppTheme.light(),
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
  bool useGuestMode = false;
  ActiveTab activeTab = ActiveTab.dashboard;
  bool isCapturingNote = false;
  final List<NoteRecord> _notes = [];
  NoteRecord? _viewingNote;
  final List<NoteImage> _viewingImages = [];
  int _currentImageIndex = 0;
  final Set<int> _ocrInProgress = <int>{};
  final Set<int> _ocrFailed = <int>{};
  final Set<int> _embInProgress = <int>{};
  final Set<int> _embFailed = <int>{};
  late final AskService _askService;
  late final SearchService _searchService;

  @override
  void initState() {
    super.initState();
    _askService = AskService(baseUrl: Env.askUrl);
    _searchService = SearchService(
      db: widget.db,
      embeddingService: EmbeddingService(baseUrl: Env.embeddingUrl),
    );
    // Load persisted notes
    final loaded = widget.db.noteBox.getAll();
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notes.addAll(loaded);
    // Auth initial state + listener
    final client = Supabase.instance.client;
    isAuthenticated = client.auth.currentSession != null;
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          isAuthenticated = useGuestMode || session != null;
          if (session != null) {
            // After logging in, always land on dashboard
            activeTab = ActiveTab.dashboard;
            isCapturingNote = false;
            _viewingNote = null;
          }
        });
      }
    });
  }

  Future<void> _runOcrForImage(NoteImage image) async {
    try {
      _ocrFailed.remove(image.id);
      _ocrInProgress.add(image.id);
      setState(() {});
      final ocr = OcrService(baseUrl: Env.serverUrl);
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
      // If this was the last pending image for the note, kick off embeddings
      final parent = image.note.target;
      if (parent != null) {
        final q = widget.db.noteImageBox
            .query(NoteImage_.note.equals(parent.id))
            .build();
        final imgs = q.find();
        q.close();
        if (imgs.isNotEmpty && imgs.every((i) => i.ocrProcessed)) {
          // All pages processed, run embeddings for the whole note
          await _runEmbeddingsForNote(parent);
        }
      }
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
    // After attempting all pending images, if all are processed, trigger embeddings
    final q2 = widget.db.noteImageBox
        .query(NoteImage_.note.equals(note.id))
        .build();
    final updatedImgs = q2.find();
    q2.close();
    if (updatedImgs.isNotEmpty && updatedImgs.every((i) => i.ocrProcessed)) {
      await _runEmbeddingsForNote(note);
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

  void _updateNoteText(NoteRecord note, String? newText) {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      final updated = NoteRecord(
        title: note.title,
        course: note.course,
        textContent: (newText == null || newText.trim().isEmpty)
            ? null
            : newText.trim(),
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
        onUpdateText: _updateNoteText,
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
        isEmbProcessing: _embInProgress.contains(note.id),
        isEmbFailed: _embFailed.contains(note.id),
        embChunkCount: _countTextChunks(note.id),
        onRetryEmbeddings: () => _runEmbeddingsForNote(note),
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
        return DashboardPage(
          recentNotes: _notes,
          onOpenNote: (note) {
            setState(() {
              activeTab = ActiveTab.myNotes;
            });
            _openCaptured(note);
          },
        );
      case ActiveTab.myNotes:
        return MyNotesPage(
          onCreateNew: _openEditorNew,
          capturedNotes: _notes,
          onOpenCaptured: _openCaptured,
          onDeleteCaptured: _deleteCaptured,
        );
      case ActiveTab.search:
        return SearchPage(
          searchService: _searchService,
          onOpenNote: (note) {
            setState(() {
              // Switch to "My Notes" tab context but open the specific note
              activeTab = ActiveTab.myNotes;
            });
            _openCaptured(note);
          },
        );
      case ActiveTab.aiTutor:
        return AITutorPage(
          db: widget.db,
          askService: _askService,
        );
      case ActiveTab.community:
        return const CommunityPage();
      case ActiveTab.profile:
        return ProfilePage(
          onOpenAuth: (isLogin) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthPage(
                  onLogin: () => setState(() {
                    isAuthenticated = true;
                    useGuestMode = false;
                    activeTab = ActiveTab.dashboard;
                    isCapturingNote = false;
                    _viewingNote = null;
                  }),
                  onGuest: () => setState(() {
                    isAuthenticated = true;
                    useGuestMode = true;
                    activeTab = ActiveTab.dashboard;
                    isCapturingNote = false;
                    _viewingNote = null;
                  }),
                  initialIsLogin: isLogin,
                ),
              ),
            );
          },
        );
    }
  }

  // Methods for OCR and embedding processing

  int _countTextChunks(int noteId) {
    final q = widget.db.textChunkBox
        .query(TextChunk_.note.equals(noteId))
        .build();
    final c = q.count();
    q.close();
    return c;
  }

  void _clearEmbeddingsForNote(NoteRecord note) {
    final q = widget.db.textChunkBox
        .query(TextChunk_.note.equals(note.id))
        .build();
    final chunks = q.find();
    q.close();
    if (chunks.isNotEmpty) {
      widget.db.textChunkBox.removeMany(chunks.map((e) => e.id).toList());
    }
    final updated = NoteRecord(
      title: note.title,
      course: note.course,
      textContent: note.textContent,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      ocrProcessed: note.ocrProcessed,
      embeddingProcessed: false,
    )..id = note.id;
    widget.db.noteBox.put(updated);
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) _notes[idx] = updated;
    if (_viewingNote?.id == note.id) _viewingNote = updated;
  }

  static List<int> _quadToInts(Uint8List quadBytes) {
    final bd = quadBytes.buffer.asByteData(
      quadBytes.offsetInBytes,
      quadBytes.lengthInBytes,
    );
    final len = quadBytes.lengthInBytes ~/ 4;
    final out = <int>[];
    for (int i = 0; i < len; i++) {
      out.add(bd.getInt32(i * 4, Endian.host));
    }
    return out;
  }

  static int _minY(List<int> q) =>
      [q[1], q[3], q[5], q[7]].reduce((a, b) => a < b ? a : b);
  static int _minX(List<int> q) =>
      [q[0], q[2], q[4], q[6]].reduce((a, b) => a < b ? a : b);

  Future<void> _runEmbeddingsForNote(NoteRecord note) async {
    try {
      _embFailed.remove(note.id);
      _embInProgress.add(note.id);
      setState(() {});
      // Build concatenated text from all images' OCR blocks
      final qImgs = widget.db.noteImageBox
          .query(NoteImage_.note.equals(note.id))
          .order(NoteImage_.createdAt)
          .build();
      final imgs = qImgs.find();
      qImgs.close();
      final buffer = StringBuffer();
      for (final img in imgs) {
        final qBlocks = widget.db.ocrBlockBox
            .query(OcrBlock_.image.equals(img.id))
            .build();
        final blocks = qBlocks.find();
        qBlocks.close();
        blocks.sort((a, b) {
          final qa = _quadToInts(a.quad);
          final qb = _quadToInts(b.quad);
          final ay = _minY(qa), by = _minY(qb);
          if (ay != by) return ay.compareTo(by);
          final ax = _minX(qa), bx = _minX(qb);
          return ax.compareTo(bx);
        });
        for (final b in blocks) {
          final t = b.text.trim();
          if (t.isNotEmpty) buffer.writeln(t);
        }
        buffer.writeln();
      }
      final fullText = buffer.toString().trim();
      if (fullText.isEmpty) {
        _embFailed.add(note.id);
        return;
      }
      final svc = EmbeddingService(baseUrl: Env.embeddingUrl);
      final pairs = await svc.chunkAndEmbed(fullText);
      // Clear old embeddings and save new
      _clearEmbeddingsForNote(note);
      for (final p in pairs) {
        final chunk = TextChunk(chunkText: p.chunkText, embedding: p.vector)
          ..note.target = note;
        widget.db.textChunkBox.put(chunk);
      }
      final updated = NoteRecord(
        title: note.title,
        course: note.course,
        textContent: note.textContent,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        ocrProcessed: note.ocrProcessed,
        embeddingProcessed: true,
      )..id = note.id;
      widget.db.noteBox.put(updated);
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx != -1) _notes[idx] = updated;
      if (_viewingNote?.id == note.id) _viewingNote = updated;
    } catch (e) {
      print('Embeddings failed: $e');
      _embFailed.add(note.id);
    } finally {
      _embInProgress.remove(note.id);
      setState(() {});
    }
  }

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
    // Remove the image itself
    final parentNote = image.note.target;
    widget.db.noteImageBox.remove(image.id);
    _ocrFailed.remove(image.id);
    _ocrInProgress.remove(image.id);
    _viewingImages.removeWhere((img) => img.id == image.id);
    if (_currentImageIndex >= _viewingImages.length &&
        _viewingImages.isNotEmpty) {
      _currentImageIndex = _viewingImages.length - 1;
    }
    // Invalidate embeddings for the note and recompute if applicable
    if (parentNote != null) {
      // Clear existing embeddings
      _clearEmbeddingsForNote(parentNote);
      // If there are still images and all are OCR processed, re-run embeddings
      final qImgs = widget.db.noteImageBox
          .query(NoteImage_.note.equals(parentNote.id))
          .build();
      final remaining = qImgs.find();
      qImgs.close();
      if (remaining.isNotEmpty && remaining.every((i) => i.ocrProcessed)) {
        // Fire and forget; UI will update on completion
        // ignore: unawaited_futures
        _runEmbeddingsForNote(parentNote);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return AuthPage(
        onLogin: () => setState(() {
          isAuthenticated = true;
          useGuestMode = false;
          activeTab = ActiveTab.dashboard;
          isCapturingNote = false;
          _viewingNote = null;
        }),
        onGuest: () => setState(() {
          isAuthenticated = true;
          useGuestMode = true;
          activeTab = ActiveTab.dashboard;
          isCapturingNote = false;
          _viewingNote = null;
        }),
      );
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
          floatingActionButton:
              (activeTab == ActiveTab.myNotes && _viewingNote != null)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    final note = _viewingNote!;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NoteDebugPage(
                          note: note,
                          images: _viewingImages,
                          currentIndex: _currentImageIndex,
                          fetchOcrBlocks: (image) {
                            final q = widget.db.ocrBlockBox
                                .query(OcrBlock_.image.equals(image.id))
                                .build();
                            final blocks = q.find();
                            q.close();
                            blocks.sort(
                              (a, b) =>
                                  a.readingOrder.compareTo(b.readingOrder),
                            );
                            return blocks;
                          },
                          fetchTextChunks: (n) {
                            final q = widget.db.textChunkBox
                                .query(TextChunk_.note.equals(n.id))
                                .order(TextChunk_.orderIndex)
                                .build();
                            final chunks = q.find();
                            q.close();
                            return chunks;
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Debug'),
                )
              : null,
        );
      },
    );
  }
}
