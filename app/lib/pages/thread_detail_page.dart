import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forum_models.dart';
import '../objectbox.dart';
import '../services/forum_supabase_service.dart';
import '../theme.dart';

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

class ThreadDetailPage extends StatefulWidget {
  final String threadId;
  final ObjectBox db;

  const ThreadDetailPage({super.key, required this.threadId, required this.db});

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  final _service = ForumSupabaseService();

  bool _isLoading = true;
  String? _error;
  ForumThread? _thread;
  List<ForumComment> _comments = const [];

  final _replyController = TextEditingController();
  bool _isPostingReply = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final thread = await _service.fetchThreadDetail(widget.threadId);
      final comments = await _service.fetchComments(widget.threadId);

      if (!mounted) return;
      setState(() {
        _thread = thread;
        _comments = comments;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  Future<void> _ensureLoggedInOrShowDialog() async {
    if (_isLoggedIn) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Login required',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'You must be logged in to reply.',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _postReply({String? parentCommentId}) async {
    await _ensureLoggedInOrShowDialog();
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final raw = _replyController.text.trim();
    if (raw.isEmpty) return;

    // Capture messenger before async gap.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isPostingReply = true);
    try {
      await _service.createComment(
        threadId: widget.threadId,
        userId: user.id,
        content: raw,
        parentCommentId: parentCommentId,
      );
      _replyController.clear();
      await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to post reply: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPostingReply = false);
    }
  }

  Future<void> _showReplyDialog({String? parentCommentId}) async {
    await _ensureLoggedInOrShowDialog();
    if (!_isLoggedIn) return;
    if (!mounted) return;

    // Capture messenger before async gap.
    final messenger = ScaffoldMessenger.of(context);

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reply', style: TextStyle(color: Colors.black)),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Write your reply...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;
                final navigator = Navigator.of(ctx);
                try {
                  await _service.createComment(
                    threadId: widget.threadId,
                    userId: user.id,
                    content: raw,
                    parentCommentId: parentCommentId,
                  );
                  navigator.pop();
                  await _load();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final tree = buildCommentTree(_comments);

    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            )
          : thread == null
          ? const Center(child: Text('Thread not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Posted by ${thread.authorUsername ?? 'Unknown'} in ${thread.courseCode ?? '-'} - ${_timeAgo(thread.createdAt)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    thread.content,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'Replies',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (tree.isEmpty)
                    const Text(
                      'No replies yet. Be the first!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    _CommentTreeView(
                      nodes: tree,
                      depth: 0,
                      onReplyTap: _isLoggedIn
                          ? (parentId) =>
                                _showReplyDialog(parentCommentId: parentId)
                          : null,
                    ),

                  if (_isLoggedIn) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _replyController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Write a reply...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _isPostingReply
                                  ? null
                                  : () => _postReply(),
                              child: const Text('Reply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CommentTreeView extends StatelessWidget {
  final List<CommentNode> nodes;
  final int depth;
  final void Function(String? parentCommentId)? onReplyTap;

  const _CommentTreeView({
    required this.nodes,
    required this.depth,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes.map((n) {
        return Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10, top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.comment.authorUsername ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(n.comment.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      n.comment.content,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    if (onReplyTap != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => onReplyTap!(n.comment.commentId),
                          child: const Text('Reply'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (n.children.isNotEmpty)
                _CommentTreeView(
                  nodes: n.children,
                  depth: depth + 1,
                  onReplyTap: onReplyTap,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
