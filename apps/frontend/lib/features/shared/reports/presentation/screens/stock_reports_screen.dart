import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';

// ── Period ────────────────────────────────────────────────────────────────────

enum _Period { today, week, month, custom }

extension _PeriodLabel on _Period {
  String get label => switch (this) {
        _Period.today => "Aujourd'hui",
        _Period.week => 'Cette semaine',
        _Period.month => 'Ce mois',
        _Period.custom => 'Personnalisé',
      };

  DateTimeRange toRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _Period.today => DateTimeRange(start: today, end: today),
      _Period.week =>
        DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today),
      _Period.month =>
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
      _Period.custom =>
        DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today),
    };
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _stockReportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final _stockReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};
  final range = ref.watch(_stockReportDateRangeProvider);
  final now = DateTime.now();
  final effective = range ??
      DateTimeRange(
          start: now.subtract(const Duration(days: 6)), end: now);
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final fmt = DateFormat('yyyy-MM-dd');
  final uri = Uri.parse('${ApiConstants.baseUrl}/reports/stock/stats')
      .replace(queryParameters: {
    'from': fmt.format(effective.start),
    'to': fmt.format(effective.end),
  });
  try {
    final response = await http
        .get(uri, headers: ApiConstants.headers(tenantId: tenantId, token: token))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (_) {}
  return {};
});

final _stockMovementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final range = ref.watch(_stockReportDateRangeProvider);
  final now = DateTime.now();
  final effective = range ??
      DateTimeRange(
          start: now.subtract(const Duration(days: 6)), end: now);
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final fmt = DateFormat('yyyy-MM-dd');
  final uri =
      Uri.parse('${ApiConstants.baseUrl}/reports/stock/movements').replace(
    queryParameters: {
      'from': fmt.format(effective.start),
      'to': fmt.format(effective.end),
    },
  );
  try {
    final response = await http
        .get(uri, headers: ApiConstants.headers(tenantId: tenantId, token: token))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List;
      return body.cast<Map<String, dynamic>>();
    }
  } catch (_) {}
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StockReportsScreen extends ConsumerStatefulWidget {
  const StockReportsScreen({super.key});

  @override
  ConsumerState<StockReportsScreen> createState() => _StockReportsScreenState();
}

class _StockReportsScreenState extends ConsumerState<StockReportsScreen> {
  _Period _period = _Period.week;
  String _mvtFilter = 'Tous';

  // GenUI state
  final _genUiCtrl = TextEditingController();
  bool _genUiAsked = false;
  bool _genUiLoading = false;

  @override
  void dispose() {
    _genUiCtrl.dispose();
    super.dispose();
  }

  void _applyPeriod(_Period p, [DateTimeRange? custom]) {
    setState(() => _period = p);
    ref.read(_stockReportDateRangeProvider.notifier).state =
        custom ?? p.toRange();
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _period.toRange(),
    );
    if (range != null && mounted) _applyPeriod(_Period.custom, range);
  }

  Future<void> _sendGenUiQuery() async {
    if (_genUiCtrl.text.trim().isEmpty) return;
    setState(() {
      _genUiAsked = false;
      _genUiLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _genUiLoading = false;
      _genUiAsked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_stockReportProvider);
    final movementsAsync = ref.watch(_stockMovementsProvider);
    final catalogAsync = ref.watch(catalogProvider);

    final stats = statsAsync.valueOrNull ?? {};
    final receptionCount = stats['receptionCount'] as int? ?? 0;
    final receptionProducts = stats['receptionProductCount'] as int? ?? 0;
    final frotteLoss = (stats['frotteLossKg'] as num?)?.toDouble() ?? 0.0;
    final criticalCount = stats['criticalCount'] as int? ?? 0;
    final totalStockValue = (stats['totalStockValue'] as num?)?.toDouble() ?? 0.0;

    final movements = movementsAsync.valueOrNull ?? [];
    final filteredMvt = _mvtFilter == 'Tous'
        ? movements
        : movements.where((m) {
            final type = m['type']?.toString() ?? '';
            return switch (_mvtFilter) {
              'Réceptions' => type == 'DELIVERY',
              'Ventes' => type == 'SALE',
              'Ajustements' => type == 'ADJUSTMENT',
              _ => true,
            };
          }).toList();

    final items = catalogAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Rapports — Stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_stockReportProvider);
              ref.invalidate(_stockMovementsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Period tabs ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _PeriodTabsBar(
              selected: _period,
              onSelect: _applyPeriod,
              onCustomTap: _pickCustomRange,
            ),
          ),

          // ── KPI row ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _KpiCard(
                    label: 'Réceptions',
                    value: '$receptionCount',
                    sub: '$receptionProducts produits',
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Pertes Frotte',
                    value: frotteLoss > 0
                        ? '−${frotteLoss.toStringAsFixed(1)} kg'
                        : '—',
                    valueColor: frotteLoss > 0 ? AppColors.error : null,
                    sub: 'produits frais',
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Critiques',
                    value: '$criticalCount',
                    valueColor:
                        criticalCount > 0 ? AppColors.error : AppColors.success,
                    sub: 'en rupture / bas',
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Valeur stock',
                    value: totalStockValue > 0
                        ? NumberFormat('#,###', 'fr_FR')
                            .format(totalStockValue.toInt())
                            .replaceAll(',', ' ')
                        : '—',
                    sub: 'XOF estimé',
                    valueFontSize: 16,
                  ),
                ],
              ),
            ),
          ),

          // ── Mouvements ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MovementsCard(
                movements: filteredMvt,
                loading: movementsAsync.isLoading,
                activeFilter: _mvtFilter,
                onFilterChange: (f) => setState(() => _mvtFilter = f),
              ),
            ),
          ),

          // ── Niveaux actuels ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _StockLevelsCard(items: items),
            ),
          ),

          // ── GenUI ─────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: _GenUiCard(
                ctrl: _genUiCtrl,
                loading: _genUiLoading,
                asked: _genUiAsked,
                onSend: _sendGenUiQuery,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period Tabs Bar ───────────────────────────────────────────────────────────

class _PeriodTabsBar extends StatelessWidget {
  final _Period selected;
  final void Function(_Period, [DateTimeRange?]) onSelect;
  final VoidCallback onCustomTap;

  const _PeriodTabsBar({
    required this.selected,
    required this.onSelect,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Period.values.map((p) {
            final isActive = p == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: p == _Period.custom ? onCustomTap : () => onSelect(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color:
                          isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String sub;
  final double valueFontSize;

  const _KpiCard({
    required this.label,
    required this.value,
    this.valueColor,
    required this.sub,
    this.valueFontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Movements Card ────────────────────────────────────────────────────────────

class _MovementsCard extends StatelessWidget {
  final List<Map<String, dynamic>> movements;
  final bool loading;
  final String activeFilter;
  final ValueChanged<String> onFilterChange;

  const _MovementsCard({
    required this.movements,
    required this.loading,
    required this.activeFilter,
    required this.onFilterChange,
  });

  static const _filters = ['Tous', 'Réceptions', 'Ventes', 'Ajustements'];

  static const _typeLabels = {
    'DELIVERY': 'Réception',
    'SALE': 'Vente',
    'ADJUSTMENT': 'Ajustement',
    'LOSS': 'Perte',
    'RETURN': 'Retour',
  };

  Color _badgeColor(String type) => switch (type) {
        'DELIVERY' => const Color(0xFF166534),
        'SALE' => const Color(0xFF1E40AF),
        'ADJUSTMENT' => const Color(0xFF475569),
        'LOSS' => const Color(0xFF991B1B),
        _ => AppColors.textSecondary,
      };

  Color _badgeBg(String type) => switch (type) {
        'DELIVERY' => const Color(0xFFDCFCE7),
        'SALE' => const Color(0xFFDBEAFE),
        'ADJUSTMENT' => const Color(0xFFF1F5F9),
        'LOSS' => const Color(0xFFFEE2E2),
        _ => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mouvements de la semaine',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isActive = f == activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onFilterChange(f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ))
          else if (movements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Aucun mouvement sur cette période',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: const [
                      Expanded(
                          flex: 3,
                          child: Text('Produit',
                              style: _headerStyle)),
                      Expanded(
                          flex: 3,
                          child: Text('Mouvement',
                              style: _headerStyle)),
                      Expanded(
                          flex: 2,
                          child: Text('Quantité',
                              style: _headerStyle)),
                      Expanded(
                          flex: 2,
                          child: Text('Date',
                              style: _headerStyle)),
                      Expanded(
                          flex: 2,
                          child: Text('Responsable',
                              style: _headerStyle)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...movements.map((m) {
                  final type = m['type']?.toString() ?? '';
                  final label = _typeLabels[type] ?? type;
                  final qty = m['quantity']?.toString() ?? '—';
                  final sign =
                      type == 'DELIVERY' ? '+' : (type == 'SALE' ? '−' : '');
                  final qtyColor = type == 'DELIVERY'
                      ? const Color(0xFF166534)
                      : (type == 'SALE'
                          ? const Color(0xFF1E40AF)
                          : AppColors.textSecondary);
                  final productName =
                      m['productName']?.toString() ?? '—';
                  final date = m['date']?.toString() ?? '';
                  final responsible =
                      m['responsibleName']?.toString() ?? '—';
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(productName,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis)),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _badgeBg(type),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _badgeColor(type)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '$sign$qty',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: qtyColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(date,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(responsible,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

// ── Stock Levels Card ─────────────────────────────────────────────────────────

class _StockLevelsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _StockLevelsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Niveaux actuels',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final stock =
                  (item['stockQuantity'] as num?)?.toDouble() ?? 0.0;
              final min =
                  (item['minStockLevel'] as num?)?.toDouble();
              final max = (item['maxStockLevel'] as num?)?.toDouble() ??
                  (min != null ? min * 4 : 100.0);
              final pct = max > 0 ? (stock / max).clamp(0.0, 1.0) : 0.0;

              final _StockStatus status;
              if (min != null && stock < min * 0.2) {
                status = _StockStatus.critical;
              } else if (min != null && stock < min) {
                status = _StockStatus.low;
              } else {
                status = _StockStatus.ok;
              }

              final unit = item['unit']?.toString() ?? '';
              final qtyStr =
                  '${stock % 1 == 0 ? stock.toInt() : stock.toStringAsFixed(1)} $unit';

              return _StockLevelItem(
                name: item['name']?.toString() ?? '—',
                qty: qtyStr,
                percent: pct,
                status: status,
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _StockStatus { critical, low, ok }

class _StockLevelItem extends StatelessWidget {
  final String name;
  final String qty;
  final double percent;
  final _StockStatus status;

  const _StockLevelItem({
    required this.name,
    required this.qty,
    required this.percent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (borderColor, bgColor, barColor, statusLabel, statusColor) =
        switch (status) {
      _StockStatus.critical => (
          const Color(0xFFFCA5A5),
          const Color(0xFFFEF2F2),
          AppColors.error,
          'Critique',
          const Color(0xFF991B1B),
        ),
      _StockStatus.low => (
          const Color(0xFFFDE68A),
          const Color(0xFFFFFBEB),
          const Color(0xFFFFCC00),
          'Bas',
          const Color(0xFF92400E),
        ),
      _StockStatus.ok => (
          const Color(0xFF86EFAC),
          const Color(0xFFF0FDF4),
          AppColors.success,
          'OK',
          const Color(0xFF166534),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(qty,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GenUI Card ────────────────────────────────────────────────────────────────

class _GenUiCard extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final bool asked;
  final VoidCallback onSend;

  const _GenUiCard({
    required this.ctrl,
    required this.loading,
    required this.asked,
    required this.onSend,
  });

  static const _suggested = [
    'Quel produit génère le plus de pertes ?',
    'Combien ai-je perdu en Taux de Frotte ?',
    'Mon stock a-t-il augmenté ce mois ?',
    'Quelle est la rotation de mes produits frais ?',
  ];

  static const _priorities = [
    (
      icon: '🔴',
      name: 'Sel',
      stock: 'Stock : 0,5 kg · Vente moy. 0,3 kg/j',
      verdict: 'En rupture',
      verdictColor: Color(0xFF991B1B),
      verdictBg: Color(0xFFFEE2E2),
    ),
    (
      icon: '🔴',
      name: 'Sucre en poudre',
      stock: 'Stock : 2 kg · Vente moy. 1,5 kg/j',
      verdict: 'Rupture dans 1 jour',
      verdictColor: Color(0xFF991B1B),
      verdictBg: Color(0xFFFEE2E2),
    ),
    (
      icon: '🟠',
      name: 'Huile végétale',
      stock: 'Stock : 19 bt. · Vente moy. 6 bt./j',
      verdict: 'Bas — 3 jours restants',
      verdictColor: Color(0xFF92400E),
      verdictBg: Color(0xFFFEF3C7),
    ),
    (
      icon: '🟠',
      name: 'Savon Lux',
      stock: 'Stock : 66 pcs. · Vente moy. 10 pcs./j',
      verdict: 'Bas — environ 1 semaine',
      verdictColor: Color(0xFF92400E),
      verdictBg: Color(0xFFFEF3C7),
    ),
    (
      icon: '🟡',
      name: 'Lait en poudre',
      stock: 'Stock : 38 boîtes · Vente moy. 5 bt./j',
      verdict: 'À surveiller',
      verdictColor: Color(0xFF854D0E),
      verdictBg: Color(0xFFFEF9C3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rainbow top border
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFFFFCC00),
                Color(0xFF1A73E8),
                Color(0xFF34A853),
                Color(0xFFEA4335),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text('✨ Analyse IA',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        border: Border.all(
                            color: const Color(0xFFFDE68A)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Premium',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF854D0E))),
                    ),
                    const Spacer(),
                    const Text(
                      'Basé sur vos ventes et stock actuels',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          hintText:
                              "Qu'est-ce que je dois réapprovisionner en priorité ?",
                          hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: FilledButton(
                        onPressed: loading ? null : onSend,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.arrow_upward, size: 18),
                      ),
                    ),
                  ],
                ),

                // Response
                if (loading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ] else if (asked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voici votre liste de réapprovisionnement prioritaire :',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF166534)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Basé sur les 7 derniers jours',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF4ADE80)),
                        ),
                        const SizedBox(height: 12),
                        ..._priorities.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Text(p.icon,
                                        style: const TextStyle(
                                            fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          Text(p.stock,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.verdictBg,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.verdict,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: p.verdictColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 4),
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Bon de commande — fonctionnalité à venir'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.assignment_outlined,
                              size: 16),
                          label: const Text(
                              'Générer bon de commande →',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Suggested questions
                const SizedBox(height: 16),
                const Text(
                  'QUESTIONS SUGGÉRÉES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggested
                      .map(
                        (q) => GestureDetector(
                          onTap: () {
                            ctrl.text = q;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(q,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
