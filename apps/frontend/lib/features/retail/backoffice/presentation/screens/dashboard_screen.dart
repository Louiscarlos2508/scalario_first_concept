import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/screens/purchase_orders_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/reports_screen.dart';
import 'package:frontend/features/shared/contacts/presentation/screens/contacts_screen.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart'
    show salesStatsProvider, activeSessionsProvider, salesStatsDateRangeProvider;
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/expenses/presentation/screens/expenses_screen.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/promotions/presentation/screens/promotions_screen.dart';
import 'package:frontend/features/shared/reservations/presentation/screens/reservations_screen.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_orders_screen.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'package:frontend/core/providers/active_modules_provider.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/billing/presentation/providers/subscription_provider.dart';
import 'dart:async';

// ── Navigation providers ──────────────────────────────────────────────────────

/// Set to a module code (e.g. 'inventory', 'reservations') to programmatically
/// switch the dashboard to that tab. Automatically reset after navigation.
final dashboardNavigationProvider = StateProvider<String?>((ref) => null);

// ── Navigation + screen mapping ───────────────────────────────────────────────

typedef _NavScreenPair = ({NavItem navItem, Widget screen});

final _allNavScreens = <_NavScreenPair>[
  (
    navItem: const NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Accueil'),
    screen: const OverviewScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Produits & Stock',
        moduleCode: 'inventory'),
    screen: const InventoryScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart,
        label: 'Commandes',
        moduleCode: 'purchase_orders'),
    screen: const PurchaseOrdersScreen(),
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
        moduleCode: 'promotions'),
    screen: const PromotionsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.bookmark_outline,
        selectedIcon: Icons.bookmark,
        label: 'Réservations',
        moduleCode: 'reservations'),
    screen: const ReservationsScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        label: 'Commandes',
        moduleCode: 'retail'),
    screen: const ClientOrdersScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Paramètres'),
    screen: const SettingsScreen(),
  ),
];

/// Base modules visible per role. Dynamic additions via roleScreenAccess:
/// - 'clients' if canAccess(role, 'clients_view')
/// - 'expenses' if canAccess(role, 'expenses')
/// - 'purchase_orders' always included for manager (if module is active)
const _roleAllowedModules = <String, Set<String>?>{
  'owner': null,
  'manager': {'inventory', 'reports', 'transactions', 'purchase_orders'},
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
  return _allNavScreens.where((p) {
    if (p.navItem.moduleCode == null) return true; // Accueil, Paramètres always shown
    if (!activeModules.contains(p.navItem.moduleCode)) return false;
    if (allowedByRole != null && !allowedByRole.contains(p.navItem.moduleCode)) return false;
    return true;
  }).toList();
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
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      child: IndexedStack(
        index: clampedIndex,
        children: pairs.map((p) => p.screen).toList(),
      ),
    );
  }
}

// ── OverviewScreen ────────────────────────────────────────────────────────────

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  // ignore: unused_field
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(salesStatsProvider);
        ref.invalidate(activeSessionsProvider);
        ref.invalidate(expensesProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(salesStatsDateRangeProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Tableau de bord',
        actions: [
          TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateRange,
              );
              if (picked != null) {
                ref.read(salesStatsDateRangeProvider.notifier).state = picked;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange == null
                  ? '7 derniers jours'
                  : '${DateFormat('dd/MM').format(dateRange.start)} – ${DateFormat('dd/MM').format(dateRange.end)}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(salesStatsProvider);
              ref.invalidate(activeSessionsProvider);
              ref.invalidate(expensesProvider);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _BillingBanner(ref: ref),
          Expanded(child: _buildSduiBody()),
        ],
      ),
    );
  }

  Widget _buildSduiBody() {
    final layoutAsync = ref.watch(sduiLayoutProvider('dashboard'));
    final layout = layoutAsync.when(
      data: (l) => l,
      loading: () => SduiLayout.dashboardDefault(),
      error: (_, _) => SduiLayout.dashboardDefault(),
    );
    return SduiRenderer(layout: layout);
  }
}

// ── Billing Banner ─────────────────────────────────────────────────────────────

class _BillingBanner extends StatelessWidget {
  final WidgetRef ref;
  const _BillingBanner({required this.ref});

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);
    return subAsync.when(
      data: (data) {
        final status = data['billingStatus'] as String? ?? '';
        final trialEndsAt = data['trialEndsAt'] as String?;
        final paidUntil = data['paidUntil'] as String?;
        return _buildBanner(context, status, trialEndsAt, paidUntil);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(
    BuildContext context,
    String status,
    String? trialEndsAt,
    String? paidUntil,
  ) {
    if (status == 'trial' && trialEndsAt != null) {
      final days = DateTime.tryParse(trialEndsAt)
              ?.difference(DateTime.now())
              .inDays ??
          0;
      final color = days <= 3 ? Colors.red : Colors.blue;
      return _Banner(
        color: color,
        icon: Icons.hourglass_top,
        message: "Période d'essai — $days jour(s) restant(s)",
      );
    }

    if (status == 'active' && paidUntil != null) {
      final days = DateTime.tryParse(paidUntil)
              ?.difference(DateTime.now())
              .inDays ??
          0;
      if (days > 30) return const SizedBox.shrink();
      final color = days <= 3
          ? Colors.red
          : days <= 7
              ? Colors.orange
              : Colors.blue;
      return _Banner(
        color: color,
        icon: Icons.calendar_today,
        message: days <= 0
            ? 'Abonnement expiré — contactez Scalario'
            : 'Abonnement expire dans $days jour(s)',
      );
    }

    if (status == 'overdue') {
      return const _Banner(
        color: Colors.red,
        icon: Icons.warning_amber,
        message: 'Abonnement expiré — renouvelez pour continuer',
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
