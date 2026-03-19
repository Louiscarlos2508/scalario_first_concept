import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/tenant_module_status.dart';
import '../../data/models/tenant_summary.dart';
import '../../data/services/admin_api_service.dart';
import '../providers/admin_providers.dart';

class AdminModulesScreen extends ConsumerStatefulWidget {
  const AdminModulesScreen({super.key});

  @override
  ConsumerState<AdminModulesScreen> createState() => _AdminModulesScreenState();
}

class _AdminModulesScreenState extends ConsumerState<AdminModulesScreen> {
  String? _selectedTenantId;

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(adminTenantsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: tenantsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
              data: (tenants) => _TenantDropdown(
                tenants: tenants,
                selectedId: _selectedTenantId,
                onChanged: (v) => setState(() => _selectedTenantId = v),
              ),
            ),
          ),
          Expanded(
            child: _selectedTenantId == null
                ? const Center(
                    key: Key('modules_select_hint'),
                    child: Text('Sélectionnez un tenant pour voir ses modules'),
                  )
                : _GroupedModuleList(tenantId: _selectedTenantId!),
          ),
        ],
      ),
    );
  }
}

// ── Tenant dropdown ───────────────────────────────────────────────────────────

class _TenantDropdown extends StatelessWidget {
  final List<TenantSummary> tenants;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _TenantDropdown({
    required this.tenants,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const Key('modules_tenant_dropdown'),
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'Tenant',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      hint: const Text('Sélectionnez un tenant'),
      items: tenants
          .map(
            (t) => DropdownMenuItem(
              key: Key('tenant_option_${t.id}'),
              value: t.id,
              child: Text(t.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Grouped module list ───────────────────────────────────────────────────────

class _GroupedModuleList extends ConsumerStatefulWidget {
  final String tenantId;

  const _GroupedModuleList({required this.tenantId});

  @override
  ConsumerState<_GroupedModuleList> createState() => _GroupedModuleListState();
}

class _GroupedModuleListState extends ConsumerState<_GroupedModuleList> {
  final Set<String> _toggling = {};

  String get _token {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _activate(TenantModuleStatus module) async {
    setState(() => _toggling.add(module.moduleCode));
    try {
      await ref
          .read(adminApiServiceProvider)
          .activateModule(widget.tenantId, module.moduleCode, token: _token);
      ref.invalidate(tenantModulesProvider(widget.tenantId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_module_activated'),
            content: Text('${module.name} activé'),
          ),
        );
      }
    } on AdminApiException catch (e) {
      ref.invalidate(tenantModulesProvider(widget.tenantId));
      if (!mounted) return;
      final msg = "Activez d'abord : ${e.detail.join(', ')}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('snackbar_module_error'),
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling.remove(module.moduleCode));
    }
  }

  Future<void> _deactivate(TenantModuleStatus module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver le module ?'),
        content: Text(
          'Désactiver "${module.name}" peut affecter les tenants qui en dépendent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('confirm_deactivate'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Désactiver',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _toggling.add(module.moduleCode));
    try {
      await ref
          .read(adminApiServiceProvider)
          .deactivateModule(widget.tenantId, module.moduleCode, token: _token);
      ref.invalidate(tenantModulesProvider(widget.tenantId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_module_deactivated'),
            content: Text('${module.name} désactivé'),
          ),
        );
      }
    } on AdminApiException catch (e) {
      ref.invalidate(tenantModulesProvider(widget.tenantId));
      if (!mounted) return;
      final msg = "Désactivez d'abord : ${e.detail.join(', ')}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('snackbar_module_error'),
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling.remove(module.moduleCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(tenantModulesProvider(widget.tenantId));

    return modulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (modules) {
        final shared = modules.where((m) => m.type == 'shared').toList();
        final vertical = modules.where((m) => m.type != 'shared').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (shared.isNotEmpty) ...[
              _SectionHeader('Modules partagés'),
              ...shared.map(
                (m) => _ModuleTile(
                  key: Key('module_tile_${m.moduleCode}'),
                  module: m,
                  isToggling: _toggling.contains(m.moduleCode),
                  onToggle: (v) => v ? _activate(m) : _deactivate(m),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (vertical.isNotEmpty) ...[
              _SectionHeader('Modules verticaux'),
              ...vertical.map(
                (m) => _ModuleTile(
                  key: Key('module_tile_${m.moduleCode}'),
                  module: m,
                  isToggling: _toggling.contains(m.moduleCode),
                  onToggle: (v) => v ? _activate(m) : _deactivate(m),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Module tile ───────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final TenantModuleStatus module;
  final bool isToggling;
  final ValueChanged<bool> onToggle;

  const _ModuleTile({
    super.key,
    required this.module,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final depText = module.dependencies.isEmpty
        ? null
        : 'Dép: ${module.dependencies.join(', ')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          module.type == 'vertical' ? Icons.store : Icons.extension,
        ),
        title: Text(module.name),
        subtitle: depText != null ? Text(depText) : null,
        trailing: isToggling
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                key: Key('module_toggle_${module.moduleCode}'),
                value: module.isActive,
                onChanged: onToggle,
              ),
      ),
    );
  }
}
