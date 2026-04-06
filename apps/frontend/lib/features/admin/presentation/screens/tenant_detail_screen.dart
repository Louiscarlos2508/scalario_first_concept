import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import '../../data/models/business_type_summary.dart';
import '../../data/models/tenant_summary.dart';
import '../providers/admin_providers.dart';
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
        appBar: ScalarioAppBar(
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  tenant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                label: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12)),
                side: BorderSide(color: statusColor, width: 1),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: const [
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

class _InfosTab extends ConsumerStatefulWidget {
  final TenantSummary tenant;

  const _InfosTab({required this.tenant});

  @override
  ConsumerState<_InfosTab> createState() => _InfosTabState();
}

class _InfosTabState extends ConsumerState<_InfosTab> {
  late String _businessType;

  @override
  void initState() {
    super.initState();
    _businessType = widget.tenant.businessType;
  }

  String _token() =>
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';

  Future<void> _openChangeBusinessTypeDialog(
      List<BusinessTypeSummary> types) async {
    // Only show types matching the tenant's vertical
    final filteredTypes =
        types.where((t) => t.vertical == widget.tenant.vertical).toList();
    String selected = _businessType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Changer le type de business'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Type de business',
                  border: OutlineInputBorder(),
                ),
                items: filteredTypes
                    .map((t) => DropdownMenuItem(
                          value: t.code,
                          child: Text(t.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selected = v ?? selected),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note : les catégories suggérées du nouveau type ne seront pas recréées automatiquement.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(adminApiServiceProvider).assignBusinessType(
            widget.tenant.id,
            selected,
            token: _token(),
          );
      setState(() => _businessType = selected);
      ref.invalidate(adminTenantsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Type de business mis à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(businessTypesProvider);

    final businessTypeName = typesAsync.maybeWhen(
      data: (types) {
        final match = types.where((t) => t.code == _businessType).toList();
        return match.isNotEmpty ? match.first.name : _businessType;
      },
      orElse: () => _businessType,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Nom', value: widget.tenant.name),
        _InfoRow(label: 'Statut', value: widget.tenant.status),
        _InfoRow(label: 'Devise', value: widget.tenant.currency),
        _InfoRow(label: 'Vertical', value: widget.tenant.vertical),
        _InfoRow(
            label: 'Membres',
            value: '${widget.tenant.membersCount} membre(s)'),
        _InfoRow(
            label: 'Modules actifs',
            value: widget.tenant.activeModules.isEmpty
                ? 'Aucun'
                : widget.tenant.activeModules.join(', ')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Text('Type métier',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Text(businessTypeName)),
              typesAsync.maybeWhen(
                data: (types) => TextButton(
                  onPressed: () => _openChangeBusinessTypeDialog(types),
                  child: const Text('Modifier'),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
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
