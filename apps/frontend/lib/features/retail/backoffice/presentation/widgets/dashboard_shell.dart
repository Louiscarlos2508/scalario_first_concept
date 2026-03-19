import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/sync_status_indicator.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// Navigation destination item.
/// [moduleCode] null = always visible; non-null = visible only when module is active.
class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? moduleCode;
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.moduleCode,
  });
}

// Phone: max 5 items in BottomNavigationBar (AC3 — MVP overflow handling)
const int _maxBottomItems = 5;

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavItem> items;

  const DashboardShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  /// Returns an icon widget with an outbox badge for the Inventaire tab.
  Widget _navIcon(WidgetRef ref, String label, IconData icon) {
    if (label != 'Inventaire') return Icon(icon);
    final countAsync = ref.watch(inventoryOutboxCountProvider);
    final count = countAsync.when(
      data: (n) => n,
      loading: () => 0,
      error: (_, __) => 0,
    );
    if (count == 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      backgroundColor: AppColors.warning,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kCompact;
        return isWide ? _buildTabletLayout(context) : _buildPhoneLayout(context);
      },
    );
  }

  // ── Tablet layout (≥ 600dp) — NavigationRail + content ──────────────────

  Widget _buildTabletLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeTenantId = ref.watch(activeTenantProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width >= 1200,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            destinations: widget.items
                .map((item) => NavigationRailDestination(
                      icon: _navIcon(ref, item.label, item.icon),
                      selectedIcon: _navIcon(ref, item.label, item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                userProfileAsync.when(
                  data: (profile) {
                    if (profile == null || profile.memberships.length <= 1) {
                      return CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.business, color: colorScheme.onPrimaryContainer),
                      );
                    }
                    return PopupMenuButton<String>(
                      initialValue: activeTenantId,
                      tooltip: 'Changer de branche',
                      onSelected: (id) {
                        ref.read(activeTenantProvider.notifier).state = id;
                      },
                      itemBuilder: (context) => profile.memberships
                          .map((m) => PopupMenuItem(
                                value: m.tenantId,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 18,
                                        color: m.tenantId == activeTenantId
                                            ? colorScheme.primary
                                            : null),
                                    const SizedBox(width: 8),
                                    Text(m.tenantName ?? 'Branche',
                                        style: TextStyle(
                                            fontWeight: m.tenantId == activeTenantId
                                                ? FontWeight.bold
                                                : null)),
                                  ],
                                ),
                              ))
                          .toList(),
                      child: CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.swap_horiz, color: Colors.white),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Icon(Icons.error),
                ),
                const SizedBox(height: 16),
                if (activeTenantId != null)
                  userProfileAsync.when(
                    data: (profile) {
                      final active = profile?.memberships
                          .firstWhere((m) => m.tenantId == activeTenantId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          active?.tenantName ?? 'Branche',
                          style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.point_of_sale),
                    tooltip: 'Ouvrir la caisse',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PosScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Déconnexion',
                    onPressed: () {
                      ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                  const SizedBox(height: 8),
                  const SyncStatusIndicator(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: SafeArea(child: widget.child),
          ),
        ],
      ),
    );
  }

  // ── Phone layout (< 600dp) — BottomNavigationBar ─────────────────────────

  Widget _buildPhoneLayout(BuildContext context) {
    final visibleBottom = widget.items.take(_maxBottomItems).toList();
    final bottomIndex = widget.selectedIndex.clamp(0, visibleBottom.length - 1);

    return Scaffold(
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        onTap: widget.onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: visibleBottom
            .asMap()
            .entries
            .map((e) => BottomNavigationBarItem(
                  icon: _navIcon(ref, e.value.label, e.value.icon),
                  activeIcon: _navIcon(ref, e.value.label, e.value.selectedIcon),
                  label: e.value.label,
                ))
            .toList(),
      ),
    );
  }
}
