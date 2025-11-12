import 'package:flutter/material.dart';
import '../theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Muhammad Rohaim', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('22L-6573', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Account Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const _DetailRow(label: 'Email', value: '22L-6573@lhr.nu.edu.pk'),
                const _DetailRow(label: 'University', value: 'National University of Computer and Emerging Sciences'),
                const _DetailRow(label: 'Courses Enrolled', value: 'PF, OOP, DSA, DB'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text('$label:', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}


