import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../pos/presentation/screens/pos_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeTenantId = ref.watch(activeTenantProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            extended: MediaQuery.of(context).size.width >= 1200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Stock History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
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
                      tooltip: 'Switch Branch',
                      onSelected: (id) {
                        ref.read(activeTenantProvider.notifier).state = id;
                      },
                      itemBuilder: (context) => profile.memberships.map((m) => PopupMenuItem(
                        value: m.tenantId,
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: m.tenantId == activeTenantId ? colorScheme.primary : null),
                            const SizedBox(width: 8),
                            Text(m.tenantName ?? 'Branch', style: TextStyle(fontWeight: m.tenantId == activeTenantId ? FontWeight.bold : null)),
                          ],
                        ),
                      )).toList(),
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
                      final active = profile?.memberships.firstWhere((m) => m.tenantId == activeTenantId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          active?.tenantName ?? 'Branch',
                          style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                    tooltip: 'Open POS',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PosScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () {
                      ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
