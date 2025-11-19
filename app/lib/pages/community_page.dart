import 'package:flutter/material.dart';
import '../theme.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search forums...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightInputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String>(
                          value: 'All',
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'PF', child: Text('PF')),
                            DropdownMenuItem(value: 'OOP', child: Text('OOP')),
                            DropdownMenuItem(value: 'DSA', child: Text('DSA')),
                            DropdownMenuItem(value: 'DB', child: Text('DB')),
                          ],
                          onChanged: (_) {},
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          iconEnabledColor: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text('New Post'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _PostCard(
                  title: 'Can someone explain Big O notation for DSA?',
                  meta: 'Posted by Aun Noman in DSA - 2 hours ago',
                  body:
                      "I'm having trouble understanding how to calculate time complexity. My notes are a bit confusing.",
                  stats: '5 replies | 2 helpful',
                ),
                const _PostCard(
                  title: 'Sharing my notes on OOP Polymorphism',
                  meta: 'Posted by Mahad Farhan Khan in OOP - 1 day ago',
                  body:
                      'Hey everyone, here are my digitized notes on polymorphism. Hope it helps someone!',
                  stats: '12 replies | 8 helpful',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String meta;
  final String body;
  final String stats;

  const _PostCard({
    required this.title,
    required this.meta,
    required this.body,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            meta,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            stats,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
