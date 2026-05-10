import 'package:flutter/material.dart';
import '../theme.dart';
import '../app.dart'; // for themeModeNotifier

enum ActiveTab {
  dashboard,
  myNotes,
  search,
  aiTutor,
  community,
  cloudSync,
  profile,
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final navItems = <_NavItem>[
      _NavItem(id: ActiveTab.dashboard, label: 'Dashboard', icon: Icons.home_outlined),
      _NavItem(id: ActiveTab.myNotes, label: 'My Notes', icon: Icons.description_outlined),
      _NavItem(id: ActiveTab.search, label: 'Search', icon: Icons.search_outlined),
      _NavItem(id: ActiveTab.aiTutor, label: 'AI Tutor', icon: Icons.school_outlined),
      _NavItem(id: ActiveTab.community, label: 'Community', icon: Icons.forum_outlined),
      _NavItem(id: ActiveTab.cloudSync, label: 'Cloud Sync', icon: Icons.cloud_sync_outlined),
      _NavItem(id: ActiveTab.profile, label: 'Profile', icon: Icons.person_outline),
    ];

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Brand header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'StudySync',
                  style: TextStyle(
                    color: AppTheme.blueLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                if (isInDrawer)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: textPrimary),
                  ),
              ],
            ),
          ),
          Divider(color: borderColor.withValues(alpha: 0.5), height: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 12),
          // ── Navigation items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final selected = activeTab == item.id;
                return _SidebarNavItem(
                  item: item,
                  selected: selected,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => onSelectTab(item.id),
                );
              },
            ),
          ),
          // ── Upload button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: _UploadButton(onUpload: onUpload, isDark: isDark),
          ),
        ],
      ),
    );

    if (isInDrawer) {
      return Container(color: bgColor, child: content);
    }
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor.withValues(alpha: 0.3))),
      ),
      child: content,
    );
  }
}

// ── Animated nav item with hover + selection bar ──
class _SidebarNavItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? AppTheme.blue.withValues(alpha: 0.08)
        : AppTheme.blue.withValues(alpha: 0.05);

    Color bgColor;
    if (widget.selected) {
      bgColor = AppTheme.blue;
    } else if (_hovering) {
      bgColor = hoverBg;
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.duration,
          curve: AppTheme.curve,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            children: [
              // ── Active accent bar ──
              AnimatedContainer(
                duration: AppTheme.duration,
                curve: AppTheme.curve,
                width: 3,
                height: widget.selected ? 20 : 0,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: widget.selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedSwitcher(
                duration: AppTheme.duration,
                child: Icon(
                  widget.item.icon,
                  key: ValueKey('${widget.item.id}_${widget.selected}'),
                  color: widget.selected ? Colors.white : widget.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.selected ? Colors.white : widget.textPrimary,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upload button with gradient + press feedback ──
class _UploadButton extends StatefulWidget {
  final VoidCallback? onUpload;
  final bool isDark;
  const _UploadButton({required this.onUpload, required this.isDark});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUpload?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.blue, AppTheme.blueHover],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Upload Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final ActiveTab id;
  final String label;
  final IconData icon;

  _NavItem({required this.id, required this.label, required this.icon});
}
