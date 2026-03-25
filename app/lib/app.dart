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
import 'pages/drive_sync_settings_page.dart';
import 'theme.dart';
import 'widgets/sidebar.dart';
import 'widgets/note_delete_flow.dart';
import 'objectbox.dart';
import 'services/ocr_service.dart';
import 'services/embedding_service.dart';
import 'services/local_embedding/local_minilm_embedder.dart';
import 'services/ask_service.dart';
import 'services/search_service.dart';
import 'services/note_transfer_service.dart';
import 'services/drive_auth_service.dart';
import 'services/drive_sync_service.dart';
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
  String? _initialAiQuery; // Store initial query for AI Tutor
  final Set<int> _ocrInProgress = <int>{};
  final Set<int> _ocrFailed = <int>{};
  final Set<int> _embInProgress = <int>{};
  final Set<int> _embFailed = <int>{};
  late final AskService _askService;
  late final EmbeddingService _embeddingService;
  late final SearchService _searchService;
  late final NoteTransferService _noteTransferService;
  late final DriveAuthService _driveAuthService;
  late final DriveSyncService _driveSyncService;
  List<NoteSyncStatusRow> _noteSyncRows = const [];
  bool _driveConnected = false;

  @override
  void initState() {
    super.initState();
    _askService = AskService(baseUrl: Env.askUrl);
    _embeddingService = EmbeddingService(baseUrl: Env.embeddingUrl);
    _searchService = SearchService(
      db: widget.db,
      embeddingService: _embeddingService,
    );
    _noteTransferService = NoteTransferService(db: widget.db);
    _driveAuthService = DriveAuthService();
    _driveSyncService = DriveSyncService(
      db: widget.db,
      authService: _driveAuthService,
      transferService: _noteTransferService,
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
    Future.microtask(_refreshDriveSyncStatus);
    Future.microtask(LocalMinilmEmbedder.tryLoad);
  }

  Future<void> _runOcrForImage(NoteImage image) async {
    try {
      _ocrFailed.remove(image.id);
      _ocrInProgress.add(image.id);
      setState(() {});
      final ocr = OcrService(baseUrl: Env.serverUrl);
      // Send the blacked-out image to OCR (falls back to display image if no OCR version)
      final ocrBytes = image.ocrImageBytes ?? image.imageBytes;
      final blocks = await ocr.detect(ocrBytes);
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
      // Now run diagram explanations with OCR context
      if (image.diagrams.isNotEmpty) {
        final ocrText = blocks.map((b) => b.text).join(' ');
        _runDiagramExplanations(image, ocrText);
      }
    } catch (e) {
      print('OCR failed: $e');
      _ocrFailed.add(image.id);
    } finally {
      _ocrInProgress.remove(image.id);
      setState(() {});
    }
  }

  Future<void> _runDiagramExplanations(NoteImage image, String ocrContext) async {
    for (final diagram in image.diagrams) {
      if (diagram.explanation == null) {
        try {
          // 1. Get Explanation from VLM with OCR context
          final explanation = await _askService.explainDiagram(
            diagram.imageBytes,
            context: ocrContext,
          );
          diagram.explanation = explanation;
          
          // 2. Embed the text structurally 
          final embedding = await _embeddingService.embed(explanation);
          diagram.embedding = embedding;
          
          // 3. Save to database
          widget.db.noteDiagramBox.put(diagram);
          
          if (mounted) setState(() {});
        } catch (e) {
          print('Diagram extraction/embedding failed: $e');
        }
      }
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
    _noteTransferService.deleteNoteTree(note.id);
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
      if (_viewingNote?.id == note.id) {
        _viewingNote = null;
      }
    });
    Future.microtask(() => _refreshDriveSyncStatus());
  }

  Future<void> _importNotes() async {
    try {
      final result = await _noteTransferService.importFromPickedFile();
      if (result == null) return;
      final loaded = widget.db.noteBox.getAll();
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _notes
          ..clear()
          ..addAll(loaded);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.importedCount} note(s), failed ${result.failedCount}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _exportSelectedNotes(List<NoteRecord> selectedNotes) async {
    if (selectedNotes.isEmpty) return;
    try {
      final result = await _noteTransferService.exportSelectedNotesToFile(
        selectedNotes.map((n) => n.id).toList(),
      );
      if (!mounted) return;
      String message;
      if (result.exportedCount == 0) {
        message = 'Export cancelled. No notes were saved.';
      } else if (result.skippedCount > 0) {
        message =
            'Exported ${result.exportedCount} note(s). Skipped ${result.skippedCount}.';
      } else {
        message = 'Exported ${result.exportedCount} note(s).';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _reloadNotesFromDb() {
    final loaded = widget.db.noteBox.getAll();
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _notes
        ..clear()
        ..addAll(loaded);
      if (_viewingNote != null) {
        final id = _viewingNote!.id;
        final match = loaded.where((n) => n.id == id).toList();
        _viewingNote = match.isNotEmpty ? match.first : null;
      }
    });
  }

  /// Sync row for the open note (falls back to local-only if not in index yet).
  NoteSyncStatusRow _syncRowForNote(NoteRecord note) {
    for (final r in _noteSyncRows) {
      if (r.localNote?.id == note.id) return r;
    }
    return NoteSyncStatusRow(
      key: note.title.toLowerCase(),
      displayTitle: note.title,
      state: NoteCloudState.localOnly,
      localNote: note,
      driveFile: null,
      latestTimestamp: note.updatedAt,
      conflictResolved: false,
    );
  }

  Future<void> _handleNoteDeleteFromViewer(NoteRecord note) async {
    await NoteDeleteFlow.showForRow(
      context,
      row: _syncRowForNote(note),
      driveConnected: _driveConnected,
      onDeleteLocalFull: _deleteCaptured,
      onDeleteDriveFile: _deleteDriveFile,
      onDeleteLocalCopy: _deleteLocalCopy,
      onDeleteSyncedBoth: _deleteSyncedBoth,
    );
  }

  Future<void> _refreshDriveSyncStatus() async {
    final auth = await _driveAuthService.getState();
    if (!mounted) return;
    _driveConnected = auth.isConnected;
    if (!_driveConnected) {
      setState(() {
        _noteSyncRows = _notes
            .map(
              (n) => NoteSyncStatusRow(
                key: n.title.toLowerCase(),
                displayTitle: n.title,
                state: NoteCloudState.localOnly,
                localNote: n,
                driveFile: null,
                latestTimestamp: n.updatedAt,
                conflictResolved: false,
              ),
            )
            .toList();
      });
      return;
    }

    try {
      final result = await _driveSyncService.refreshIndex();
      _reloadNotesFromDb();
      if (!mounted) return;
      setState(() {
        _noteSyncRows = result.rows;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _noteSyncRows = _notes
            .map(
              (n) => NoteSyncStatusRow(
                key: n.title.toLowerCase(),
                displayTitle: n.title,
                state: NoteCloudState.localOnly,
                localNote: n,
                driveFile: null,
                latestTimestamp: n.updatedAt,
                conflictResolved: false,
              ),
            )
            .toList();
      });
    }
  }

  Future<void> _uploadAllLocalOnly() async {
    final summary = await _driveSyncService.uploadAllLocalOnly();
    await _refreshDriveSyncStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Uploaded ${summary.uploaded} local note(s). Failed: ${summary.failed}.',
        ),
      ),
    );
  }

  Future<void> _downloadAllDriveOnly() async {
    final summary = await _driveSyncService.downloadAllDriveOnly();
    await _refreshDriveSyncStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloaded ${summary.downloaded} Drive note(s). Failed: ${summary.failed}.',
        ),
      ),
    );
  }

  Future<void> _uploadLocalNote(NoteRecord note) async {
    await _driveSyncService.uploadLocalNote(note.id);
    await _refreshDriveSyncStatus();
  }

  Future<void> _downloadDriveOnlyNote(String driveFileId) async {
    await _driveSyncService.downloadDriveOnlyNote(driveFileId);
    await _refreshDriveSyncStatus();
  }

  Future<void> _deleteLocalCopy(NoteRecord note) async {
    await _driveSyncService.deleteLocalCopy(note.id);
    _reloadNotesFromDb();
    await _refreshDriveSyncStatus();
  }

  Future<void> _deleteDriveFile(String driveFileId) async {
    await _driveSyncService.deleteDriveFile(driveFileId);
    _reloadNotesFromDb();
    await _refreshDriveSyncStatus();
  }

  Future<void> _deleteSyncedBoth(NoteRecord note, String driveFileId) async {
    await _driveSyncService.deleteSyncedBoth(note.id, driveFileId);
    _reloadNotesFromDb();
    await _refreshDriveSyncStatus();
  }

  Widget _buildContent() {
    if (activeTab == ActiveTab.myNotes && isCapturingNote) {
      return NoteCapturePage(
        onSave: (processedImages, title, course, text) {
          final note = NoteRecord(
            title: title,
            course: course,
            textContent: text,
          );
          widget.db.noteBox.put(note);
          final createdImages = <NoteImage>[];

          for (final result in processedImages) {
            final img = NoteImage(
              imageBytes: result.displayImageBytes,
              ocrImageBytes: result.ocrImageBytes,
            );
            img.note.target = note;
            
            // Add identified diagrams
            for (final diagram in result.diagrams) {
              final nd = NoteDiagram(
                 imageBytes: diagram.imageBytes,
                 quad: Uint8List.fromList(diagram.quad),
              );
              nd.image.target = img;
              img.diagrams.add(nd);
            }

            widget.db.noteImageBox.put(img);
            createdImages.add(img);
          }
          setState(() {
            _notes.insert(0, note);
            isCapturingNote = false;
          });
          // Trigger OCR in background (diagram explanations now run after OCR completes)
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
        onDelete: () => _handleNoteDeleteFromViewer(note),
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
          onAskTutor: (query) {
            setState(() {
              activeTab = ActiveTab.aiTutor;
              _initialAiQuery = query;
            });
          },
        );
      case ActiveTab.myNotes:
        return MyNotesPage(
          onCreateNew: _openEditorNew,
          capturedNotes: _notes,
          onOpenCaptured: _openCaptured,
          onDeleteCaptured: _deleteCaptured,
          onExportSelected: _exportSelectedNotes,
          onImportNotes: _importNotes,
          driveConnected: _driveConnected,
          syncRows: _noteSyncRows,
          onRefreshSync: _refreshDriveSyncStatus,
          onUploadAllLocalOnly: _uploadAllLocalOnly,
          onDownloadAllDriveOnly: _downloadAllDriveOnly,
          onUploadLocalNote: _uploadLocalNote,
          onDownloadDriveOnlyNote: _downloadDriveOnlyNote,
          onDeleteLocalCopy: _deleteLocalCopy,
          onDeleteDriveFile: _deleteDriveFile,
          onDeleteSyncedBoth: _deleteSyncedBoth,
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
        final query = _initialAiQuery;
        // Reset query after passing it once to avoid re-triggering on rebuilds
        if (_initialAiQuery != null) {
          // We clear it in the next frame or let the page handle it.
          // Better: pass it and let the page consume it.
          // But since build() is pure, we should clear it in a state update callback from the page
          // or just pass it as a one-off "initial" param which the page state reads only on init.
          // However, since AITutorPage stays in the tree (ActiveTab switches),
          // we might need to force a re-init if the widget is rebuilt with a new query.
          // A simple way is to pass a unique key when we have a query, or handle didUpdateWidget.
          // For now, let's pass it. We'll clear the state variable here to ensure it's not reused.
          // This side-effect in build is not ideal but works for simple nav.
          // Better: wrap in a microtask to clear.
          Future.microtask(() => _initialAiQuery = null);
        }
        return AITutorPage(
          db: widget.db,
          askService: _askService,
          initialQuery: query,
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
      case ActiveTab.cloudSync:
        return DriveSyncSettingsPage(
          authService: _driveAuthService,
          syncService: _driveSyncService,
          onSyncCompleted: _refreshDriveSyncStatus,
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
      final svc = _embeddingService;
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
