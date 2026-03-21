import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/promotions/presentation/providers/promotions_providers.dart';

String _fcfa(double amount) => NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
).format(amount);

class CreatePromotionSheet extends ConsumerStatefulWidget {
  const CreatePromotionSheet({super.key});

  @override
  ConsumerState<CreatePromotionSheet> createState() =>
      _CreatePromotionSheetState();
}

class _CreatePromotionSheetState extends ConsumerState<CreatePromotionSheet> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'PERCENT';
  final String _scope = 'ITEM';
  String? _scopeId;
  String? _scopeLabel;

  // PERCENT fields
  final _percentCtrl = TextEditingController(text: '10');

  // BUY_N_GET_M fields
  final _buyNCtrl = TextEditingController(text: '3');
  final _getMCtrl = TextEditingController(text: '1');

  // CROSSED_PRICE fields
  final _newPriceCtrl = TextEditingController();
  double? _originalPrice;

  // Dates
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  bool _saving = false;

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _percentCtrl.dispose();
    _buyNCtrl.dispose();
    _getMCtrl.dispose();
    _newPriceCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Preview calculation ────────────────────────────────────────────────────

  String _preview() {
    if (_originalPrice == null) return '';
    final base = _originalPrice!;
    switch (_type) {
      case 'PERCENT':
        final pct = double.tryParse(_percentCtrl.text) ?? 0;
        final after = base * (1 - pct / 100);
        return '${_fcfa(base)} → ${_fcfa(after)} (-${pct.toInt()}%)';
      case 'CROSSED_PRICE':
        final np = double.tryParse(_newPriceCtrl.text) ?? base;
        return '${_fcfa(base)} → ${_fcfa(np)}';
      case 'BUY_N_GET_M':
        final n = int.tryParse(_buyNCtrl.text) ?? 3;
        final m = int.tryParse(_getMCtrl.text) ?? 1;
        return '$n achetés = $m offert(s) — prix unitaire : ${_fcfa(base)}';
      default:
        return '';
    }
  }

  // ── Article search ─────────────────────────────────────────────────────────

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final tenantId = ref.read(activeTenantProvider);
      if (tenantId == null) return;
      final results = await ref
          .read(catalogRepositoryProvider)
          .getProducts(tenantId: tenantId);
      setState(() {
        _searchResults = results
            .where(
              (p) => p['name'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .take(8)
            .toList();
      });
    } finally {
      setState(() => _searching = false);
    }
  }

  // ── Date pickers ───────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;

    Map<String, dynamic> value;
    switch (_type) {
      case 'PERCENT':
        value = {'percent': double.parse(_percentCtrl.text)};
        break;
      case 'BUY_N_GET_M':
        value = {
          'buyN': int.parse(_buyNCtrl.text),
          'getM': int.parse(_getMCtrl.text),
        };
        break;
      case 'CROSSED_PRICE':
        value = {'newPrice': double.parse(_newPriceCtrl.text)};
        break;
      default:
        value = {};
    }

    final dto = {
      'type': _type,
      'scope': _scope,
      if (_scopeId != null) 'scopeId': _scopeId,
      'value': value,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'conflictRule': 'BEST',
    };

    setState(() => _saving = true);
    try {
      await ref
          .read(promotionsRepositoryProvider)
          .createPromotion(tenantId, dto);
      ref.invalidate(promotionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvelle promotion',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Type dropdown
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type de promotion',
                ),
                items: const [
                  DropdownMenuItem(value: 'PERCENT', child: Text('Remise %')),
                  DropdownMenuItem(
                    value: 'BUY_N_GET_M',
                    child: Text('Offre quantitative (3+1)'),
                  ),
                  DropdownMenuItem(
                    value: 'CROSSED_PRICE',
                    child: Text('Prix barré'),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'PERCENT'),
              ),
              const SizedBox(height: 12),

              // Article search
              TextFormField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Rechercher un article',
                  suffixIcon: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _search,
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: _searchResults.map((p) {
                      return ListTile(
                        dense: true,
                        title: Text(p['name'] as String? ?? ''),
                        trailing: Text(
                          '${(p['price'] as num?)?.toStringAsFixed(0) ?? ''} FCFA',
                        ),
                        onTap: () {
                          setState(() {
                            _scopeId = p['id'] as String?;
                            _scopeLabel = p['name'] as String?;
                            _originalPrice = (p['price'] as num?)?.toDouble();
                            if (_type == 'CROSSED_PRICE' &&
                                _originalPrice != null) {
                              _newPriceCtrl.text = _originalPrice!
                                  .toStringAsFixed(0);
                            }
                            _searchResults = [];
                            _searchCtrl.text = _scopeLabel ?? '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              if (_scopeLabel != null)
                Chip(
                  label: Text(_scopeLabel!),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() {
                    _scopeId = null;
                    _scopeLabel = null;
                    _originalPrice = null;
                    _searchCtrl.clear();
                  }),
                ),
              const SizedBox(height: 12),

              // Dynamic fields
              if (_type == 'PERCENT') ...[
                TextFormField(
                  controller: _percentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pourcentage de remise (%)',
                  ),
                  validator: (v) => (double.tryParse(v ?? '') == null)
                      ? 'Valeur invalide'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (_type == 'BUY_N_GET_M') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyNCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Acheter N',
                        ),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null) ? 'Invalide' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _getMCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Offrir M',
                        ),
                        validator: (v) =>
                            (int.tryParse(v ?? '') == null) ? 'Invalide' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
              if (_type == 'CROSSED_PRICE') ...[
                TextFormField(
                  controller: _newPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau prix (FCFA)',
                  ),
                  validator: (v) => (double.tryParse(v ?? '') == null)
                      ? 'Valeur invalide'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 12),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        'Début : ${DateFormat('dd/MM/yy').format(_startDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(
                        'Fin : ${DateFormat('dd/MM/yy').format(_endDate)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Real-time preview
              if (preview.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preview,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Créer la promotion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
