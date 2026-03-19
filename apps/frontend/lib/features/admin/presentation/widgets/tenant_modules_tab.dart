import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/tenant_module_status.dart';
import '../../data/services/admin_api_service.dart';
import '../providers/admin_providers.dart';

class TenantModulesTab extends ConsumerStatefulWidget {
  final String tenantId;

  const TenantModulesTab({super.key, required this.tenantId});

  @override
  ConsumerState<TenantModulesTab> createState() => _TenantModulesTabState();
}

class _TenantModulesTabState extends ConsumerState<TenantModulesTab> {
  /// Tracks which module codes are currently being toggled.
  final Set<String> _toggling = {};

  String get _token {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _onToggle(TenantModuleStatus module, bool newValue) async {
    setState(() => _toggling.add(module.moduleCode));

    try {
      final service = ref.read(adminApiServiceProvider);
      if (newValue) {
        await service.activateModule(widget.tenantId, module.moduleCode,
            token: _token);
      } else {
        await service.deactivateModule(widget.tenantId, module.moduleCode,
            token: _token);
      }
      ref.invalidate(tenantModulesProvider(widget.tenantId));
    } on AdminApiException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'MISSING_DEPENDENCY'
          ? 'Activez d\'abord : ${e.detail.join(', ')}'
          : 'Désactivez d\'abord : ${e.detail.join(', ')}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      // Provider was never mutated → refresh gives back original state
      ref.invalidate(tenantModulesProvider(widget.tenantId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      ref.invalidate(tenantModulesProvider(widget.tenantId));
    } finally {
      if (mounted) setState(() => _toggling.remove(module.moduleCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(tenantModulesProvider(widget.tenantId));

    return modulesAsync.when(
      data: (modules) => ListView.builder(
        itemCount: modules.length,
        itemBuilder: (context, i) => _ModuleTile(
          module: modules[i],
          isToggling: _toggling.contains(modules[i].moduleCode),
          onToggle: (v) => _onToggle(modules[i], v),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final TenantModuleStatus module;
  final bool isToggling;
  final ValueChanged<bool> onToggle;

  const _ModuleTile({
    required this.module,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final depText = module.dependencies.isEmpty
        ? null
        : 'Dépend de : ${module.dependencies.join(', ')}';

    return ListTile(
      leading: Icon(
        module.type == 'vertical' ? Icons.store : Icons.extension,
      ),
      title: Text(module.name),
      subtitle: Text([
        module.type,
        depText,
      ].nonNulls.join(' • ')),
      trailing: isToggling
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: module.isActive,
              onChanged: onToggle,
            ),
    );
  }
}
