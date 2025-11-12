import 'package:flutter/material.dart';
import '../theme.dart';

enum ActiveTab { dashboard, myNotes, aiTutor, community, profile }

class Sidebar extends StatelessWidget {
  final ActiveTab activeTab;
  final ValueChanged<ActiveTab> onSelectTab;
  final VoidCallback? onUpload;
  final bool isInDrawer;

  const Sidebar({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
    this.onUpload,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = <_NavItem>[
      _NavItem(
        id: ActiveTab.dashboard,
        label: 'Dashboard',
        icon: Icons.home_outlined,
      ),
      _NavItem(
        id: ActiveTab.myNotes,
        label: 'My Notes',
        icon: Icons.description_outlined,
      ),
      _NavItem(
        id: ActiveTab.aiTutor,
        label: 'AI Tutor',
        icon: Icons.school_outlined,
      ),
      _NavItem(
        id: ActiveTab.community,
        label: 'Community',
        icon: Icons.forum_outlined,
      ),
      _NavItem(
        id: ActiveTab.profile,
        label: 'Profile',
        icon: Icons.person_outline,
      ),
    ];

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'StudySync',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                if (isInDrawer)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final selected = activeTab == item.id;
                return InkWell(
                  onTap: () => onSelectTab(item.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Notes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isInDrawer) {
      return Container(color: AppTheme.surface, child: content);
    }
    return Container(
      width: 260,
      color: AppTheme.surface,
      child: content,
    );
  }
}

class _NavItem {
  final ActiveTab id;
  final String label;
  final IconData icon;

  _NavItem({required this.id, required this.label, required this.icon});
}


