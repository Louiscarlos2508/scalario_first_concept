import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';
import '../../data/models/tenant_summary.dart';
import 'new_tenant_form.dart';
import 'tenant_detail_screen.dart';

class AdminTenantsScreen extends ConsumerStatefulWidget {
  const AdminTenantsScreen({super.key});

  @override
  ConsumerState<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}

class _AdminTenantsScreenState extends ConsumerState<AdminTenantsScreen> {
  String? _billingFilter; // null = all, 'overdue', 'suspended'

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(adminTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String?>(
              value: _billingFilter,
              underline: const SizedBox.shrink(),
              hint: const Text('Tous'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'overdue', child: Text('En retard')),
                DropdownMenuItem(
                    value: 'suspended', child: Text('Suspendus')),
              ],
              onChanged: (v) => setState(() => _billingFilter = v),
            ),
          ),
        ],
      ),
      body: tenantsAsync.when(
        data: (allTenants) {
          final tenants = _billingFilter == null
              ? allTenants
              : allTenants
                  .where((t) => t.billingStatus == _billingFilter)
                  .toList();
          return tenants.isEmpty
              ? const Center(child: Text('Aucun tenant trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tenants.length,
                  itemBuilder: (context, index) =>
                      _TenantCard(tenant: tenants[index]),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(
          children: [
            MaterialBanner(
              content: const Text('Connexion requise pour l\'administration'),
              actions: [
                TextButton(
                  onPressed: () => ref.invalidate(adminTenantsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
            Expanded(
              child: Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewTenantForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau client'),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantSummary tenant;

  const _TenantCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TenantDetailScreen(tenant: tenant)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tenant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: tenant.status),
                  const SizedBox(width: 6),
                  _BillingStatusChip(status: tenant.billingStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${tenant.membersCount} membres • plan: ${tenant.plan}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tenant.activeModules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: tenant.activeModules
                      .map((mod) => Chip(
                            label: Text(mod, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (const Color(0xFF4CAF50), 'Actif'),
      'suspended' => (const Color(0xFFFF9800), 'Suspendu'),
      _ => (const Color(0xFF9E9E9E), 'Archivé'),
    };

    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      side: BorderSide(color: color, width: 1),
    );
  }
}

class _BillingStatusChip extends StatelessWidget {
  final String status;

  const _BillingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'trial' => (Colors.blue.shade300, 'Essai'),
      'active' => (const Color(0xFF4CAF50), 'Actif'),
      'overdue' => (const Color(0xFFFF9800), 'En retard'),
      'suspended' => (const Color(0xFFF44336), 'Suspendu'),
      _ => (const Color(0xFF9E9E9E), status),
    };

    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      side: BorderSide(color: color, width: 1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
