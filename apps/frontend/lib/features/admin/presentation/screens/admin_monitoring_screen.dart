import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/monitoring_health.dart';
import '../providers/admin_providers.dart';

class AdminMonitoringScreen extends ConsumerWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminMonitoringProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring plateforme')),
      body: healthAsync.when(
        data: (health) => RefreshIndicator(
          onRefresh: () async => ref.refresh(adminMonitoringProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
