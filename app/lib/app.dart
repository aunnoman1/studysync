import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/captured_note.dart';
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
  final List<CapturedNote> _capturedNotes = [];
  CapturedNote? _viewingCaptured;

  @override
  void initState() {
    super.initState();
    // Load persisted notes
    final loaded = widget.db.capturedNoteBox.getAll();
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _capturedNotes.addAll(loaded);
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

  void _openCaptured(CapturedNote note) {
    setState(() {
      _viewingCaptured = note;
    });
  }

  void _closeCaptured() {
    setState(() {
      _viewingCaptured = null;
    });
  }

  void _renameCaptured(CapturedNote note, String newTitle) {
    final idx = _capturedNotes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      final updated = note.copyWith(title: newTitle);
      setState(() {
        _capturedNotes[idx] = updated;
        if (_viewingCaptured?.id == updated.id) {
          _viewingCaptured = updated;
        }
      });
      widget.db.capturedNoteBox.put(updated);
    }
  }

  void _updateCourse(CapturedNote note, String newCourse) {
    final idx = _capturedNotes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      final updated = note.copyWith(course: newCourse);
      setState(() {
        _capturedNotes[idx] = updated;
        if (_viewingCaptured?.id == updated.id) {
          _viewingCaptured = updated;
        }
      });
      widget.db.capturedNoteBox.put(updated);
    }
  }

  void _deleteCaptured(CapturedNote note) {
    widget.db.capturedNoteBox.remove(note.id);
    setState(() {
      _capturedNotes.removeWhere((n) => n.id == note.id);
      if (_viewingCaptured?.id == note.id) {
        _viewingCaptured = null;
      }
    });
  }

  Widget _buildContent() {
    if (activeTab == ActiveTab.myNotes && isCapturingNote) {
      return NoteCapturePage(
        onSave: (bytes, title, course, text) {
          final note = CapturedNote(
            id: 0,
            createdAt: DateTime.now(),
            imageBytes: bytes,
            title: title,
            course: course,
            textContent: text,
          );
          widget.db.capturedNoteBox.put(note);
          setState(() {
            _capturedNotes.insert(0, note);
            isCapturingNote = false;
          });
        },
        onCancel: _cancelCapture,
      );
    }
    if (activeTab == ActiveTab.myNotes && _viewingCaptured != null) {
      return NotePhotoViewPage(
        note: _viewingCaptured!,
        onBack: _closeCaptured,
        onRename: _renameCaptured,
        onUpdateCourse: _updateCourse,
        onDelete: (note) {
          _deleteCaptured(note);
        },
      );
    }
    switch (activeTab) {
      case ActiveTab.dashboard:
        return const DashboardPage();
      case ActiveTab.myNotes:
        return MyNotesPage(
          onCreateNew: _openEditorNew,
          capturedNotes: _capturedNotes,
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
