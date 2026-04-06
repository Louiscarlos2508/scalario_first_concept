import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/product_stock_screen.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/screens/purchase_orders_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/reports_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';
import 'package:frontend/features/shared/contacts/presentation/screens/contacts_screen.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart'
    show salesStatsProvider, activeSessionsProvider, salesStatsDateRangeProvider;
import 'package:frontend/features/shared/reports/presentation/widgets/kpi_card_grid.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/line_chart_widget.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/terminal_status_list.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/screens/stock_alerts_screen.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/expenses/presentation/screens/expenses_screen.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart'
    show lowStockCountProvider;
import 'package:frontend/features/shared/promotions/presentation/screens/promotions_screen.dart';
import 'package:frontend/features/shared/reservations/presentation/screens/reservations_screen.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_orders_screen.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'package:frontend/features/shared/team/presentation/screens/team_screen.dart';
import 'package:frontend/core/providers/active_modules_provider.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/retail/pos/presentation/screens/unified_sessions_screen.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/manager_overview_screen.dart';
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
        shortLabel: 'Stock',
        moduleCode: 'inventory'),
    screen: const ProductStockScreen(),
  ),
  (
    navItem: const NavItem(
        icon: Icons.call_received_outlined,
        selectedIcon: Icons.call_received,
        label: 'Achats',
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
        label: 'Commandes',
        moduleCode: 'retail'),
    screen: const ClientOrdersScreen(),
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
/// - 'purchase_orders' always included for manager (if module is active)
const _roleAllowedModules = <String, Set<String>?>{
  'owner': null,
  'manager': {'inventory', 'reports', 'transactions', 'purchase_orders', 'reservations', 'sessions'},
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

  // Swap home screen for manager — operational view instead of financial dashboard.
  if (role == 'manager' && pairs.isNotEmpty) {
    pairs[0] = (navItem: pairs[0].navItem, screen: const ManagerOverviewScreen());
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

// ── OverviewScreen ────────────────────────────────────────────────────────────

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _invalidateAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(salesStatsProvider);
    ref.invalidate(activeSessionsProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(stockAlertCountProvider);
    ref.invalidate(stockAlertsProvider);
    ref.invalidate(lowStockCountProvider);
    ref.invalidate(urgentBatchCountProvider);
    ref.invalidate(purchaseOrderStatsProvider);
    ref.invalidate(reservationsKpiProvider);
    ref.invalidate(clientOrderKpisProvider);
  }

  Future<void> _onRefresh() async {
    _invalidateAll();
  }

  void _showPeriodMenu(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final periods = <(String, DateTimeRange?)>[
      ("Aujourd'hui", DateTimeRange(start: today, end: today)),
      ('7 derniers jours',
          DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today)),
      ('30 derniers jours',
          DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today)),
      ('Ce mois', DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today)),
      ('Personnalisé', null),
    ];

    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<(String, DateTimeRange?)>(
      context: context,
      position: position,
      items: periods
          .map((p) => PopupMenuItem(value: p, child: Text(p.$1)))
          .toList(),
    );

    if (selected == null || !mounted) return;

    if (selected.$2 != null) {
      ref.read(salesStatsDateRangeProvider.notifier).state = selected.$2;
      return;
    }

    // Personnalisé → DateRangePicker natif
    if (!mounted || !context.mounted) return;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: ref.read(salesStatsDateRangeProvider),
    );
    if (picked != null && mounted) {
      ref.read(salesStatsDateRangeProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(salesStatsDateRangeProvider);
    final periodLabel = dateRange == null
        ? '7 derniers jours'
        : '${DateFormat('dd/MM').format(dateRange.start)} – ${DateFormat('dd/MM').format(dateRange.end)}';

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Tableau de bord',
        actions: [
          Builder(
            builder: (ctx) => TextButton.icon(
              onPressed: () => _showPeriodMenu(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(periodLabel,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _invalidateAll,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _BillingBanner(ref: ref),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _StockAlertBanner(),
          const KpiCardGrid(),
          const LineChartWidget(title: 'Ventes des 7 derniers jours'),
          const TerminalStatusList(),
          const _QuickAccessSection(),
        ],
      ),
    );
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

// ── Stock Alert Banner ─────────────────────────────────────────────────────────

class _StockAlertBanner extends ConsumerWidget {
  const _StockAlertBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsProvider);
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        // Sort: most critical first (stock ≤ 0 or below 40% threshold)
        final sorted = [...alerts]..sort((a, b) {
            int score(Map<String, dynamic> alert) {
              final stock = (alert['stockQuantity'] as num?)?.toDouble() ?? 0;
              if (stock <= 0) return 2;
              final threshold = (alert['minStockLevel'] as num?)?.toDouble() ?? 0;
              if (threshold > 0 && stock <= threshold * 0.4) return 2;
              return 1;
            }
            return score(b).compareTo(score(a));
          });
        final first = sorted.first;
        final name = first['itemName']?.toString() ?? 'produit';
        final extra = alerts.length - 1;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockAlertsScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock bas — $name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.red.shade800),
                      ),
                      if (extra > 0)
                        Text(
                          'et $extra autre${extra > 1 ? 's' : ''} alerte${extra > 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade600),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.red.shade400, size: 18),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Quick Access Section ───────────────────────────────────────────────────────

class _QuickAccessSection extends ConsumerWidget {
  const _QuickAccessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);

    final totalRevenue = statsAsync.whenOrNull(
          data: (stats) => stats.fold(0.0, (s, e) => s + e.revenue),
        ) ??
        0.0;
    final totalOrders = statsAsync.whenOrNull(
          data: (stats) => stats.fold(0, (s, e) => s + e.orderCount),
        ) ??
        0;

    String fmtRevenue(double v) {
      if (v >= 1000000) {
        return '${(v / 1000000).toStringAsFixed(2)}M FCFA';
      }
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
      return '${v.toStringAsFixed(0)} FCFA';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick links ────────────────────────────────────────────────
          _SectionCard(
            title: 'Accès rapides',
            children: [
              _QuickLink(
                icon: Icons.analytics_outlined,
                label: 'Voir les rapports',
                onTap: () => ref
                    .read(dashboardNavigationProvider.notifier)
                    .state = 'reports',
              ),
              _QuickLink(
                icon: Icons.inventory_2_outlined,
                label: 'État du stock',
                onTap: () => ref
                    .read(dashboardNavigationProvider.notifier)
                    .state = 'inventory',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Week stats ─────────────────────────────────────────────────
          _SectionCard(
            title: '7 derniers jours',
            children: [
              _StatRow(
                label: 'CA total',
                value: statsAsync.isLoading ? '…' : fmtRevenue(totalRevenue),
              ),
              _StatRow(
                label: 'Ventes',
                value: statsAsync.isLoading ? '…' : '$totalOrders',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF3B5BDB)),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
