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
          duration: const Duration(milliseconds: 100),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Tutor', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightInputFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: _buildResults(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Ask a question...'),
                          onSubmitted: (_) => _runAsk(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _runAsk,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      controller: _scrollController,
      children: _messages.map((msg) {
        if (msg.isUser) return _UserBubble(name: 'You', text: msg.text);
        // Show a blinking cursor on the last bot message while streaming
        final isLive = _isLoading && msg == _messages.last;
        return _BotBubble(name: 'StudySync AI', text: msg.text, isStreaming: isLive);
      }).toList(),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  String text;
  _ChatMessage({required this.isUser, required this.text});
}

class _BotBubble extends StatelessWidget {
  final String name;
  final String text;
  final bool isStreaming;
  const _BotBubble({required this.name, required this.text, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold)),
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
              color: AppTheme.lightInputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            child: MarkdownBody(
              data: isStreaming ? '$text▍' : text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                h1: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
                h2: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                h3: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                strong: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                code: const TextStyle(
                  backgroundColor: Color(0xFFE5E7EB),
                  color: Color(0xFF1F2937),
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String name;
  final String text;
  const _UserBubble({required this.name, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(name, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
