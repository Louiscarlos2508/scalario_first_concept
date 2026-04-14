import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_card.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_filter_sheet.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_kpi_row.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/workflow_stepper.dart';
import 'package:frontend/features/shared/internal_orders/presentation/screens/internal_order_detail_screen.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show activeBreadcrumbSubLabel;

/// Set to an order ID to programmatically open its detail on desktop.
/// Automatically reset after navigation.
final pendingOrderNavigationProvider = StateProvider<String?>((ref) => null);

/// Ecran principal « Commandes internes ».
/// Responsive : liste de cartes (mobile) / page header + tableau (desktop ≥ 1024).
class InternalOrdersScreen extends ConsumerStatefulWidget {
  const InternalOrdersScreen({super.key});

  @override
  ConsumerState<InternalOrdersScreen> createState() => _InternalOrdersScreenState();
}

class _InternalOrdersScreenState extends ConsumerState<InternalOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _search = '';
  InternalOrderFilter _filter = const InternalOrderFilter();

  /// Non-null = on affiche le détail inline (desktop) au lieu de la liste.
  InternalOrder? _selectedOrder;

  static const _tabs = [
    OrderStatus.toValidate,
    OrderStatus.inProgress,
    OrderStatus.validated,
    OrderStatus.refused,
  ];

  static const _tabLabels = [
    'À valider',
    'En cours',
    'Validées',
    'Refusées',
  ];

  static const _tabSectionLabels = [
    'Commandes à valider',
    'Commandes en cours',
    'Commandes validées',
    'Commandes refusées',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<InternalOrder> get _filteredOrders {
    final status = _tabs[_tabCtrl.index];
    var list = internalOrdersByStatus(status);

    if (_filter.urgency != null) {
      list = list.where((o) => o.urgency == _filter.urgency).toList();
    }
    if (_filter.commercials.isNotEmpty) {
      list = list
          .where((o) => _filter.commercials.contains(o.commercialName))
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((o) =>
              o.title.toLowerCase().contains(q) ||
              o.id.toLowerCase().contains(q) ||
              o.commercialName.toLowerCase().contains(q) ||
              o.supplierName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _openFilter() async {
    final result =
        await showInternalOrderFilterSheet(context, current: _filter);
    if (result != null) setState(() => _filter = result);
  }

  void _openOrderDetail(InternalOrder order) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (isDesktop) {
      setState(() => _selectedOrder = order);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InternalOrderDetailScreen(order: order),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for programmatic order navigation (e.g. from notification actions)
    ref.listen(pendingOrderNavigationProvider, (_, orderId) {
      if (orderId == null) return;
      final order = mockInternalOrders.where((o) => o.id == orderId).firstOrNull;
      if (order != null && mounted) {
        _openOrderDetail(order);
      }
      ref.read(pendingOrderNavigationProvider.notifier).state = null;
    });

    // Breadcrumb: clicking "Commandes" clears sub-label → go back to list
    ref.listen(activeBreadcrumbSubLabel, (prev, next) {
      if (prev != null && next == null && _selectedOrder != null && mounted) {
        setState(() => _selectedOrder = null);
      }
    });

    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    if (isWide && _selectedOrder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeBreadcrumbSubLabel.notifier).state =
              _selectedOrder!.id;
        }
      });
      return InternalOrderDetailScreen(order: _selectedOrder!);
    }
    if (isWide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeBreadcrumbSubLabel.notifier).state = null;
        }
      });
    }
    return isWide ? _buildDesktop() : _buildMobile();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Mobile layout
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() {
    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Commandes internes',
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _buildTabWidgets(mobile: true),
        ),
      ),
      body: Column(
        children: [
          InternalOrderKpiRow(allOrders: mockInternalOrders),
          _MobileSearchFilterBar(
            search: _search,
            filterCount: _filter.activeCount,
            onSearchChanged: (v) => setState(() => _search = v),
            onFilterTap: _openFilter,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                for (final _ in _tabs)
                  _MobileOrderList(
                    orders: _filteredOrders,
                    onOpenDetail: _openOrderDetail,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Desktop layout — matches Figma node 31:719
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header (Figma 31:766 — h:95, pt:24, px:32) ─────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Commandes internes',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Demandes de réappro · workflow Commercial → Gérante → Patronne',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _DesktopHeaderButton(
                  label: '⇕ Filtres',
                  onTap: _openFilter,
                ),
                const SizedBox(width: 12),
                _DesktopHeaderButton(
                  label: '↻ Rafraîchir',
                  onTap: () => setState(() {}),
                ),
              ],
            ),
          ),

          // ── Tabs (Figma 31:781 — h:47, pl:32, border-b) ───────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom:
                    BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            padding: const EdgeInsets.only(left: 32),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: _buildTabWidgets(mobile: false),
            ),
          ),

          // ── KPI row ─────────────────────────────────────────────────────
          InternalOrderKpiRow(allOrders: mockInternalOrders),

          // ── Table section ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  _DesktopTableSection(
                    sectionLabel: _tabSectionLabels[i],
                    orders: _filteredOrders,
                    onOpenDetail: _openOrderDetail,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab widgets ─────────────────────────────────────────────────────────

  List<Widget> _buildTabWidgets({required bool mobile}) {
    return [
      for (int i = 0; i < _tabs.length; i++)
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_tabLabels[i]),
              _TabBadge(
                count: internalOrdersByStatus(_tabs[i]).length,
                isActive: _tabCtrl.index == i,
                mobile: mobile,
              ),
            ],
          ),
        ),
    ];
  }
}

// ── Desktop header button (outlined) ────────────────────────────────────────

class _DesktopHeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DesktopHeaderButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: AppColors.border, width: 0.8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        foregroundColor: AppColors.textPrimary,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Tab badge ───────────────────────────────────────────────────────────────

class _TabBadge extends StatelessWidget {
  final int count;
  final bool isActive;
  final bool mobile;
  const _TabBadge(
      {required this.count, required this.isActive, this.mobile = true});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    if (mobile) {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );
    }

    // Desktop: blue pill badge
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary)),
    );
  }
}

// ── Mobile search + filter bar ──────────────────────────────────────────────

class _MobileSearchFilterBar extends StatelessWidget {
  final String search;
  final int filterCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  const _MobileSearchFilterBar({
    required this.search,
    required this.filterCount,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher une commande…',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: AppColors.textSecondary),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onFilterTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(
                  color:
                      filterCount > 0 ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                minimumSize: Size.zero,
              ),
              icon: Icon(Icons.tune,
                  size: 18,
                  color: filterCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary),
              label: Text(
                filterCount > 0 ? 'Filtres ($filterCount)' : 'Filtres',
                style: TextStyle(
                  fontSize: 13,
                  color: filterCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile order list ───────────────────────────────────────────────────────

class _MobileOrderList extends StatelessWidget {
  final List<InternalOrder> orders;
  final ValueChanged<InternalOrder> onOpenDetail;
  const _MobileOrderList({required this.orders, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: orders.length,
      itemBuilder: (_, i) => InternalOrderCard(
        order: orders[i],
        onTap: () => onOpenDetail(orders[i]),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 32, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Aucune commande',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Les commandes correspondant à ces critères\napparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop table section — Figma node 31:839
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTableSection extends StatelessWidget {
  final String sectionLabel;
  final List<InternalOrder> orders;
  final ValueChanged<InternalOrder> onOpenDetail;
  const _DesktopTableSection(
      {required this.sectionLabel,
      required this.orders,
      required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const _EmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header (Figma 31:840 — pt:25, px:25, gap:18)
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sectionLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    '${orders.length} demande${orders.length > 1 ? 's' : ''}',
                    style: AppTextStyles.labelSmall
                        .copyWith(letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            // Table
            _OrderDataTable(
              orders: orders,
              onOpenDetail: onOpenDetail,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop data table — Figma node 31:847 ──────────────────────────────────
// Column flex proportions from Figma (total ≈ 1163px):
// N°: 145 → flex 12, DEMANDE: 221 → flex 19, COMMERCIAL: 186 → flex 16,
// WORKFLOW: 166 → flex 14, STATUT: 167 → flex 14, MONTANT: 133 → flex 11,
// Actions: 145 → flex 12

class _OrderDataTable extends StatelessWidget {
  final List<InternalOrder> orders;
  final ValueChanged<InternalOrder> onOpenDetail;
  const _OrderDataTable({required this.orders, required this.onOpenDetail});

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8)),
          ),
          child: Row(
            children: [
              _cell(12, const Text('N°', style: _headerStyle)),
              _cell(19, const Text('DEMANDE', style: _headerStyle)),
              _cell(16, const Text('COMMERCIAL', style: _headerStyle)),
              _cell(14, const Text('WORKFLOW', style: _headerStyle)),
              _cell(14, const Text('STATUT', style: _headerStyle)),
              _cell(11,
                  const Text('MONTANT', style: _headerStyle, textAlign: TextAlign.right),
                  align: Alignment.centerRight),
              _cell(12, const SizedBox.shrink()),
            ],
          ),
        ),
        // Data rows
        ...orders.map((o) => _buildRow(context, o)),
      ],
    );
  }

  Widget _cell(int flex, Widget child, {Alignment align = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(alignment: align, child: child),
      ),
    );
  }

  Widget _buildRow(BuildContext context, InternalOrder o) {
    final isHighlighted = o.isMyTurn;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFF8FBFF) : Colors.transparent,
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // N°
          _cell(
            12,
            Text(o.id,
                style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ),
          // Demande
          _cell(
            19,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(o.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${o.productCount} produit${o.productCount > 1 ? 's' : ''} · ${o.supplierName}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Commercial
          _cell(
            16,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.chipActionBg,
                  child: Text(o.commercialInitial,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(o.commercialName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      Text(formatTimeAgo(o.createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Workflow
          _cell(14, WorkflowStepper(steps: o.steps, showLabels: false)),
          // Statut
          _cell(14, InternalOrderStatusBadge(order: o)),
          // Montant
          _cell(
            11,
            Text('~ ${formatAmount(o.estimatedAmount)} F',
                style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            align: Alignment.centerRight,
          ),
          // Action
          _cell(
            12,
            isHighlighted
                ? FilledButton(
                    onPressed: () => onOpenDetail(o),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: const Text('Examiner \u2192',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  )
                : OutlinedButton(
                    onPressed: () => onOpenDetail(o),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      side: const BorderSide(
                          color: AppColors.border, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: const Text('Voir',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
            align: Alignment.centerRight,
          ),
        ],
      ),
    );
  }
}
