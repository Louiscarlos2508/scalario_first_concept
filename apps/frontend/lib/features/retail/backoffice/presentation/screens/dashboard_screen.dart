import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/backoffice/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/shared/catalog/presentation/screens/products_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/reports_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';
import 'package:frontend/features/shared/contacts/presentation/screens/contacts_screen.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/expenses/presentation/screens/expenses_screen.dart';
import 'package:frontend/features/shared/promotions/presentation/screens/promotions_screen.dart';
import 'package:frontend/features/shared/reservations/presentation/screens/reservations_screen.dart';
import 'package:frontend/features/shared/internal_orders/presentation/screens/internal_orders_screen.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'package:frontend/features/shared/team/presentation/screens/team_screen.dart';
import 'package:frontend/core/providers/active_modules_provider.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/retail/pos/presentation/screens/unified_sessions_screen.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/owner_overview_screen.dart';

// ── Navigation providers ──────────────────────────────────────────────────────

/// Set to a module code (e.g. 'inventory', 'reservations') to programmatically
/// switch the dashboard to that tab. Automatically reset after navigation.
final dashboardNavigationProvider = StateProvider<String?>((ref) => null);

/// Active sub-tab label for breadcrumb display (e.g. "Chiffre d'affaires").
/// Null = default/overview tab, no extra breadcrumb segment.
final activeBreadcrumbSubLabel = StateProvider<String?>((ref) => null);

// ── Navigation + screen mapping ───────────────────────────────────────────────

typedef _NavScreenPair = ({NavItem navItem, Widget screen});

final _allNavScreens = <_NavScreenPair>[
  (
    navItem: const NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard'),
    screen: const OwnerOverviewScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Stock',
        moduleCode: 'inventory'),
    screen: const ProductsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Clients',
        moduleCode: 'clients'),
    screen: const ContactsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        label: 'Rapports',
        moduleCode: 'reports'),
    screen: const ReportsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Dépenses',
        moduleCode: 'expenses'),
    screen: const ExpensesScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.local_offer_outlined,
        selectedIcon: Icons.local_offer,
        label: 'Promotions',
        shortLabel: 'Promos',
        moduleCode: 'promotions'),
    screen: const PromotionsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.bookmark_outline,
        selectedIcon: Icons.bookmark,
        label: 'Réservations',
        shortLabel: 'Réservations',
        moduleCode: 'reservations'),
    screen: const ReservationsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag,
        label: 'Commandes'),
    screen: const InternalOrdersScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Ventes',
        moduleCode: 'transactions'),
    screen: const SalesHistoryScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        label: 'Sessions',
        moduleCode: 'sessions'),
    screen: const UnifiedSessionsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Équipe',
        moduleCode: 'team'),
    screen: const TeamScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Paramètres',
        shortLabel: 'Réglages'),
    screen: const SettingsScreen(),
  ),
];

/// Base modules visible per role. Dynamic additions via roleScreenAccess:
/// - 'clients' if canAccess(role, 'clients_view')
/// - 'expenses' if canAccess(role, 'expenses')
const _roleAllowedModules = <String, Set<String>?>{
  'owner': null,
  'manager': {'inventory', 'reports', 'transactions', 'reservations', 'sessions'},
};

List<_NavScreenPair> _visiblePairs(
  Set<String> activeModules,
  String? role,
  BusinessTypeConfig? config,
) {
  final base = _roleAllowedModules[role]; // null = owner/unrestricted
  Set<String>? allowedByRole;
  if (base != null) {
    allowedByRole = {...base};
    if (role != null && config != null) {
      if (config.canAccess(role, 'clients_view')) allowedByRole.add('clients');
      if (config.canAccess(role, 'expenses')) allowedByRole.add('expenses');
    }
  }
  // Modules always visible regardless of the tenant's active module list.
  const alwaysVisible = {'sessions', 'team'};

  final pairs = _allNavScreens.where((p) {
    if (p.navItem.moduleCode == null) return true; // Accueil, Paramètres always shown
    if (p.navItem.moduleCode == 'pos') return false; // handled separately below
    if (!alwaysVisible.contains(p.navItem.moduleCode) &&
        !activeModules.contains(p.navItem.moduleCode)) {
      return false;
    }
    if (allowedByRole != null && !allowedByRole.contains(p.navItem.moduleCode)) {
      return false;
    }
    return true;
  }).toList();

  // Only non-owner roles with explicit POS access get a Caisse shortcut (owners live in the backoffice).
  final canPos = role != 'owner' && config != null && config.canAccess(role ?? '', 'pos');
  if (canPos) {
    pairs.add((
      navItem: const NavItem(
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        label: 'Caisse',
        moduleCode: 'pos',
      ),
      screen: const SizedBox.shrink(), // never rendered — nav intercepts before showing
    ));
  }

  return pairs;
}

// ── DashboardScreen ───────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(activeModulesProvider);
    final activeModules = modulesAsync.valueOrNull ?? {};
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final pairs = _visiblePairs(activeModules, role, config);

    // Handle programmatic navigation from KPI cards (by module code)
    ref.listen(dashboardNavigationProvider, (_, moduleCode) {
      if (moduleCode == null) return;
      final idx = pairs.indexWhere(
        (p) => p.navItem.moduleCode == moduleCode || p.navItem.label == moduleCode,
      );
      if (idx >= 0 && mounted) setState(() => _selectedIndex = idx);
      ref.read(dashboardNavigationProvider.notifier).state = null;
    });

    // Clamp index when module list shrinks
    final clampedIndex = _selectedIndex.clamp(0, pairs.length - 1);
    if (clampedIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = clampedIndex);
      });
    }

    return DashboardShell(
      items: pairs.map((p) => p.navItem).toList(),
      selectedIndex: clampedIndex,
      onDestinationSelected: (index) {
        if (pairs[index].navItem.moduleCode == 'pos') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PosScreen()),
          );
          return;
        }
        setState(() => _selectedIndex = index);
      },
      child: IndexedStack(
        index: clampedIndex,
        children: pairs.map((p) => p.screen).toList(),
      ),
    );
  }
}

