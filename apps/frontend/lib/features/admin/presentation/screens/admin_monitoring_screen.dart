import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/monitoring_health.dart';
import '../providers/admin_providers.dart';

class AdminMonitoringScreen extends ConsumerWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminMonitoringProvider);
    final billingAsync = ref.watch(billingSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring plateforme')),
      body: healthAsync.when(
        data: (health) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminMonitoringProvider);
            ref.invalidate(billingSummaryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Billing KPIs
              billingAsync.when(
                data: (billing) => _BillingKpiSection(billing: billing),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Text('KPI billing indisponible: $e',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              // Platform KPIs
              _KpiRow(health: health),
              const SizedBox(height: 16),
              ...health.tenants.map((t) => _TenantHealthTile(tenant: t)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

// ── Billing KPIs ──────────────────────────────────────────────────────────────

class _BillingKpiSection extends StatelessWidget {
  final Map<String, dynamic> billing;

  const _BillingKpiSection({required this.billing});

  String _fmt(num v) {
    if (v == 0) return '0';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyRevenue = (billing['monthlyRevenue'] as num?) ?? 0;
    final mrr = (billing['mrr'] as num?) ?? 0;
    final arr = (billing['arr'] as num?) ?? 0;
    final activeClients = (billing['activeClients'] as num?) ?? 0;
    final trialClients = (billing['trialClients'] as num?) ?? 0;
    final overdueClients = (billing['overdueClients'] as num?) ?? 0;
    final pendingInvoices = (billing['pendingInvoicesCount'] as num?) ?? 0;
    final totalUnpaid = (billing['totalUnpaid'] as num?) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Facturation',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _BillingKpiCard(
              label: 'Revenus du mois',
              value: '${_fmt(monthlyRevenue)} FCFA',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            _BillingKpiCard(
              label: 'MRR',
              value: '${_fmt(mrr)} FCFA',
              icon: Icons.repeat,
              color: Colors.blue,
            ),
            _BillingKpiCard(
              label: 'ARR',
              value: '${_fmt(arr)} FCFA',
              icon: Icons.calendar_today,
              color: Colors.indigo,
            ),
            _BillingKpiCard(
              label: 'Clients actifs',
              value: '$activeClients',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _BillingKpiCard(
              label: 'En essai',
              value: '$trialClients',
              icon: Icons.hourglass_top,
              color: Colors.blue,
            ),
            _BillingKpiCard(
              label: 'Impayés',
              value: '$overdueClients',
              icon: Icons.warning_amber,
              color: overdueClients > 0 ? Colors.red : Colors.grey,
              badge: overdueClients > 0,
            ),
            _BillingKpiCard(
              label: 'Factures en attente',
              value: '$pendingInvoices',
              icon: Icons.description_outlined,
              color: pendingInvoices > 0 ? Colors.orange : Colors.grey,
            ),
            _BillingKpiCard(
              label: 'Total impayé',
              value: '${_fmt(totalUnpaid)} FCFA',
              icon: Icons.money_off,
              color: totalUnpaid > 0 ? Colors.orange : Colors.grey,
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }
}

class _BillingKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool badge;

  const _BillingKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  if (badge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Cards ─────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final MonitoringHealth health;

  const _KpiRow({required this.health});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Tenants actifs',
            value: '${health.activeTenants}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'Utilisateurs totaux',
            value: '${health.totalUsers}',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tenant health tile ────────────────────────────────────────────────────────

class _TenantHealthTile extends StatelessWidget {
  final TenantHealthStatus tenant;

  const _TenantHealthTile({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final hasAlert = tenant.failedMutationsCount > 10;

    return ListTile(
      leading: _StatusBadge(status: tenant.status),
      title: Text(tenant.name),
      subtitle: Text(
        '${tenant.membersCount} membre(s) • Dernière activité : ${_relativeTime(tenant.lastActivityAt)}',
      ),
      trailing: hasAlert
          ? _AlertBadge(count: tenant.failedMutationsCount)
          : const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
      onTap: hasAlert
          ? () => _showAlertDialog(context, tenant)
          : null,
    );
  }

  void _showAlertDialog(BuildContext context, TenantHealthStatus tenant) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Alertes sync — ${tenant.name}'),
        content: Text(
            '${tenant.failedMutationsCount} mutations en échec en attente de traitement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'Jamais';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 30) return 'il y a ${diff.inDays}j';
    return 'il y a ${(diff.inDays / 30).floor()}mois';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => const Color(0xFF4CAF50),
      'suspended' => const Color(0xFFFF9800),
      _ => const Color(0xFF9E9E9E),
    };

    return CircleAvatar(
      radius: 10,
      backgroundColor: color,
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final int count;

  const _AlertBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber, color: Colors.orange),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
