import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme.dart';
import '../services/ask_service.dart';
import '../objectbox.dart';
import '../models/note_record.dart';
import '../objectbox.g.dart';

class AITutorPage extends StatefulWidget {
  final String? initialQuery;

  const AITutorPage({
    super.key,
    required this.db,
    required this.askService,
    this.initialQuery,
  });

  final ObjectBox db;
  final AskService askService;

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isUser: false,
      text: 'Hello! How can I help you study today? Ask me anything about your notes.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // If an initial query was passed, run it automatically after build
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialQuery!;
        _runAsk();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, dynamic>> _collectLocalChunks({int maxChunks = 8}) {
    final q = widget.db.textChunkBox.query().order(TextChunk_.id, flags: Order.descending).build();
    final chunks = q.find();
    q.close();
    final limited = chunks.take(maxChunks);
    final out = <Map<String, dynamic>>[];
    for (final c in limited) {
      final note = c.note.target;
      out.add({
        'text': c.chunkText,
        'note_title': note?.title,
        'note_id': note?.id,
      });
    }
    return out;
  }

  Future<void> _runAsk() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _isLoading) return;

    final botMsg = _ChatMessage(isUser: false, text: '');
    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage(isUser: true, text: question));
      _messages.add(botMsg);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final locals = _collectLocalChunks();
      await for (final chunk in widget.askService.askStream(
        question: question,
        localChunks: locals,
      )) {
        if (!mounted) break;
        setState(() => botMsg.text += chunk);
        _scrollToBottom();
      }
      if (mounted && botMsg.text.isEmpty) {
        setState(() => botMsg.text = 'No response received from LLM.');
      }
    } catch (e) {
      if (mounted) setState(() => botMsg.text = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final chatBg = isDark ? AppTheme.darkBackground : AppTheme.lightInputFill;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Tutor',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration(isDark: isDark),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: chatBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: _buildResults(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Input bar with floating shadow ──
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Ask a question...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onSubmitted: (_) => _runAsk(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SendButton(
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _runAsk,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isLive = _isLoading && index == _messages.length - 1;
        return _MessageBubbleEntrance(
          index: index,
          child: msg.isUser
              ? _UserBubble(name: 'You', text: msg.text, isDark: isDark)
              : _BotBubble(
                  name: 'StudySync AI',
                  text: msg.text,
                  isStreaming: isLive,
                  isDark: isDark,
                ),
        );
      },
    );
  }
}

// ── Entrance animation for each message bubble ──
class _MessageBubbleEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const _MessageBubbleEntrance({required this.index, required this.child});

  @override
  State<_MessageBubbleEntrance> createState() => _MessageBubbleEntranceState();
}

class _MessageBubbleEntranceState extends State<_MessageBubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}

// ── Send button with animated icon ──
class _SendButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _SendButton({required this.isLoading, required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.blue, AppTheme.blueHover],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  String text;
  _ChatMessage({required this.isUser, required this.text});
}

// ── Bot bubble with left accent ──
class _BotBubble extends StatelessWidget {
  final String name;
  final String text;
  final bool isStreaming;
  final bool isDark;
  const _BotBubble({
    required this.name,
    required this.text,
    this.isStreaming = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E2235) : AppTheme.lightInputFill;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(color: AppTheme.blueLight, fontWeight: FontWeight.bold, fontSize: 13)),
              if (isStreaming && text.isEmpty) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                left: BorderSide(
                  color: AppTheme.blue.withOpacity(0.3),
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: MarkdownBody(
              data: isStreaming ? '$text▍' : text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
                h1: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
                h2: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                h3: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                strong: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: isDark ? const Color(0xFF2A2D3E) : const Color(0xFFE5E7EB),
                  color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1F2937),
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── User bubble with modern chat corners ──
class _UserBubble extends StatelessWidget {
  final String name;
  final String text;
  final bool isDark;
  const _UserBubble({required this.name, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(name, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.blue, AppTheme.blueHover],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
