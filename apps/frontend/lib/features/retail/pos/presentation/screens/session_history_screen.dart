import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fcfa(num v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

String _initials(String? fullName, String? email) {
  final source = fullName ?? email ?? '?';
  final parts = source.trim().split(RegExp(r'[\s@._]+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
}

Color _avatarColor(String userId) {
  const colors = [
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
  ];
  return colors[userId.hashCode.abs() % colors.length];
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _DateFilter { week7, days30, month, all }

extension _DateFilterLabel on _DateFilter {
  String get label {
    switch (this) {
      case _DateFilter.week7:
        return '7 derniers jours';
      case _DateFilter.days30:
        return '30 derniers jours';
      case _DateFilter.month:
        return 'Ce mois';
      case _DateFilter.all:
        return 'Tout';
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _UserInfo {
  final String userId;
  final String? fullName;
  final String? email;

  const _UserInfo({required this.userId, this.fullName, this.email});

  String get displayName => fullName ?? email ?? userId.substring(0, 8);
  String get initials => _initials(fullName, email);
  Color get color => _avatarColor(userId);
}

// ── Provider ──────────────────────────────────────────────────────────────────

// Combined provider: [sessions, users]
final _historyDataProvider = FutureProvider.autoDispose
    .family<_HistoryData, String>((ref, tenantId) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final headers = {
    'Content-Type': 'application/json',
    'x-tenant-id': tenantId,
    if (token != null) 'Authorization': 'Bearer $token',
  };

  final sessionsFuture = http.get(
    Uri.parse('${ApiConstants.baseUrl}/retail/sessions/reports')
        .replace(queryParameters: {'tenantId': tenantId}),
    headers: headers,
  ).timeout(const Duration(seconds: 15));

  final usersFuture = http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/my-users'),
    headers: headers,
  ).timeout(const Duration(seconds: 15));

  final results = await Future.wait([sessionsFuture, usersFuture]);
  final sessionsResp = results[0];
  final usersResp = results[1];

  if (sessionsResp.statusCode != 200) {
    throw Exception('Erreur sessions ${sessionsResp.statusCode}');
  }

  final sessions =
      (jsonDecode(sessionsResp.body) as List).cast<Map<String, dynamic>>();

  final userMap = <String, _UserInfo>{};
  if (usersResp.statusCode == 200) {
    final users =
        (jsonDecode(usersResp.body) as List).cast<Map<String, dynamic>>();
    for (final u in users) {
      final id = u['userId'] as String? ?? '';
      if (id.isNotEmpty) {
        userMap[id] = _UserInfo(
          userId: id,
          fullName: u['fullName'] as String?,
          email: u['email'] as String?,
        );
      }
    }
  }

  return _HistoryData(sessions: sessions, userMap: userMap);
});

class _HistoryData {
  final List<Map<String, dynamic>> sessions;
  final Map<String, _UserInfo> userMap;

  const _HistoryData({required this.sessions, required this.userMap});
}

// ── KPIs ──────────────────────────────────────────────────────────────────────

class _KpiData {
  final int count;
  final double totalSales;
  final double cumulativeVariance;
  final int balancedCount;

  const _KpiData({
    required this.count,
    required this.totalSales,
    required this.cumulativeVariance,
    required this.balancedCount,
  });

  factory _KpiData.from(List<Map<String, dynamic>> sessions) {
    double sales = 0;
    double variance = 0;
    int balanced = 0;

    for (final s in sessions) {
      final v = s['variance'] != null
          ? double.tryParse(s['variance'].toString()) ?? 0
          : 0.0;
      final totalSales = s['total_sales'] != null
          ? double.tryParse(s['total_sales'].toString()) ?? 0
          : 0.0;
      final closingBal = s['closing_balance'] != null
          ? double.tryParse(s['closing_balance'].toString()) ?? 0
          : 0.0;
      // Use closing_balance as proxy for CA if total_sales not in reports payload
      sales += closingBal > 0 ? closingBal : totalSales;
      variance += v;
      if (v == 0) balanced++;
    }

    return _KpiData(
      count: sessions.length,
      totalSales: sales,
      cumulativeVariance: variance,
      balancedCount: balanced,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  _DateFilter _filter = _DateFilter.week7;

  List<Map<String, dynamic>> _applyFilter(
      List<Map<String, dynamic>> all, _DateFilter filter) {
    if (filter == _DateFilter.all) return all;
    final now = DateTime.now();
    DateTime cutoff;
    switch (filter) {
      case _DateFilter.week7:
        cutoff = now.subtract(const Duration(days: 7));
      case _DateFilter.days30:
        cutoff = now.subtract(const Duration(days: 30));
      case _DateFilter.month:
        cutoff = DateTime(now.year, now.month, 1);
      case _DateFilter.all:
        return all;
    }
    return all.where((s) {
      final closedStr = s['closed_at'] as String?;
      if (closedStr == null) return false;
      final closed = DateTime.tryParse(closedStr);
      return closed != null && closed.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(activeTenantProvider) ?? '';
    final dataAsync = ref.watch(_historyDataProvider(tenantId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Historique sessions',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_historyDataProvider(tenantId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          error: '$e',
          onRetry: () => ref.invalidate(_historyDataProvider(tenantId)),
        ),
        data: (data) {
          final filtered = _applyFilter(data.sessions, _filter);
          final kpi = _KpiData.from(filtered);

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_historyDataProvider(tenantId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Filter row ───────────────────────────────────────────
                _FilterRow(
                  selected: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 16),

                // ── KPI cards ────────────────────────────────────────────
                _KpiRow(kpi: kpi, filter: _filter),
                const SizedBox(height: 20),

                // ── Sessions list ────────────────────────────────────────
                if (filtered.isEmpty)
                  _EmptyState(filter: _filter)
                else
                  _SessionList(
                    sessions: filtered,
                    userMap: data.userMap,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _DateFilter selected;
  final ValueChanged<_DateFilter> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DateFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onChanged(f),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final _KpiData kpi;
  final _DateFilter filter;

  const _KpiRow({required this.kpi, required this.filter});

  @override
  Widget build(BuildContext context) {
    final balancedPct = kpi.count > 0
        ? '${((kpi.balancedCount / kpi.count) * 100).round()}% équilibrées'
        : '—';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Sessions',
                value: '${kpi.count}',
                sub: filter.label,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'CA total',
                value: kpi.totalSales >= 1000000
                    ? '${(kpi.totalSales / 1000000).toStringAsFixed(2)}M'
                    : kpi.totalSales >= 1000
                        ? '${(kpi.totalSales / 1000).toStringAsFixed(0)}K'
                        : kpi.totalSales.toStringAsFixed(0),
                sub: 'FCFA',
                valueColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Écarts cumulés',
                value: kpi.cumulativeVariance == 0
                    ? '0'
                    : '${kpi.cumulativeVariance > 0 ? '+' : ''}${kpi.cumulativeVariance.toStringAsFixed(0)}',
                sub: 'FCFA',
                valueColor: kpi.cumulativeVariance < 0
                    ? AppColors.error
                    : kpi.cumulativeVariance > 0
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Sans écart',
                value: '${kpi.balancedCount} / ${kpi.count}',
                sub: balancedPct,
                valueColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sessions list ─────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Map<String, _UserInfo> userMap;

  const _SessionList({required this.sessions, required this.userMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _ColHeader('Date')),
                Expanded(flex: 3, child: _ColHeader('Caissier')),
                Expanded(
                    flex: 2,
                    child: _ColHeader('Écart', align: TextAlign.right)),
                Expanded(
                    flex: 2,
                    child: _ColHeader('Signatures',
                        align: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...sessions.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast = i == sessions.length - 1;
            final userId = s['user_id'] as String? ?? '';
            final user = userMap[userId] ??
                _UserInfo(userId: userId.isEmpty ? 'XX' : userId);
            return _SessionRow(
              session: s,
              user: user,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final TextAlign align;

  const _ColHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final Map<String, dynamic> session;
  final _UserInfo user;
  final bool isLast;

  const _SessionRow({
    required this.session,
    required this.user,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final closedAtStr = session['closed_at'] as String?;
    final closedAt =
        closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;

    final variance = session['variance'] != null
        ? double.tryParse(session['variance'].toString())
        : null;

    // Audit trail dots
    final hasManagerSigned = session['manager_validated_at'] != null;
    final hasOwnerSigned = session['owner_signed_at'] != null;
    // Cashier always submitted (it's in CLOSED status)
    const cashierSigned = true;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Date ─────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    closedAt != null
                        ? DateFormat('d MMM yyyy', 'fr_FR').format(closedAt)
                        : '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (closedAt != null)
                    Text(
                      DateFormat('HH:mm', 'fr_FR').format(closedAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),

            // ── Caissier ──────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: user.color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Écart ─────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: variance == null
                  ? const Text('—',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary))
                  : Text(
                      variance == 0
                          ? '0 FCFA'
                          : '${variance > 0 ? '+' : ''}${_fcfa(variance)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: variance == 0
                            ? Colors.green.shade700
                            : AppColors.error,
                      ),
                    ),
            ),

            // ── Signatures ────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SigDot(signed: cashierSigned),
                  const SizedBox(width: 3),
                  _SigDot(signed: hasManagerSigned),
                  const SizedBox(width: 3),
                  _SigDot(signed: hasOwnerSigned),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SigDot extends StatelessWidget {
  final bool signed;

  const _SigDot({required this.signed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: signed ? Colors.green.shade500 : AppColors.border,
      ),
      child: signed
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _DateFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history,
                  size: 32, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune session',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune session clôturée sur « ${filter.label} ».',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Impossible de charger l\'historique',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
