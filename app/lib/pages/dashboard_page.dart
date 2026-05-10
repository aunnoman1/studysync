import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/note_record.dart';

class DashboardPage extends StatefulWidget {
  final List<NoteRecord> recentNotes;
  final void Function(NoteRecord note) onOpenNote;
  final void Function(String query) onAskTutor;

  const DashboardPage({
    super.key,
    required this.recentNotes,
    required this.onOpenNote,
    required this.onAskTutor,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _staggeredFade(int index) {
    final start = (index * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = (index * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return SingleChildScrollView(
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
                'Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMd = constraints.maxWidth >= 700;
              final isLg = constraints.maxWidth >= 1024;
              final crossAxisCount = isLg ? 3 : (isMd ? 2 : 1);
              final cards = <Widget>[
                SlideTransition(
                  position: _staggeredSlide(0),
                  child: FadeTransition(
                    opacity: _staggeredFade(0),
                    child: _HoverCard(
                      isDark: isDark,
                      child: _CardRecentNotes(
                        notes: widget.recentNotes,
                        onOpenNote: widget.onOpenNote,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _staggeredSlide(1),
                  child: FadeTransition(
                    opacity: _staggeredFade(1),
                    child: _HoverCard(
                      isDark: isDark,
                      accentGradient: true,
                      child: _CardTutorQuickAccess(
                        onAsk: widget.onAskTutor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _staggeredSlide(2),
                  child: FadeTransition(
                    opacity: _staggeredFade(2),
                    child: _HoverCard(
                      isDark: isDark,
                      child: _CardCommunityActivity(isDark: isDark),
                    ),
                  ),
                ),
              ];

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Hover wrapper that lifts card on hover ──
class _HoverCard extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool accentGradient;
  const _HoverCard({
    required this.child,
    required this.isDark,
    this.accentGradient = false,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: AppTheme.duration,
        curve: AppTheme.curve,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        decoration: AppTheme.cardDecoration(
          hovered: _hovering,
          isDark: widget.isDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.accentGradient)
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.blue,
                      AppTheme.blueLight,
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Notes card ──
class _CardRecentNotes extends StatelessWidget {
  final List<NoteRecord> notes;
  final void Function(NoteRecord note) onOpenNote;
  final bool isDark;
  const _CardRecentNotes({required this.notes, required this.onOpenNote, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = notes.take(3).toList();
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Notes',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text('No notes yet', style: TextStyle(color: textSecondary))
        else
          ...items.map(
            (n) => _RecentNoteItem(
              n.title.isEmpty ? 'Untitled note' : n.title,
              onTap: () => onOpenNote(n),
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

// ── Note item with hover accent ──
class _RecentNoteItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  const _RecentNoteItem(this.title, {required this.onTap, required this.isDark});

  @override
  State<_RecentNoteItem> createState() => _RecentNoteItemState();
}

class _RecentNoteItemState extends State<_RecentNoteItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppTheme.darkBackground : AppTheme.lightInputFill;
    final borderColor = widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.duration,
          curve: AppTheme.curve,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppTheme.duration,
                width: 3,
                height: _hovering ? 20 : 0,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.description, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(color: textPrimary),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tutor Quick Access card ──
class _CardTutorQuickAccess extends StatelessWidget {
  final void Function(String query) onAsk;
  final bool isDark;
  const _CardTutorQuickAccess({required this.onAsk, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Tutor Quick Access',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ask a question about your recent notes:',
          style: TextStyle(color: textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            hintText: 'E.g., Explain polymorphism in OOP',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onAsk(value.trim());
            }
          },
        ),
      ],
    );
  }
}

// ── Community Activity card ──
class _CardCommunityActivity extends StatelessWidget {
  final bool isDark;
  const _CardCommunityActivity({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Activity',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'New post in "DSA Helpers": "How to implement a binary search tree?"',
          style: TextStyle(color: textSecondary),
        ),
      ],
    );
  }
}
