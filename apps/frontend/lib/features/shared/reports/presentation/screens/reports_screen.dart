import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/reports/presentation/screens/session_history_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';
import 'package:frontend/features/shared/reports/presentation/screens/stock_reports_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

// ── Period tab ────────────────────────────────────────────────────────────────

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
      _Period.week => DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
      _Period.month => DateTimeRange(
          start: DateTime(now.year, now.month, 1), end: today),
      _Period.custom => DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
    };
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _Period _period = _Period.week;

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
    final range = custom ?? p.toRange();
    ref.read(salesReportDateRangeProvider.notifier).state = range;
    ref.read(salesStatsDateRangeProvider.notifier).state = range;
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

  void _fakeGenUiQuery() async {
    if (_genUiCtrl.text.trim().isEmpty) return;
    setState(() {
      _genUiAsked = false;
      _genUiLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _genUiLoading = false;
      _genUiAsked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final canSeeFullHistory = canAccessScreen(role, 'daily_sales', config) ||
        canAccessScreen(role, 'backoffice', config);
    final canSeeSessionHistory = canAccessScreen(role, 'pos', config);
    final canSeeAnalytics = canAccessScreen(role, 'backoffice', config);

    final reportAsync = ref.watch(salesReportProvider);
    final statsAsync = ref.watch(salesStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Rapports — Ventes',
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Rapports Stock',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const StockReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(salesReportProvider);
              ref.invalidate(salesStatsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Period tabs
          SliverToBoxAdapter(
            child: _PeriodTabsBar(
              selected: _period,
              onSelect: _applyPeriod,
              onCustomTap: _pickCustomRange,
            ),
          ),

          // KPI row (from daily stats)
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox(height: 8),
              error: (_, _) => const SizedBox.shrink(),
              data: (stats) => _KpiRow(
                stats: stats,
                period: _period,
              ),
            ),
          ),

          // Main report body
          SliverToBoxAdapter(
            child: reportAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (data) => _buildBody(
                data,
                canSeeFullHistory: canSeeFullHistory,
                canSeeSessionHistory: canSeeSessionHistory,
                canSeeAnalytics: canSeeAnalytics,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    Map<String, dynamic> data, {
    required bool canSeeFullHistory,
    required bool canSeeSessionHistory,
    required bool canSeeAnalytics,
  }) {
    final productSales = (data['productSales'] as List<dynamic>?) ?? [];
    final employeeSales =
        (data['employeeSales'] as List<dynamic>?) ?? [];
    final paymentMethodStats =
        (data['paymentMethodStats'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 7-day chart
          if (canSeeAnalytics) ...[
            _SectionCard(
              title: "CA — ${_period == _Period.today ? "Aujourd'hui" : "7 derniers jours"}",
              child: _BarChartWidget(),
            ),
            const SizedBox(height: 16),
          ],

          // Employee sales
          if (canSeeAnalytics && employeeSales.isNotEmpty) ...[
            _SectionCard(
              title: 'Ventes par employé',
              child: _EmployeeSalesSection(employees: employeeSales),
            ),
            const SizedBox(height: 16),
          ],

          // Payment methods
          if (canSeeAnalytics && paymentMethodStats.isNotEmpty) ...[
            _SectionCard(
              title: 'Répartition paiements',
              child: _PaymentMethodsSection(stats: paymentMethodStats),
            ),
            const SizedBox(height: 16),
          ],

          // GenUI AI section (owner only)
          if (canSeeAnalytics) ...[
            _GenUiCard(
              ctrl: _genUiCtrl,
              loading: _genUiLoading,
              asked: _genUiAsked,
              productSales: productSales,
              onSubmit: _fakeGenUiQuery,
              onSuggestion: (q) {
                _genUiCtrl.text = q;
                _fakeGenUiQuery();
              },
            ),
            const SizedBox(height: 16),
          ],

          // Quick links
          if (canSeeFullHistory) ...[
            _NavCard(
              icon: Icons.receipt_long,
              title: 'Historique des ventes',
              subtitle: 'Toutes les transactions par période',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (canSeeSessionHistory)
            _NavCard(
              key: const Key('session_history_card'),
              icon: Icons.point_of_sale,
              title: 'Sessions de caisse',
              subtitle: 'Sessions en cours et historique',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SessionHistoryScreen()),
              ),
            ),

          // Product sales table
          if (canSeeAnalytics && productSales.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Ventes par produit',
              child: _ProductSalesTable(productSales: productSales),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Period tabs ───────────────────────────────────────────────────────────────

class _PeriodTabsBar extends StatelessWidget {
  final _Period selected;
  final void Function(_Period) onSelect;
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _Period.values.map((p) {
              final isSelected = p == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      p == _Period.custom ? onCustomTap() : onSelect(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final List<dynamic> stats;
  final _Period period;

  const _KpiRow({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    double totalRevenue = 0;
    int saleCount = 0;
    String bestDay = '—';
    double bestRevenue = 0;

    for (final s in stats) {
      final rev = (s.revenue as double?) ?? 0.0;
      final cnt = (s.orderCount as int?) ?? 0;
      totalRevenue += rev;
      saleCount += cnt;
      if (rev > bestRevenue) {
        bestRevenue = rev;
        bestDay = DateFormat('EEEE', 'fr_FR').format(s.day as DateTime);
        bestDay = '${bestDay[0].toUpperCase()}${bestDay.substring(1)}';
      }
    }

    final avgTicket = saleCount > 0 ? totalRevenue / saleCount : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              label: 'CA ${period.label.toLowerCase()}',
              value: _fcfa(totalRevenue),
              valueColor: totalRevenue > 0 ? AppColors.success : null,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiCard(
              label: 'Transactions',
              value: '$saleCount',
              icon: Icons.receipt_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiCard(
              label: 'Ticket moyen',
              value: _fcfa(avgTicket),
              icon: Icons.confirmation_number_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiCard(
              label: 'Meilleur jour',
              value: bestDay,
              icon: Icons.star_outline,
              valueColor: bestDay != '—' ? Colors.amber.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Bar chart (inline div-style) ──────────────────────────────────────────────

class _BarChartWidget extends ConsumerWidget {
  const _BarChartWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);
    return statsAsync.when(
      loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.isEmpty) return const SizedBox.shrink();
        final maxRev =
            stats.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
        return SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.map((s) {
              final pct = maxRev > 0 ? s.revenue / maxRev : 0.0;
              final isBest = maxRev > 0 && s.revenue == maxRev;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: pct.clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBest
                                  ? Colors.amber.shade600
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E', 'fr_FR').format(s.day),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Employee sales ────────────────────────────────────────────────────────────

class _EmployeeSalesSection extends StatelessWidget {
  final List<dynamic> employees;
  const _EmployeeSalesSection({required this.employees});

  @override
  Widget build(BuildContext context) {
    final maxRev = employees
        .map((e) => (e['revenue'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: employees.take(5).map((e) {
        final name = e['name'] as String? ?? '—';
        final revenue = (e['revenue'] as num?)?.toDouble() ?? 0;
        final count = (e['count'] as num?)?.toInt() ?? 0;
        final pct = maxRev > 0 ? revenue / maxRev : 0.0;
        final initials = name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name.toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '$count vente${count > 1 ? 's' : ''} · ${_fcfa(revenue)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Payment methods ───────────────────────────────────────────────────────────

class _PaymentMethodsSection extends StatelessWidget {
  final List<dynamic> stats;
  const _PaymentMethodsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats
        .map((s) => (s['value'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a + b);

    const methodColors = {
      'Espèces': Color(0xFF10B981),
      'Orange Money': Color(0xFFF97316),
      'Moov Money': Color(0xFF3B82F6),
    };

    return Column(
      children: stats.map((s) {
        final name = s['name'] as String? ?? '—';
        final value = (s['value'] as num?)?.toDouble() ?? 0;
        final pct = total > 0 ? value / total : 0.0;
        final color = methodColors[name] ??
            AppColors.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          '${(pct * 100).round()}% · ${_fcfa(value)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.border,
                        color: color,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── GenUI card ────────────────────────────────────────────────────────────────

const _kSuggestedQuestions = [
  'Quel est mon produit le plus vendu ?',
  'Quelle heure est la plus rentable ?',
  'Quel employé a le meilleur CA ?',
];

class _GenUiCard extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final bool asked;
  final List<dynamic> productSales;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSuggestion;

  const _GenUiCard({
    required this.ctrl,
    required this.loading,
    required this.asked,
    required this.productSales,
    required this.onSubmit,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Premium',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '✨ Analyse IA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Posez une question sur vos ventes en langage naturel.',
            style:
                TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Ex : Quel est mon produit le plus vendu ?',
                    hintStyle: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A73E8), width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSubmit,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send,
                          size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Suggested questions
          if (!asked)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _kSuggestedQuestions.map((q) {
                return GestureDetector(
                  onTap: () => onSuggestion(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      q,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                );
              }).toList(),
            ),

          // AI response
          if (asked && !loading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: _GenUiResponse(productSales: productSales),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenUiResponse extends StatelessWidget {
  final List<dynamic> productSales;
  const _GenUiResponse({required this.productSales});

  @override
  Widget build(BuildContext context) {
    if (productSales.isEmpty) {
      return const Text(
        'Aucune donnée de vente disponible pour cette période.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      );
    }

    final sorted = [...productSales]..sort(
        (a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));
    final top = sorted.take(5).toList();
    final maxRev = (top.first['revenue'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 produits les plus vendus (par CA)',
          style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...top.map((p) {
          final name = p['name'] as String? ?? '—';
          final rev = (p['revenue'] as num).toDouble();
          final pct = maxRev > 0 ? rev / maxRev : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFF1E293B),
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fcfa(rev),
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Product sales table ───────────────────────────────────────────────────────

class _ProductSalesTable extends StatelessWidget {
  final List<dynamic> productSales;
  const _ProductSalesTable({required this.productSales});

  @override
  Widget build(BuildContext context) {
    final sorted = [...productSales]
      ..sort((a, b) =>
          (b['revenue'] as num).compareTo(a['revenue'] as num));

    return Column(
      children: sorted.map((item) {
        final qty = (item['quantity'] as num).toInt();
        final rev = (item['revenue'] as num).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(item['name'] as String? ?? '—',
                    style: const TextStyle(fontSize: 13)),
              ),
              Text('$qty',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 16),
              Text(_fcfa(rev),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
