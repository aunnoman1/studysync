import 'package:flutter/material.dart';
import '../theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                children: const [
                  _CardRecentNotes(),
                  _CardTutorQuickAccess(),
                  _CardCommunityActivity(),
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
  const _CardRecentNotes();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Recent Notes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          _RecentNoteItem('Data Structures - Lecture 3'),
          _RecentNoteItem('OOP Concepts'),
          _RecentNoteItem('Database Schema Design'),
        ],
      ),
    );
  }
}

class _RecentNoteItem extends StatelessWidget {
  final String title;
  const _RecentNoteItem(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
    );
  }
}

class _CardTutorQuickAccess extends StatelessWidget {
  const _CardTutorQuickAccess();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Tutor Quick Access', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('Ask a question about your recent notes:', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(hintText: 'E.g., Explain polymorphism in OOP'),
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
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Community Activity', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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


