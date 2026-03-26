import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forum_models.dart';
import '../models/note_record.dart';
import '../objectbox.dart';
import '../objectbox.g.dart';
import '../services/forum_supabase_service.dart';
import '../services/note_transfer_service.dart';
import '../theme.dart';
import 'thread_detail_page.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().toUtc().difference(dt.toUtc());
  final secs = diff.inSeconds;
  if (secs < 60) return '${secs}s ago';
  final mins = diff.inMinutes;
  if (mins < 60) return '${mins}m ago';
  final hrs = diff.inHours;
  if (hrs < 24) return '${hrs}h ago';
  final days = diff.inDays;
  return '${days}d ago';
}

String _truncate(String s, int maxLen) {
  final raw = s.trim();
  if (raw.length <= maxLen) return raw;
  return '${raw.substring(0, maxLen)}...';
}

class CommunityPage extends StatefulWidget {
  final ObjectBox db;
  final void Function(NoteRecord)? onOpenNote;

  const CommunityPage({super.key, required this.db, this.onOpenNote});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _forumService = ForumSupabaseService();

  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  List<ForumCourse> _courses = const [];
  List<ForumThread> _threads = const [];
  bool _isLoading = true;
  String? _error;

  int? _selectedCourseId;
  String _selectedCourseCode = 'All';

  // Local notes for "reshare note" attachment.
  List<NoteRecord> _localNotes = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      _localNotes = widget.db.noteBox.getAll().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _courses = await _forumService.fetchCourses();
      if (_courses.isNotEmpty) {
        // Default dropdown selection: All
        _selectedCourseId = null;
        _selectedCourseCode = 'All';
      }

      await _refreshThreads();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshThreads() async {
    final q = _searchController.text;
    final res = await _forumService.fetchThreads(
      courseId: _selectedCourseId,
      searchQuery: q,
    );
    if (!mounted) return;
    setState(() => _threads = res);
  }

  bool get _isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  Future<void> _showNewPostDialog() async {
    if (!_isLoggedIn) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'Login required',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'You must be logged in to create a thread.',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser!;
    final currentNotes = _localNotes;

    final courseOptions = _courses;
    if (courseOptions.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'No courses found',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Create courses in Supabase first.',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    int? dialogSelectedCourseId =
        _selectedCourseId ?? courseOptions.first.courseId;

    // Reset form state when opening the dialog.
    _titleController.text = '';
    _contentController.text = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'New Thread',
                style: TextStyle(color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Course',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: courseOptions.map((c) {
                            final isSelected =
                                dialogSelectedCourseId == c.courseId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(c.courseName.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      dialogSelectedCourseId = c.courseId;
                                    });
                                  }
                                },
                                selectedColor: AppTheme.blue.withAlpha(50),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.blue
                                      : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., How do I solve ...?',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Write your question here...',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(color: Colors.black),
                        ),
                        maxLines: 6,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Title and question are required.'),
                        ),
                      );
                      return;
                    }

                    if (dialogSelectedCourseId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a course.'),
                        ),
                      );
                      return;
                    }

                    // Disable button during submission by using dialog route state.
                    setDialogState(() {});

                    // Capture context-dependent objects before async gaps.
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      final threadId = await _forumService.createThread(
                        courseId: dialogSelectedCourseId!,
                        title: title,
                        content: content,
                        userId: user.id,
                      );

                      if (!mounted) return;
                      navigator.pop();
                      await _refreshThreads();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Thread created.')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _noteToTextFallback(NoteRecord note) async {
    final textContent = note.textContent?.trim();
    if (textContent != null && textContent.isNotEmpty) return textContent;

    // Fallback: join local OCR/chunk text in stable order using text chunks.
    final q = widget.db.textChunkBox
        .query(TextChunk_.note.equals(note.id))
        .build();
    final chunks = q.find();
    q.close();
    chunks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final joined = chunks
        .map((c) => c.chunkText.trim())
        .where((s) => s.isNotEmpty)
        .join('\n\n');
    return joined.isEmpty ? note.title : joined;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = !_isLoading && _threads.isEmpty && (_error == null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Forums',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search forums...',
                        ),
                        onChanged: (_) => _debouncedRefresh(),
                      ),
                    ),
                    if (_isLoggedIn) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showNewPostDialog,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text('New Post'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCourseCode == 'All',
                          onSelected: (selected) async {
                            if (selected) {
                              setState(() {
                                _selectedCourseCode = 'All';
                                _selectedCourseId = null;
                              });
                              await _refreshThreads();
                            }
                          },
                          selectedColor: AppTheme.blue.withAlpha(50),
                          backgroundColor: AppTheme.surface,
                          labelStyle: TextStyle(
                            color: _selectedCourseCode == 'All'
                                ? AppTheme.blue
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      ..._courses.map((c) {
                        final isSelected = _selectedCourseCode == c.courseCode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(c.courseName.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) async {
                              if (selected) {
                                setState(() {
                                  _selectedCourseCode = c.courseCode;
                                  _selectedCourseId = c.courseId;
                                });
                                await _refreshThreads();
                              }
                            },
                            selectedColor: AppTheme.blue.withAlpha(50),
                            backgroundColor: AppTheme.surface,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.blue
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  )
                else if (isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No threads found. Create the first one!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
                  Column(
                    children: _threads.map((t) {
                      final meta =
                          'Posted by ${t.authorUsername ?? 'Unknown'} in ${t.courseCode ?? '-'} - ${_timeAgo(t.createdAt)}';
                      final body = _truncate(t.content, 220);
                      final currentUser =
                          Supabase.instance.client.auth.currentUser;
                      final isOwner =
                          currentUser != null && t.userId == currentUser.id;

                      return _ThreadCard(
                        title: t.title,
                        meta: meta,
                        body: body,
                        onDelete: isOwner
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Delete Thread',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this thread?',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _forumService.deleteThread(
                                      t.threadId,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Thread deleted successfully',
                                        ),
                                      ),
                                    );
                                    _refreshThreads();
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete thread: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ThreadDetailPage(
                                threadId: t.threadId,
                                db: widget.db,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Timer? _debounce;
  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _refreshThreads();
      } catch (_) {
        // Ignore transient errors while typing; UI error will appear on manual refresh.
      }
    });
  }
}

class _ThreadCard extends StatelessWidget {
  final String title;
  final String meta;
  final String body;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ThreadCard({
    required this.title,
    required this.meta,
    required this.body,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              meta,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
