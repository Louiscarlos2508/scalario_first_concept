import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart'
    show activeSessionsProvider;
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';

// ── Provider local : aperçu des achats en attente (max 3) ────────────────────

final _pendingPurchasesPreviewProvider =
    FutureProvider.autoDispose<List<PurchaseOrderLocal>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final repo = ref.watch(purchaseOrdersRepositoryProvider);
  final all = await repo.listOrders(tenantId: tenantId, status: null);
  return all
      .where((o) => o.status == 'PENDING' || o.status == 'CONFIRMED')
      .take(3)
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ManagerOverviewScreen extends ConsumerStatefulWidget {
  const ManagerOverviewScreen({super.key});

  @override
  ConsumerState<ManagerOverviewScreen> createState() =>
      _ManagerOverviewScreenState();
}

class _ManagerOverviewScreenState extends ConsumerState<ManagerOverviewScreen> {
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
    ref.invalidate(activeSessionsProvider);
    ref.invalidate(stockAlertsProvider);
    ref.invalidate(_pendingPurchasesPreviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final firstName = profile?.fullName?.split(' ').first ?? '';

    final sessionsAsync = ref.watch(activeSessionsProvider);
    final alertsAsync = ref.watch(stockAlertsProvider);
    final purchasesAsync = ref.watch(_pendingPurchasesPreviewProvider);

    final sessionCount = sessionsAsync.valueOrNull?.length ?? 0;
    final alerts = alertsAsync.valueOrNull ?? [];
    int criticalCount = 0;
    for (final a in alerts) {
      final stock = (a['stockQuantity'] as num?)?.toDouble() ?? 0;
      final min = (a['minStockLevel'] as num?)?.toDouble() ?? 0;
      if (stock <= 0 || (min > 0 && stock <= min * 0.4)) criticalCount++;
    }
    final purchaseCount = purchasesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Tableau de bord',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _invalidateAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateAll(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Ops summary header ─────────────────────────────────────
            _OpsSummaryHeader(
              firstName: firstName,
              sessionCount: sessionCount,
              criticalCount: criticalCount,
              purchaseCount: purchaseCount,
            ),
            const SizedBox(height: 16),

            // ── Quick actions ─────────────────────────────────────────
            const _SectionLabel(text: 'Actions rapides'),
            const SizedBox(height: 8),
            const _QuickActionsRow(),
            const SizedBox(height: 20),

            // ── Sessions actives ──────────────────────────────────────
            _ActiveSessionsCard(sessionsAsync: sessionsAsync),
            const SizedBox(height: 12),

            // ── Alertes stock ─────────────────────────────────────────
            _StockAlertsCard(
              alerts: alerts,
              criticalCount: criticalCount,
              isLoading: alertsAsync.isLoading,
            ),
            const SizedBox(height: 12),

            // ── Achats en attente ─────────────────────────────────────
            _PendingPurchasesCard(purchasesAsync: purchasesAsync),
            const SizedBox(height: 12),

            // ── Activité du jour ──────────────────────────────────────
            _ActivityCard(
              sessionCount: sessionCount,
              alertCount: alerts.length,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ops summary header ────────────────────────────────────────────────────────

class _OpsSummaryHeader extends StatelessWidget {
  final String firstName;
  final int sessionCount;
  final int criticalCount;
  final int purchaseCount;

  const _OpsSummaryHeader({
    required this.firstName,
    required this.sessionCount,
    required this.criticalCount,
    required this.purchaseCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(now);
    final date = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? 'Bonjour 👋' : 'Bonjour, $firstName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (sessionCount > 0)
                      _OpsPill(
                        label:
                            '● $sessionCount caisse${sessionCount > 1 ? 's' : ''} active${sessionCount > 1 ? 's' : ''}',
                        color: Colors.green,
                      )
                    else
                      const _OpsPill(
                          label: '● Aucune caisse active',
                          color: Colors.grey),
                    if (criticalCount > 0)
                      _OpsPill(
                        label: '● $criticalCount produit${criticalCount > 1 ? 's' : ''} critique${criticalCount > 1 ? 's' : ''}',
                        color: Colors.red,
                      ),
                    if (purchaseCount > 0)
                      _OpsPill(
                        label:
                            '● $purchaseCount achat${purchaseCount > 1 ? 's' : ''} en attente',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpsPill extends StatelessWidget {
  final String label;
  final Color color;

  const _OpsPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color == Colors.grey
              ? Colors.white.withValues(alpha: 0.5)
              : (color == Colors.green
                  ? const Color(0xFF4ADE80)
                  : color == Colors.red
                      ? const Color(0xFFF87171)
                      : const Color(0xFFFBBF24)),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.point_of_sale_outlined,
            label: 'Ouvrir\nune caisse',
            bgColor: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF1A73E8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PosScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.call_received_outlined,
            label: 'Faire une\nréception',
            bgColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF34A853),
            onTap: () => ref
                .read(dashboardNavigationProvider.notifier)
                .state = 'purchase_orders',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.analytics_outlined,
            label: 'Voir les\nrapports',
            bgColor: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            onTap: () => ref
                .read(dashboardNavigationProvider.notifier)
                .state = 'reports',
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card shell ────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final IconData titleIcon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget child;
  final String? linkLabel;
  final VoidCallback? onLink;

  const _OverviewCard({
    required this.titleIcon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.child,
    this.linkLabel,
    this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(titleIcon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (onLink != null && linkLabel != null)
                GestureDetector(
                  onTap: onLink,
                  child: Text(
                    linkLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Active sessions card ───────────────────────────────────────────────────────

class _ActiveSessionsCard extends ConsumerWidget {
  final AsyncValue<List<dynamic>> sessionsAsync;

  const _ActiveSessionsCard({required this.sessionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OverviewCard(
      titleIcon: Icons.point_of_sale_outlined,
      iconBg: const Color(0xFFDBEAFE),
      iconColor: const Color(0xFF1A73E8),
      title: 'Caisses actives',
      linkLabel: 'Tout voir →',
      onLink: () =>
          ref.read(dashboardNavigationProvider.notifier).state = 'sessions',
      child: sessionsAsync.when(
        loading: () => const _LoadingHint(),
        error: (_, _) => const _EmptyHint(
          icon: Icons.point_of_sale_outlined,
          message: 'Impossible de charger les sessions.',
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Column(
              children: [
                const _EmptyHint(
                  icon: Icons.point_of_sale_outlined,
                  message: 'Aucune caisse ouverte en ce moment.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PosScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ouvrir une caisse'),
                  ),
                ),
              ],
            );
          }
          final fcfa = NumberFormat.currency(
              locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
          return Column(
            children: sessions.take(3).map<Widget>((raw) {
              final s = raw as Map<String, dynamic>;
              final openedAt = s['openedAt'] != null
                  ? DateTime.tryParse(s['openedAt'] as String)
                  : null;
              final openingBalance =
                  double.tryParse(s['openingBalance']?.toString() ?? '') ?? 0;
              final deviceId = s['deviceId'] as String? ?? 'Terminal';
              final saleCount =
                  (s['saleCount'] as num? ?? s['orderCount'] as num?)
                      ?.toInt();
              final initials =
                  deviceId.length >= 2 ? deviceId.substring(0, 2).toUpperCase() : deviceId.toUpperCase();
              return _SessionRow(
                initials: initials,
                name: deviceId,
                subtitle: openedAt != null
                    ? 'Depuis ${DateFormat('HH:mm').format(openedAt.toLocal())}'
                    : 'Session en cours',
                saleCount: saleCount,
                revenue: (s['totalRevenue'] as num?)?.toDouble(),
                fondInitial: openingBalance,
                fcfa: fcfa,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;
  final int? saleCount;
  final double? revenue;
  final double fondInitial;
  final NumberFormat fcfa;

  const _SessionRow({
    required this.initials,
    required this.name,
    required this.subtitle,
    this.saleCount,
    this.revenue,
    required this.fondInitial,
    required this.fcfa,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A73E8),
            child: Text(
              initials,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (saleCount != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$saleCount ventes',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const Text(
                  "AUJOURD'HUI",
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'EN COURS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stock alerts card ─────────────────────────────────────────────────────────

class _StockAlertsCard extends ConsumerWidget {
  final List<Map<String, dynamic>> alerts;
  final int criticalCount;
  final bool isLoading;

  const _StockAlertsCard({
    required this.alerts,
    required this.criticalCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningCount = alerts.length - criticalCount;
    return _OverviewCard(
      titleIcon: Icons.warning_amber_rounded,
      iconBg: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
      title: 'Alertes stock',
      linkLabel: 'Voir le stock →',
      onLink: () =>
          ref.read(dashboardNavigationProvider.notifier).state = 'inventory',
      child: isLoading
          ? const _LoadingHint()
          : alerts.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: Color(0xFF166534)),
                      SizedBox(width: 8),
                      Text(
                        'Tout va bien — aucun produit critique',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Count badges
                    Row(
                      children: [
                        if (criticalCount > 0)
                          Expanded(
                            child: _AlertBigBadge(
                              count: criticalCount,
                              label: 'Critiques',
                              bgColor: const Color(0xFFFEF2F2),
                              borderColor: const Color(0xFFFCA5A5),
                              textColor: const Color(0xFFDC2626),
                            ),
                          ),
                        if (criticalCount > 0 && warningCount > 0)
                          const SizedBox(width: 10),
                        if (warningCount > 0)
                          Expanded(
                            child: _AlertBigBadge(
                              count: warningCount,
                              label: 'Stock bas',
                              bgColor: const Color(0xFFFFFBEB),
                              borderColor: const Color(0xFFFDE68A),
                              textColor: const Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Top 3 items
                    ...alerts.take(3).map((a) {
                      final stock =
                          (a['stockQuantity'] as num?)?.toDouble() ?? 0;
                      final min =
                          (a['minStockLevel'] as num?)?.toDouble() ?? 0;
                      final isCritical = stock <= 0 ||
                          (min > 0 && stock <= min * 0.4);
                      final qtyColor = isCritical
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706);
                      final qtyLabel = isCritical ? 'Critique' : 'Bas';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                a['itemName']?.toString() ?? 'Produit',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${a['stockQuantity'] ?? 0} ${a['unit'] ?? ''} — $qtyLabel',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: qtyColor),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (alerts.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(dashboardNavigationProvider.notifier)
                              .state = 'inventory',
                          child: Text(
                            '+${alerts.length - 3} autres alertes',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _AlertBigBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _AlertBigBadge({
    required this.count,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

// ── Pending purchases card ────────────────────────────────────────────────────

class _PendingPurchasesCard extends ConsumerWidget {
  final AsyncValue<List<PurchaseOrderLocal>> purchasesAsync;

  const _PendingPurchasesCard({required this.purchasesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _OverviewCard(
      titleIcon: Icons.call_received_outlined,
      iconBg: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFF57C00),
      title: 'Achats en attente',
      linkLabel: 'Gérer →',
      onLink: () =>
          ref.read(dashboardNavigationProvider.notifier).state = 'purchase_orders',
      child: purchasesAsync.when(
        loading: () => const _LoadingHint(),
        error: (_, _) => const _EmptyHint(
          icon: Icons.call_received_outlined,
          message: 'Impossible de charger les achats.',
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const _EmptyHint(
              icon: Icons.check_circle_outline,
              message: 'Aucun achat en attente.',
              positive: true,
            );
          }
          final now = DateTime.now();
          return Column(
            children: orders.map((o) {
              final isLate = o.expectedDate != null &&
                  o.expectedDate!.isBefore(now);
              final dateLabel = o.expectedDate == null
                  ? 'Date inconnue'
                  : isLate
                      ? 'En retard'
                      : DateFormat('dd/MM').format(o.expectedDate!);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLate
                            ? const Color(0xFF1A73E8)
                            : const Color(0xFFFFCC00),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        o.supplierName ?? 'Fournisseur inconnu',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: isLate
                              ? const Color(0xFF991B1B)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLate
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLate ? 'En retard' : 'En attente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLate
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ── Activité du jour card ─────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final int sessionCount;
  final int alertCount;

  const _ActivityCard({
    required this.sessionCount,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      titleIcon: Icons.trending_up,
      iconBg: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF34A853),
      title: 'Activité du jour',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniKpi(label: 'Caisses actives', value: '$sessionCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniKpi(label: 'Alertes stock', value: '$alertCount'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: alertCount == 0
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: alertCount == 0
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Text(
                  alertCount == 0 ? '✅' : '⚠️',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alertCount == 0
                        ? 'Journée en cours — aucun incident signalé'
                        : '$alertCount alerte${alertCount > 1 ? 's' : ''} stock à traiter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: alertCount == 0
                          ? const Color(0xFF166534)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;

  const _MiniKpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _LoadingHint extends StatelessWidget {
  const _LoadingHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool positive;

  const _EmptyHint({
    required this.icon,
    required this.message,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }
}
