import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../../../../core/auth/auth_state.dart';
import '../../../pos/presentation/screens/pos_screen.dart';
import '../../../pos/presentation/widgets/sync_status_indicator.dart';
import '../../../pos/presentation/providers/pos_providers.dart';

// Navigation destination data (Loi de Hick — 7 items max)
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

const List<_NavItem> _allItems = [
  _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Accueil'),
  _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'Inventaire'),
  _NavItem(icon: Icons.category_outlined, selectedIcon: Icons.category, label: 'Catégories'),
  _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Clients'),
  _NavItem(icon: Icons.history_outlined, selectedIcon: Icons.history, label: 'Historique'),
  _NavItem(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Rapports'),
  _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Paramètres'),
];

// Phone: max 5 items in BottomNavigationBar (AC3 — MVP overflow handling)
const int _maxBottomItems = 5;

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const DashboardShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  /// Returns an icon widget with an outbox badge for the Inventaire tab (index 1).
  Widget _navIcon(WidgetRef ref, int index, IconData icon) {
    if (index != 1) return Icon(icon);
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
            destinations: _allItems
                .asMap()
                .entries
                .map((e) => NavigationRailDestination(
                      icon: _navIcon(ref, e.key, e.value.icon),
                      selectedIcon: _navIcon(ref, e.key, e.value.selectedIcon),
                      label: Text(e.value.label),
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
                  error: (_, _) => const Icon(Icons.error),
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
                    error: (_, _) => const SizedBox(),
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
          // Main content with SafeArea (AC5 — notch/status-bar protection)
          Expanded(
            child: SafeArea(child: widget.child),
          ),
        ],
      ),
    );
  }

  // ── Phone layout (< 600dp) — BottomNavigationBar ─────────────────────────

  Widget _buildPhoneLayout(BuildContext context) {
    // Clamp index: BottomNavBar shows only first 5 items (AC3 — MVP)
    final bottomIndex = widget.selectedIndex.clamp(0, _maxBottomItems - 1);

    return Scaffold(
      // SafeArea on body for notch/status-bar (AC5); BottomNavBar handles
      // system nav bar inset automatically via the Scaffold slot.
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        onTap: widget.onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: _allItems
            .take(_maxBottomItems)
            .toList()
            .asMap()
            .entries
            .map((e) => BottomNavigationBarItem(
                  icon: _navIcon(ref, e.key, e.value.icon),
                  activeIcon: _navIcon(ref, e.key, e.value.selectedIcon),
                  label: e.value.label,
                ))
            .toList(),
      ),
    );
  }
}
