import 'package:flutter/material.dart';
import '../../data/models/tenant_summary.dart';
import '../widgets/billing_tab.dart';
import '../widgets/tenant_modules_tab.dart';
import '../widgets/tenant_users_tab.dart';

class TenantDetailScreen extends StatelessWidget {
  final TenantSummary tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (tenant.status) {
      'active' => (const Color(0xFF4CAF50), 'Actif'),
      'suspended' => (const Color(0xFFFF9800), 'Suspendu'),
      _ => (const Color(0xFF9E9E9E), 'Archivé'),
    };

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tenant.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    label: Text(statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12)),
                    side: BorderSide(color: statusColor, width: 1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              Text(
                '${tenant.currency} • ${tenant.activeModules.length} modules actifs',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          toolbarHeight: 72,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Modules'),
              Tab(text: 'Users'),
              Tab(text: 'Facturation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfosTab(tenant: tenant),
            TenantModulesTab(tenantId: tenant.id),
            TenantUsersTab(tenantId: tenant.id),
            BillingTab(tenantId: tenant.id),
          ],
        ),
      ),
    );
  }
}

// ── Infos tab ─────────────────────────────────────────────────────────────────

class _InfosTab extends StatelessWidget {
  final TenantSummary tenant;

  const _InfosTab({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Nom', value: tenant.name),
        _InfoRow(label: 'Statut', value: tenant.status),
        _InfoRow(label: 'Devise', value: tenant.currency),
        _InfoRow(
            label: 'Membres',
            value: '${tenant.membersCount} membre(s)'),
        _InfoRow(
            label: 'Modules actifs',
            value: tenant.activeModules.isEmpty
                ? 'Aucun'
                : tenant.activeModules.join(', ')),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
