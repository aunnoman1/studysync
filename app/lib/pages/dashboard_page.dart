import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/note_record.dart';

class DashboardPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMd = constraints.maxWidth >= 700;
              final isLg = constraints.maxWidth >= 1024;
              final crossAxisCount = isLg ? 3 : (isMd ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _CardRecentNotes(notes: recentNotes, onOpenNote: onOpenNote),
                  _CardTutorQuickAccess(onAsk: onAskTutor),
                  const _CardCommunityActivity(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardRecentNotes extends StatelessWidget {
  final List<NoteRecord> notes;
  final void Function(NoteRecord note) onOpenNote;
  const _CardRecentNotes({required this.notes, required this.onOpenNote});

  @override
  Widget build(BuildContext context) {
    final items = notes.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Notes',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No notes yet',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...items.map(
              (n) => _RecentNoteItem(
                n.title.isEmpty ? 'Untitled note' : n.title,
                onTap: () => onOpenNote(n),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentNoteItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _RecentNoteItem(this.title, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.lightInputFill,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTutorQuickAccess extends StatelessWidget {
  final void Function(String query) onAsk;
  const _CardTutorQuickAccess({required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Tutor Quick Access',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask a question about your recent notes:',
            style: TextStyle(color: AppTheme.textSecondary),
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
      ),
    );
  }
}

class _CardCommunityActivity extends StatelessWidget {
  const _CardCommunityActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Community Activity',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'New post in "DSA Helpers": "How to implement a binary search tree?"',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
