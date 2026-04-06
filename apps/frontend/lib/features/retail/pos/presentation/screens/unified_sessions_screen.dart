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
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart'
    show activeSessionsProvider, closedSessionsProvider, closedSessionsDateRangeProvider, sessionDetailProvider;
import 'package:frontend/features/retail/pos/presentation/screens/sessions_pending_screen.dart'
    show pendingSessionsProvider;
import 'package:frontend/features/retail/pos/presentation/screens/session_validate_screen.dart';
import 'package:frontend/features/retail/pos/presentation/screens/session_sign_screen.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class UnifiedSessionsScreen extends ConsumerStatefulWidget {
  const UnifiedSessionsScreen({super.key});

  @override
  ConsumerState<UnifiedSessionsScreen> createState() =>
      _UnifiedSessionsScreenState();
}

class _UnifiedSessionsScreenState extends ConsumerState<UnifiedSessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(activeSessionsProvider);
    ref.invalidate(pendingSessionsProvider);
    ref.invalidate(closedSessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingSessionsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final activeCount =
        ref.watch(activeSessionsProvider).valueOrNull?.length ?? 0;
    final historyCount =
        ref.watch(closedSessionsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Sessions de caisse',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('En cours'),
                  const SizedBox(width: 6),
                  _TabCount(count: activeCount, style: _TabCountStyle.blue),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('À traiter'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    _TabCount(
                        count: pendingCount, style: _TabCountStyle.orange),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Historique'),
                  const SizedBox(width: 6),
                  _TabCount(count: historyCount, style: _TabCountStyle.grey),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActiveSessionsTab(),
          _PendingSessionsTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ── Tab count badge ───────────────────────────────────────────────────────────

enum _TabCountStyle { blue, orange, grey }

class _TabCount extends StatelessWidget {
  final int count;
  final _TabCountStyle style;

  const _TabCount({required this.count, required this.style});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      _TabCountStyle.blue => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      _TabCountStyle.orange =>
        (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      _TabCountStyle.grey => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Tab 1 : En cours ──────────────────────────────────────────────────────────

class _ActiveSessionsTab extends ConsumerWidget {
  const _ActiveSessionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(activeSessionsProvider),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.point_of_sale_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune caisse ouverte',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les sessions actives apparaîtront ici.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PosScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ouvrir une caisse'),
                  ),
                ],
              ),
            ),
          );
        }

        final fcfa = NumberFormat.currency(
            locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeSessionsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final s = sessions[i] as Map<String, dynamic>;
              return _ActiveSessionCard(session: s, fcfa: fcfa);
            },
          ),
        );
      },
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final NumberFormat fcfa;

  const _ActiveSessionCard(
      {required this.session, required this.fcfa});

  @override
  Widget build(BuildContext context) {
    final deviceId = session['deviceId'] as String? ?? 'Terminal';
    final openedAt = session['openedAt'] != null
        ? DateTime.tryParse(session['openedAt'] as String)
        : null;
    final openingBalance =
        double.tryParse(session['openingBalance']?.toString() ?? '') ?? 0;
    final saleCount =
        (session['saleCount'] as num? ?? session['orderCount'] as num?)
            ?.toInt();
    final revenue = (session['totalRevenue'] as num?)?.toDouble();

    final initials = deviceId.length >= 2
        ? deviceId.substring(0, 2).toUpperCase()
        : deviceId.toUpperCase();

    String elapsed = '';
    if (openedAt != null) {
      final diff = DateTime.now().difference(openedAt);
      if (diff.inHours > 0) {
        elapsed = '${diff.inHours}h${diff.inMinutes.remainder(60).toString().padLeft(2, '0')} en cours';
      } else {
        elapsed = '${diff.inMinutes} min en cours';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFF1A73E8),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceId,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (openedAt != null)
                      Text(
                        'Ouvert à ${DateFormat('HH:mm').format(openedAt.toLocal())}${elapsed.isNotEmpty ? ' · $elapsed' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _StatusDot(color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text(
                      'En cours',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166634)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── KPI chips ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _KpiChip(
                  value: saleCount != null ? '$saleCount' : '—',
                  label: 'Ventes',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiChip(
                  value: revenue != null
                      ? NumberFormat.compact(locale: 'fr_FR').format(revenue)
                      : '—',
                  label: 'CA (FCFA)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiChip(
                  value: NumberFormat.compact(locale: 'fr_FR')
                      .format(openingBalance),
                  label: 'Fond initial',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Actions ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showSessionDetail(
                      context, session['id'] as String),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Voir le détail',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showCashMovementDialog(
                    context, session['id'] as String),
                icon: const Icon(Icons.swap_vert_rounded, size: 16),
                label: const Text('Mouvement',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String value;
  final String label;

  const _KpiChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Tab 2 : À traiter ─────────────────────────────────────────────────────────

class _PendingSessionsTab extends ConsumerWidget {
  const _PendingSessionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final sessionsAsync = ref.watch(pendingSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(pendingSessionsProvider),
      ),
      data: (sessions) {
        final visible = sessions.where((s) {
          final status = s['status'] as String? ?? '';
          if (role == 'manager') return status == 'PENDING_MANAGER';
          return status == 'PENDING_MANAGER' || status == 'PENDING_OWNER';
        }).toList();

        if (visible.isEmpty) {
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
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline,
                        size: 32, color: Colors.green.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tout est à jour',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role == 'manager'
                        ? 'Aucune session en attente de votre validation.'
                        : 'Aucune session en attente de votre signature.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingSessionsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Sessions clôturées — en attente de validation'
                    .toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              ...visible.map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ValidateSessionCard(
                      session: session,
                      role: role,
                      onTap: () async {
                        final id = session['id'] as String;
                        final status = session['status'] as String? ?? '';
                        final Widget screen;
                        if (status == 'PENDING_OWNER') {
                          screen = SessionSignScreen(sessionId: id);
                        } else {
                          screen = SessionValidateScreen(sessionId: id);
                        }
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => screen),
                        );
                        if (result == true) {
                          ref.invalidate(pendingSessionsProvider);
                        }
                      },
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _ValidateSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final String role;
  final VoidCallback onTap;

  const _ValidateSessionCard({
    required this.session,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fcfa = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    final status = session['status'] as String? ?? '';
    final openedAtStr = session['opened_at'] as String?;
    final closedAtStr = session['closed_at'] as String?;
    final closedAt =
        closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;
    final openedAt =
        openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final variance = session['variance'] != null
        ? double.tryParse(session['variance'].toString())
        : null;
    final totalRevenue = session['totalRevenue'] != null
        ? double.tryParse(session['totalRevenue'].toString())
        : null;
    final openingBalance = session['opening_balance'] != null
        ? double.tryParse(session['opening_balance'].toString())
        : session['openingBalance'] != null
            ? double.tryParse(session['openingBalance'].toString())
            : null;
    final saleCount = (session['saleCount'] as num?)?.toInt();
    final isPendingManager = status == 'PENDING_MANAGER';

    final deviceId = session['deviceId'] as String? ??
        session['device_id'] as String? ??
        'Terminal';
    final initials = deviceId.length >= 2
        ? deviceId.substring(0, 2).toUpperCase()
        : deviceId.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendingManager
              ? const Color(0xFFFDE68A)
              : AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFF64748B),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceId,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (closedAt != null)
                          'Clôturée ${DateFormat('HH:mm', 'fr_FR').format(closedAt)}',
                        if (openedAt != null)
                          'ouvert ${DateFormat('HH:mm').format(openedAt)}',
                        if (saleCount != null) '$saleCount ventes',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPendingManager
                      ? const Color(0xFFFEF3C7)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPendingManager ? 'À valider' : 'À signer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPendingManager
                        ? const Color(0xFF92400E)
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Amounts ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _AmountColumn(
                  label: 'CA déclaré',
                  value:
                      totalRevenue != null ? fcfa.format(totalRevenue) : '—',
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Fond initial',
                  value: openingBalance != null
                      ? fcfa.format(openingBalance)
                      : '—',
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Écart',
                  value: variance != null
                      ? '${variance > 0 ? '+' : ''}${fcfa.format(variance)}'
                      : '—',
                  valueColor: variance == null
                      ? null
                      : variance == 0
                          ? Colors.green.shade700
                          : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Actions ───────────────────────────────────────────────
          Row(
            children: [
              OutlinedButton(
                onPressed: () => showSessionDetail(
                    context, session['id'] as String),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                child: const Text('Voir le détail',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isPendingManager
                        ? const Color(0xFF1A73E8)
                        : AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    isPendingManager ? 'Valider la session' : 'Signer',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _AmountColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// ── Tab 3 : Historique ────────────────────────────────────────────────────────

enum _HistoryPeriod { today, week, month, custom }

extension _HistoryPeriodExt on _HistoryPeriod {
  String get label => switch (this) {
        _HistoryPeriod.today => "Aujourd'hui",
        _HistoryPeriod.week => 'Cette semaine',
        _HistoryPeriod.month => 'Ce mois',
        _HistoryPeriod.custom => 'Personnalisé',
      };

  DateTimeRange toRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _HistoryPeriod.today => DateTimeRange(start: today, end: today),
      _HistoryPeriod.week => DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
      _HistoryPeriod.month => DateTimeRange(
          start: today.subtract(const Duration(days: 29)), end: today),
      _HistoryPeriod.custom => DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
    };
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab();

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  _HistoryPeriod _period = _HistoryPeriod.week;

  @override
  void initState() {
    super.initState();
    // Sync provider to the initial period so the query matches the UI state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(closedSessionsDateRangeProvider.notifier).state =
            _HistoryPeriod.week.toRange();
      }
    });
  }

  void _selectPeriod(_HistoryPeriod p) async {
    if (p == _HistoryPeriod.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: ref.read(closedSessionsDateRangeProvider),
      );
      if (picked != null && mounted) {
        setState(() => _period = p);
        ref.read(closedSessionsDateRangeProvider.notifier).state = picked;
      }
    } else {
      setState(() => _period = p);
      ref.read(closedSessionsDateRangeProvider.notifier).state = p.toRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(closedSessionsProvider);
    final fcfa = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Column(
      children: [
        // ── Period selector ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: _HistoryPeriod.values.map((p) {
                  final selected = _period == p;
                  return GestureDetector(
                    onTap: () => _selectPeriod(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF1A73E8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(closedSessionsProvider),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'Aucune session sur cette période',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Compute summary
              double totalRevenue = 0;
              int totalSales = 0;
              for (final s in sessions) {
                final m = s as Map<String, dynamic>;
                totalRevenue +=
                    double.tryParse(m['totalRevenue']?.toString() ?? '') ?? 0;
                totalSales +=
                    (m['saleCount'] as num? ?? m['orderCount'] as num?)
                            ?.toInt() ??
                        0;
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(closedSessionsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _HistorySummaryRow(
                        totalSessions: sessions.length,
                        totalSales: totalSales,
                        totalRevenue: totalRevenue,
                        fcfa: fcfa,
                      );
                    }
                    return _HistorySessionRow(
                      session: sessions[i - 1] as Map<String, dynamic>,
                      fcfa: fcfa,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistorySummaryRow extends StatelessWidget {
  final int totalSessions;
  final int totalSales;
  final double totalRevenue;
  final NumberFormat fcfa;

  const _HistorySummaryRow({
    required this.totalSessions,
    required this.totalSales,
    required this.totalRevenue,
    required this.fcfa,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryKpiCard(
                label: 'Sessions', value: '$totalSessions'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                _SummaryKpiCard(label: 'Ventes', value: '$totalSales'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryKpiCard(
              label: 'CA Total',
              value: NumberFormat.compact(locale: 'fr_FR')
                  .format(totalRevenue),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryKpiCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryKpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _HistorySessionRow extends StatelessWidget {
  final Map<String, dynamic> session;
  final NumberFormat fcfa;

  const _HistorySessionRow({required this.session, required this.fcfa});

  @override
  Widget build(BuildContext context) {
    final openedAtStr =
        session['opened_at'] as String? ?? session['openedAt'] as String?;
    final closedAtStr =
        session['closed_at'] as String? ?? session['closedAt'] as String?;
    final openedAt =
        openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final closedAt =
        closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;
    final totalRevenue =
        double.tryParse(session['totalRevenue']?.toString() ?? '') ?? 0;
    final saleCount =
        (session['saleCount'] as num? ?? session['orderCount'] as num?)
            ?.toInt();
    final status = session['status'] as String? ?? '';
    final deviceId = session['deviceId'] as String? ?? 'Terminal';

    final initials = deviceId.length >= 2
        ? deviceId.substring(0, 2).toUpperCase()
        : deviceId.toUpperCase();

    final (statusColor, statusLabel) = switch (status) {
      'CLOSED' => (const Color(0xFF166634), 'Signée'),
      'PENDING_OWNER' => (const Color(0xFF1E40AF), 'Validée'),
      'PENDING_MANAGER' => (const Color(0xFFD97706), 'À valider'),
      _ => (const Color(0xFF475569), 'Clôturée'),
    };
    final statusBg = switch (status) {
      'CLOSED' => const Color(0xFFDCFCE7),
      'PENDING_OWNER' => const Color(0xFFDBEAFE),
      'PENDING_MANAGER' => const Color(0xFFFEF3C7),
      _ => const Color(0xFFF1F5F9),
    };

    return GestureDetector(
      onTap: () => showSessionDetail(context, session['id'] as String),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Cashier avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1A73E8),
            child: Text(
              initials,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceId,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (openedAt != null)
                  Text(
                    '${DateFormat('d MMM', 'fr_FR').format(openedAt)} '
                    '${DateFormat('HH:mm').format(openedAt)}'
                    '${closedAt != null ? ' → ${DateFormat('HH:mm').format(closedAt)}' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),

          // Sales count
          if (saleCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$saleCount',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
              ),
            ),

          // Revenue
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              fcfa.format(totalRevenue),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
          ),

          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Session detail — top-level helper callable from any widget ────────────────

void showSessionDetail(BuildContext context, String sessionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SessionDetailSheet(sessionId: sessionId),
  );
}

void _showCashMovementDialog(BuildContext context, String sessionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CashMovementSheet(sessionId: sessionId),
  );
}

class _CashMovementSheet extends ConsumerStatefulWidget {
  final String sessionId;
  const _CashMovementSheet({required this.sessionId});

  @override
  ConsumerState<_CashMovementSheet> createState() => _CashMovementSheetState();
}

class _CashMovementSheetState extends ConsumerState<_CashMovementSheet> {
  String _type = 'IN';
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
        _amountController.text.replaceAll(' ', '').replaceAll(',', '.'));
    final reason = _reasonController.text.trim();
    if (amount == null || amount <= 0 || reason.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}/retail/sessions/${widget.sessionId}/movements'),
            headers: {
              'Content-Type': 'application/json',
              'x-tenant-id': tenantId,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'type': _type,
              'amount': amount,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.invalidate(activeSessionsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_type == 'IN'
              ? 'Entrée caisse enregistrée.'
              : 'Sortie caisse enregistrée.'),
          backgroundColor: _type == 'IN'
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIn = _type == 'IN';
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Mouvement de caisse',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // IN / OUT toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'IN'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'IN'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _type == 'IN'
                            ? const Color(0xFF166634)
                            : const Color(0xFFE2E8F0),
                        width: _type == 'IN' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward_rounded,
                            size: 18,
                            color: _type == 'IN'
                                ? const Color(0xFF166634)
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Entrée',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _type == 'IN'
                                    ? const Color(0xFF166634)
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'OUT'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'OUT'
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _type == 'OUT'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE2E8F0),
                        width: _type == 'OUT' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded,
                            size: 18,
                            color: _type == 'OUT'
                                ? const Color(0xFFDC2626)
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Sortie',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _type == 'OUT'
                                    ? const Color(0xFFDC2626)
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: 12),

            // Reason
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: isIn
                    ? 'Motif (ex: apport monnaie, avance reçue…)'
                    : 'Motif (ex: remise coffre, achat urgence…)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: isIn
                      ? const Color(0xFF166634)
                      : const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isIn
                            ? 'Enregistrer l\'entrée'
                            : 'Enregistrer la sortie',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetailSheet extends ConsumerWidget {
  final String sessionId;
  const _SessionDetailSheet({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionDetailProvider(sessionId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(sessionDetailProvider(sessionId)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _buildBody(context, ctrl, data),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ScrollController ctrl,
      Map<String, dynamic> data) {
    final session = data['session'] as Map<String, dynamic>? ?? {};
    final totalsByMethod =
        (data['totalsByMethod'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
    final totalSales = (data['totalSales'] as num?)?.toDouble() ?? 0;
    final grossSales = data['grossSales'] as Map<String, dynamic>?;
    final saleCount = (grossSales?['count'] as num?)?.toInt() ?? 0;
    final closingBalance = (data['closingBalance'] as num?)?.toDouble();
    final openingBalance = (data['openingBalance'] as num?)?.toDouble() ?? 0;
    final variance = (data['variance'] as num?)?.toDouble();
    final varianceExplanation = data['varianceExplanation'] as String?;
    final managerValidatedAt = data['managerValidatedAt'] as String?;
    final ownerSignedAt = data['ownerSignedAt'] as String?;
    final cashMovements =
        (data['cashMovements'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final movementSummary =
        data['cashMovementsSummary'] as Map<String, dynamic>?;
    final movementsIn =
        (movementSummary?['in'] as num?)?.toDouble() ?? 0;
    final movementsOut =
        (movementSummary?['out'] as num?)?.toDouble() ?? 0;
    final transactions =
        (data['transactions'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final status = session['status'] as String? ?? '';
    final deviceId = session['deviceId'] as String? ?? 'Terminal';
    final openedAtStr =
        session['openedAt'] as String? ?? session['opened_at'] as String?;
    final closedAtStr =
        session['closedAt'] as String? ?? session['closed_at'] as String?;
    final openedAt =
        openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final closedAt =
        closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;

    final fcfa = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    final (statusColor, statusLabel) = switch (status) {
      'CLOSED' => (const Color(0xFF166634), 'Signée'),
      'PENDING_OWNER' => (const Color(0xFF1E40AF), 'Validée'),
      'PENDING_MANAGER' => (const Color(0xFFD97706), 'À valider'),
      'OPEN' => (const Color(0xFF166634), 'En cours'),
      _ => (const Color(0xFF475569), 'Clôturée'),
    };
    final statusBg = switch (status) {
      'CLOSED' => const Color(0xFFDCFCE7),
      'PENDING_OWNER' => const Color(0xFFDBEAFE),
      'PENDING_MANAGER' => const Color(0xFFFEF3C7),
      'OPEN' => const Color(0xFFDCFCE7),
      _ => const Color(0xFFF1F5F9),
    };

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceId,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    if (openedAt != null)
                      Text(
                        DateFormat("d MMMM yyyy 'à' HH:mm", 'fr_FR')
                            .format(openedAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Scrollable content
        Expanded(
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // KPI strip
              Row(
                children: [
                  _DetailKpi(label: 'Ventes', value: '$saleCount'),
                  const SizedBox(width: 10),
                  _DetailKpi(
                      label: 'CA total',
                      value: NumberFormat.compact(locale: 'fr_FR')
                          .format(totalSales)),
                  const SizedBox(width: 10),
                  _DetailKpi(
                      label: 'Fond initial',
                      value: NumberFormat.compact(locale: 'fr_FR')
                          .format(openingBalance)),
                ],
              ),
              const SizedBox(height: 16),

              // Horaires
              if (openedAt != null) ...[
                const _DetailSection(label: 'Horaires'),
                _DetailCard(children: [
                  Row(children: [
                    Expanded(
                        child: _DetailCell(
                            label: 'Ouverture',
                            value: DateFormat('HH:mm').format(openedAt))),
                    if (closedAt != null) ...[
                      Expanded(
                          child: _DetailCell(
                              label: 'Fermeture',
                              value: DateFormat('HH:mm').format(closedAt))),
                      Expanded(
                          child: _DetailCell(
                              label: 'Durée',
                              value: _fmtDuration(
                                  closedAt.difference(openedAt)))),
                    ],
                  ]),
                ]),
                const SizedBox(height: 14),
              ],

              // Ventes par méthode
              if (totalsByMethod.values.any((v) => v > 0)) ...[
                const _DetailSection(label: 'Ventes par méthode'),
                _DetailCard(children: [
                  ...totalsByMethod.entries
                      .where((e) => e.value > 0)
                      .map((e) => _DetailRow(
                          label: paymentMethodLabel(e.key),
                          value: fcfa.format(e.value))),
                  const Divider(height: 16),
                  _DetailRow(
                      label: 'Total système',
                      value: fcfa.format(totalSales),
                      bold: true),
                ]),
                const SizedBox(height: 14),
              ],

              // Mouvements de caisse (paid-in / paid-out)
              if (cashMovements.isNotEmpty) ...[
                const _DetailSection(label: 'Mouvements de caisse'),
                _DetailCard(children: [
                  ...cashMovements.map((m) {
                    final isIn = m['type'] == 'IN';
                    final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                    final reason = m['reason'] as String? ?? '';
                    final at = m['createdAt'] != null
                        ? DateTime.tryParse(m['createdAt'] as String)
                        : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isIn
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIn
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: isIn
                                ? const Color(0xFF166634)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reason,
                                  style: const TextStyle(fontSize: 13)),
                              if (at != null)
                                Text(
                                  DateFormat('HH:mm', 'fr_FR').format(at),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIn ? '+' : '-'}${fcfa.format(amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isIn
                                ? const Color(0xFF166634)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ]),
                    );
                  }),
                  const Divider(height: 16),
                  Row(children: [
                    const Expanded(
                        child: Text('Net mouvements',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold))),
                    Text(
                      '${(movementsIn - movementsOut) >= 0 ? '+' : ''}${fcfa.format(movementsIn - movementsOut)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ]),
                const SizedBox(height: 14),
              ],

              // Arrêt de caisse
              if (closingBalance != null) ...[
                const _DetailSection(label: 'Arrêt de caisse'),
                _DetailCard(children: [
                  _DetailRow(
                      label: 'Fond initial',
                      value: fcfa.format(openingBalance)),
                  _DetailRow(
                      label: 'Espèces encaissées',
                      value: fcfa.format(totalsByMethod['CASH'] ?? 0)),
                  if (movementsIn > 0)
                    _DetailRow(
                        label: 'Entrées caisse',
                        value: '+${fcfa.format(movementsIn)}'),
                  if (movementsOut > 0)
                    _DetailRow(
                        label: 'Sorties caisse',
                        value: '-${fcfa.format(movementsOut)}'),
                  _DetailRow(
                      label: 'Théorique espèces',
                      value: fcfa.format(openingBalance +
                          (totalsByMethod['CASH'] ?? 0) +
                          movementsIn -
                          movementsOut)),
                  const Divider(height: 16),
                  _DetailRow(
                      label: 'Compté par le caissier',
                      value: fcfa.format(closingBalance),
                      bold: true),
                ]),
                const SizedBox(height: 10),
                if (variance != null)
                  _VarianceBanner(
                      variance: variance,
                      explanation: varianceExplanation),
                const SizedBox(height: 14),
              ],

              // Liste des ventes
              if (transactions.isNotEmpty) ...[
                _DetailSection(
                    label: 'Ventes (${transactions.length})'),
                _DetailCard(children: [
                  ...transactions.take(10).map((tx) {
                    final amount =
                        (tx['totalAmount'] as num?)?.toDouble() ?? 0;
                    final method = tx['paymentMethod'] as String?;
                    final at = tx['createdAt'] != null
                        ? DateTime.tryParse(tx['createdAt'] as String)
                        : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            at != null
                                ? DateFormat('HH:mm', 'fr_FR').format(at)
                                : '—',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                        if (method != null)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              paymentMethodLabel(method),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        Text(
                          fcfa.format(amount),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    );
                  }),
                  if (transactions.length > 10) ...[
                    const Divider(height: 14),
                    Text(
                      '+ ${transactions.length - 10} autres ventes',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
              ],

              // Workflow
              if (managerValidatedAt != null || ownerSignedAt != null) ...[
                const _DetailSection(label: 'Validation'),
                _DetailCard(children: [
                  if (managerValidatedAt != null)
                    _AuditRow(
                      icon: Icons.verified_outlined,
                      color: const Color(0xFF1A73E8),
                      label: 'Validé par le gestionnaire',
                      date: DateTime.tryParse(managerValidatedAt),
                    ),
                  if (managerValidatedAt != null && ownerSignedAt != null)
                    const SizedBox(height: 8),
                  if (ownerSignedAt != null)
                    _AuditRow(
                      icon: Icons.draw_outlined,
                      color: const Color(0xFF166634),
                      label: 'Signé par la propriétaire',
                      date: DateTime.tryParse(ownerSignedAt),
                    ),
                ]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${m}min';
  }
}

class _DetailKpi extends StatelessWidget {
  final String label;
  final String value;
  const _DetailKpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      );
}

class _DetailSection extends StatelessWidget {
  final String label;
  const _DetailSection({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5)),
      );
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  const _DetailCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DetailRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: bold ? null : AppColors.textSecondary,
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.normal))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w600)),
        ]),
      );
}

class _VarianceBanner extends StatelessWidget {
  final double variance;
  final String? explanation;
  const _VarianceBanner({required this.variance, this.explanation});

  @override
  Widget build(BuildContext context) {
    final fcfa = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final isOk = variance == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isOk
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isOk
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              size: 18,
              color: isOk
                  ? const Color(0xFF166634)
                  : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    isOk ? 'Caisse équilibrée' : 'Écart détecté',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOk
                            ? const Color(0xFF166634)
                            : const Color(0xFFDC2626)))),
            Text(
              isOk
                  ? '0 FCFA'
                  : '${variance > 0 ? '+' : ''}${fcfa.format(variance)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOk
                      ? const Color(0xFF166634)
                      : const Color(0xFFDC2626)),
            ),
          ]),
          if (!isOk &&
              explanation != null &&
              explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$explanation"',
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final DateTime? date;
  const _AuditRow(
      {required this.icon,
      required this.color,
      required this.label,
      this.date});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text(label, style: const TextStyle(fontSize: 13))),
        if (date != null)
          Text(
            DateFormat("d MMM HH:mm", 'fr_FR').format(date!),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
      ]);
}

// ── Shared error view ─────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
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
