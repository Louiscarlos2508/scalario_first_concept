import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/role_label_utils.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class SessionHistoryScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  const SessionHistoryScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(closedSessionsProvider);
    final dateRange = ref.watch(closedSessionsDateRangeProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Historique des sessions',
        leadingOverride: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        actions: [
          TextButton.icon(
            key: const Key('session_history_date_filter'),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateRange,
              );
              if (picked != null) {
                ref.read(closedSessionsDateRangeProvider.notifier).state =
                    picked;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange == null
                  ? 'Toute la période'
                  : '${DateFormat('dd/MM').format(dateRange.start)} – ${DateFormat('dd/MM').format(dateRange.end)}',
            ),
          ),
          if (dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Effacer le filtre',
              onPressed: () {
                ref.read(closedSessionsDateRangeProvider.notifier).state = null;
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(closedSessionsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              key: const Key('session_history_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.point_of_sale,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    dateRange == null
                        ? 'Aucune session clôturée'
                        : 'Aucune session sur cette période',
                    style:
                        const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(closedSessionsProvider),
            child: ListView.builder(
              key: const Key('session_history_list'),
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index] as Map<String, dynamic>;
                return _SessionCard(session: s);
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends ConsumerWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openedAt = session['openedAt'] != null
        ? DateTime.tryParse(session['openedAt'].toString())
        : null;
    final closedAt = session['closedAt'] != null
        ? DateTime.tryParse(session['closedAt'].toString())
        : null;
    final openingBalance =
        double.tryParse(session['openingBalance']?.toString() ?? '') ?? 0.0;
    final closingBalance =
        double.tryParse(session['closingBalance']?.toString() ?? '') ?? 0.0;
    final variance =
        double.tryParse(session['variance']?.toString() ?? '') ?? 0.0;
    final deviceId =
        session['deviceId']?.toString() ?? 'Terminal inconnu';
    final userId = session['userId']?.toString() ?? '';
    final userLabel =
        userId.length > 8 ? userId.substring(0, 8) : userId;
    final roleLabels = ref
        .watch(businessTypeConfigProvider)
        .valueOrNull
        ?.roleLabels ?? {};
    final cashierLabel = getRoleLabel('cashier', roleLabels);

    final varianceColor =
        variance >= 0 ? AppColors.success : AppColors.error;

    return Card(
      key: Key('session_card_${session['id']}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showZReport(context, ref, session['id'].toString()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row — device + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.point_of_sale,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        deviceId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (openedAt != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(openedAt.toLocal()),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Caissier + horaire
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$cashierLabel : $userLabel…',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (openedAt != null && closedAt != null)
                    Text(
                      '${DateFormat('HH:mm').format(openedAt.toLocal())} → ${DateFormat('HH:mm').format(closedAt.toLocal())}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const Divider(height: 16),

              // Financial summary
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                        label: 'Fond de caisse',
                        value: _fcfa(openingBalance)),
                  ),
                  Expanded(
                    child: _Stat(
                        label: 'Clôturé',
                        value: _fcfa(closingBalance)),
                  ),
                  _VarianceStat(variance: variance, color: varianceColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showZReport(
      BuildContext context, WidgetRef ref, String sessionId) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ZReportDialog(sessionId: sessionId),
    );
  }
}

// ── Stat helpers ──────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VarianceStat extends StatelessWidget {
  final double variance;
  final Color color;
  const _VarianceStat({required this.variance, required this.color});

  @override
  Widget build(BuildContext context) {
    final sign = variance > 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Écart',
            style: TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          '$sign${_fcfa(variance)}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// ── Z-Report dialog ───────────────────────────────────────────────────────────

class _ZReportDialog extends ConsumerWidget {
  final String sessionId;
  const _ZReportDialog({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));

    return Dialog(
      key: const Key('z_report_dialog'),
      child: detailAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erreur : $e'),
        ),
        data: (detail) => _ZReportContent(detail: detail),
      ),
    );
  }
}

class _ZReportContent extends StatelessWidget {
  final Map<String, dynamic> detail;
  const _ZReportContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final session = detail['session'] as Map<String, dynamic>? ?? {};
    final totalsByMethod =
        (detail['totalsByMethod'] as Map<String, dynamic>?) ?? {};
    final grossSales =
        (detail['grossSales'] as Map<String, dynamic>?) ?? {};
    final returns = (detail['returns'] as Map<String, dynamic>?) ?? {};
    final netSales =
        (detail['netSales'] as Map<String, dynamic>?) ?? {};

    final openingBalance =
        double.tryParse(detail['openingBalance']?.toString() ?? '') ?? 0;
    final theoreticalBalance =
        double.tryParse(detail['theoreticalBalance']?.toString() ?? '') ?? 0;
    final closingBalance =
        double.tryParse(detail['closingBalance']?.toString() ?? '') ?? 0;
    final variance =
        double.tryParse(detail['variance']?.toString() ?? '') ?? 0;
    final varianceExplanation =
        detail['varianceExplanation']?.toString();

    final openedAt = session['openedAt'] != null
        ? DateTime.tryParse(session['openedAt'].toString())
        : null;
    final closedAt = session['closedAt'] != null
        ? DateTime.tryParse(session['closedAt'].toString())
        : null;
    final deviceId =
        session['deviceId']?.toString() ?? 'Terminal inconnu';

    final varianceColor = variance >= 0 ? AppColors.success : AppColors.error;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Z-Report — $deviceId',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Body
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timing
                if (openedAt != null || closedAt != null) ...[
                  _SectionTitle('Horaires'),
                  _Row('Ouverture',
                      openedAt != null ? fmt.format(openedAt.toLocal()) : '—'),
                  _Row('Clôture',
                      closedAt != null ? fmt.format(closedAt.toLocal()) : '—'),
                  const SizedBox(height: 16),
                ],

                // Sales by method
                _SectionTitle('Ventes par méthode de paiement'),
                if (totalsByMethod.isEmpty)
                  const Text('Aucune vente',
                      style:
                          TextStyle(color: AppColors.textSecondary))
                else
                  ...totalsByMethod.entries.map((e) => _Row(
                        e.key,
                        _fcfa(double.tryParse(e.value.toString()) ?? 0),
                      )),
                const Divider(height: 20),
                _Row(
                  'Total brut (${(grossSales['count'] as num?)?.toInt() ?? 0} transactions)',
                  _fcfa(double.tryParse(grossSales['amount']?.toString() ?? '') ?? 0),
                  bold: true,
                ),
                if (((returns['count'] as num?)?.toInt() ?? 0) > 0)
                  _Row(
                    'Retours (${(returns['count'] as num?)?.toInt() ?? 0})',
                    '- ${_fcfa(double.tryParse(returns['amount']?.toString() ?? '') ?? 0)}',
                    color: AppColors.error,
                  ),
                _Row(
                  'Total net',
                  _fcfa(double.tryParse(netSales['amount']?.toString() ?? '') ?? 0),
                  bold: true,
                ),
                const SizedBox(height: 16),

                // Cash reconciliation
                _SectionTitle('Réconciliation caisse'),
                _Row('Fond d\'ouverture', _fcfa(openingBalance)),
                _Row('Total théorique', _fcfa(theoreticalBalance)),
                _Row('Déclaré (clôture)', _fcfa(closingBalance), bold: true),
                const Divider(height: 12),
                _Row(
                  'Écart',
                  '${variance >= 0 ? '+' : ''}${_fcfa(variance)}',
                  bold: true,
                  color: varianceColor,
                ),
                if (varianceExplanation != null &&
                    varianceExplanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Explication de l\'écart',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(varianceExplanation),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(color: color ?? AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}
