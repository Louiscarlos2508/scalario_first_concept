import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/loss_locations_provider.dart';

/// Standalone reusable editor for tenant loss locations.
/// Shows existing chips + add field. Used in GeneralSettingsScreen
/// and kept in SettingsScreen via import.
class LossLocationsEditor extends ConsumerStatefulWidget {
  const LossLocationsEditor({super.key});

  @override
  ConsumerState<LossLocationsEditor> createState() =>
      _LossLocationsEditorState();
}

class _LossLocationsEditorState extends ConsumerState<LossLocationsEditor> {
  final _newLocCtrl = TextEditingController();
  bool _saving = false;

  static const _suggestedDefaults = [
    'Magasin',
    'Rayon',
    'Transit',
    'Stockroom'
  ];

  @override
  void dispose() {
    _newLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _patch(List<String> locations) async {
    setState(() => _saving = true);
    try {
      final tenantId = ref.read(activeTenantProvider);
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tenant/loss-locations'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
        body: jsonEncode({'locations': locations}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(lossLocationsProvider);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add(List<String> current) {
    final val = _newLocCtrl.text.trim();
    if (val.isEmpty || current.contains(val)) return;
    _newLocCtrl.clear();
    _patch([...current, val]);
  }

  void _remove(List<String> current, String loc) {
    _patch(current.where((l) => l != loc).toList());
  }

  @override
  Widget build(BuildContext context) {
    final locations =
        ref.watch(lossLocationsProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optionnel. Si configurés, le champ devient obligatoire lors d\'une déclaration de perte.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (locations.isEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _suggestedDefaults
                .map(
                  (d) => ActionChip(
                    label: Text(d),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed:
                        _saving ? null : () => _patch(_suggestedDefaults),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          const Text(
            'Appuyez sur une suggestion pour charger tous les défauts.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ] else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: locations
                .map(
                  (loc) => Chip(
                    label: Text(loc),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted:
                        _saving ? null : () => _remove(locations, loc),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newLocCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nouvel emplacement...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(locations),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _add(locations),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
