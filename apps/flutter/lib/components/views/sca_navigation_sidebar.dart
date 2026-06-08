// ============================================================
// sca_navigation_sidebar.dart
// Sidebar de navigation ERP-OS — comportement identique à NavigationDrawer de Twenty
// Features:
//  - Collapsible fluide (animation width + icon-only mode)
//  - États actifs (surbrillance bleue, border gauche)
//  - Tooltip natif en mode collapsed
//  - Sections groupées (avec titre de section)
//  - Workspace header (avec avatar + titre)
//  - Resize drag handle
// ============================================================
import 'package:flutter/material.dart';
import '../../theme/sca_tokens.dart';
import '../_internal/sca_focus_wrapper.dart';

// ---- Types ----

class ScaNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String? routePath;
  final VoidCallback? onTap;
  final List<ScaNavItem> subItems;
  final String? badge; // "New", "Soon", count

  const ScaNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.routePath,
    this.onTap,
    this.subItems = const [],
    this.badge,
  });
}

class ScaNavSection {
  final String? title;
  final List<ScaNavItem> items;

  const ScaNavSection({this.title, required this.items});
}

// ---- Main Sidebar Widget ----

class ScaNavigationSidebar extends StatefulWidget {
  final String workspaceName;
  final String? workspaceAvatarUrl;
  final List<ScaNavSection> sections;
  final String? activeItemId;
  final bool initiallyExpanded;

  const ScaNavigationSidebar({
    super.key,
    required this.workspaceName,
    required this.sections,
    this.workspaceAvatarUrl,
    this.activeItemId,
    this.initiallyExpanded = true,
  });

  @override
  State<ScaNavigationSidebar> createState() => _ScaNavigationSidebarState();
}

class _ScaNavigationSidebarState extends State<ScaNavigationSidebar>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: ScaAnimation.normal,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: ScaAnimation.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final width = ScaNavDrawer.collapsedWidth +
            (ScaNavDrawer.expandedWidth - ScaNavDrawer.collapsedWidth) *
                _widthAnimation.value;

        return Container(
          width: width,
          decoration: const BoxDecoration(
            color: ScaColors.bgSecondary,
            border: Border(
              right: BorderSide(color: ScaColors.borderLight, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header workspace
              _ScaSidebarHeader(
                workspaceName: widget.workspaceName,
                avatarUrl: widget.workspaceAvatarUrl,
                isExpanded: _isExpanded,
                fadeAnimation: _fadeAnimation,
                onToggle: _toggleExpanded,
              ),
              const SizedBox(height: ScaSpacing.s2),
              // Sections scrollables
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScaSpacing.s2,
                    vertical: ScaSpacing.s1,
                  ),
                  children: [
                    for (final section in widget.sections)
                      _ScaNavSection(
                        section: section,
                        isExpanded: _isExpanded,
                        fadeAnimation: _fadeAnimation,
                        activeItemId: widget.activeItemId,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- Header ----

class _ScaSidebarHeader extends StatelessWidget {
  final String workspaceName;
  final String? avatarUrl;
  final bool isExpanded;
  final Animation<double> fadeAnimation;
  final VoidCallback onToggle;

  const _ScaSidebarHeader({
    required this.workspaceName,
    required this.isExpanded,
    required this.fadeAnimation,
    required this.onToggle,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(
        horizontal: ScaSpacing.s2,
        vertical: ScaSpacing.s1,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ScaColors.borderLight)),
      ),
      child: Row(
        children: [
          // Workspace avatar
          Container(
            width: ScaSpacing.s8,
            height: ScaSpacing.s8,
            decoration: BoxDecoration(
              color: ScaColors.focusRing,
              borderRadius: BorderRadius.circular(ScaRadius.sm),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: avatarUrl == null
                ? Text(
                    workspaceName.isNotEmpty
                        ? workspaceName.substring(0, 1).toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          // Nom workspace (fade in/out)
          FadeTransition(
            opacity: fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(left: ScaSpacing.s2),
              child: SizedBox(
                width: ScaNavDrawer.expandedWidth - 80,
                child: Text(
                  workspaceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ScaColors.fontPrimary,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Collapse button
          ScaFocusWrapper(
            onTap: onToggle,
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(ScaRadius.sm),
            child: Icon(
              isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
              color: ScaColors.fontTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Section ----

class _ScaNavSection extends StatelessWidget {
  final ScaNavSection section;
  final bool isExpanded;
  final Animation<double> fadeAnimation;
  final String? activeItemId;

  const _ScaNavSection({
    required this.section,
    required this.isExpanded,
    required this.fadeAnimation,
    this.activeItemId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          FadeTransition(
            opacity: fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ScaSpacing.s2,
                ScaSpacing.s3,
                ScaSpacing.s2,
                ScaSpacing.s1,
              ),
              child: Text(
                section.title!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: ScaColors.fontTertiary,
                ),
              ),
            ),
          ),
        ],
        for (final item in section.items)
          _ScaNavItem(
            item: item,
            isExpanded: isExpanded,
            fadeAnimation: fadeAnimation,
            isActive: item.id == activeItemId,
          ),
        const SizedBox(height: ScaSpacing.s2),
      ],
    );
  }
}

// ---- Nav Item ----

class _ScaNavItem extends StatelessWidget {
  final ScaNavItem item;
  final bool isExpanded;
  final Animation<double> fadeAnimation;
  final bool isActive;

  const _ScaNavItem({
    required this.item,
    required this.isExpanded,
    required this.fadeAnimation,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidget = ScaFocusWrapper(
      onTap: item.onTap,
      isSelected: isActive,
      borderRadius: BorderRadius.circular(ScaRadius.sm),
      child: Container(
        height: ScaNavDrawer.itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: ScaSpacing.s1),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: ScaSpacing.s6,
              height: ScaSpacing.s6,
              child: Center(
                child: Icon(
                  item.icon,
                  size: 18,
                  color: isActive ? ScaColors.fontPrimary : ScaColors.fontSecondary,
                ),
              ),
            ),
            // Label (animated)
            FadeTransition(
              opacity: fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(left: ScaSpacing.s2),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? ScaColors.fontPrimary : ScaColors.fontSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Spacer(),
            // Badge (Soon / New / count)
            if (item.badge != null)
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ScaColors.neutralBg,
                    borderRadius: BorderRadius.circular(ScaRadius.full),
                    border: Border.all(color: ScaColors.borderLight),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ScaColors.fontTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // En mode collapsed → Tooltip natif
    if (!isExpanded) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        waitDuration: Duration.zero,
        child: itemWidget,
      );
    }

    return itemWidget;
  }
}
