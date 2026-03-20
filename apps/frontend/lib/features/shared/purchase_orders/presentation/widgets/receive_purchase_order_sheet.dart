import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';

// ─── Line state ──────────────────────────────────────────────────────────────

class _LineState {
  final PurchaseOrderLineLocal line;
  final TextEditingController qtyCtrl;
  final TextEditingController notesCtrl;
  String? selectedVariantId;
  final List<TextEditingController> serialControllers = [];
  DateTime? expiryDate;
  DateTime? bestBeforeDate;

  _LineState(this.line)
      : qtyCtrl =
            TextEditingController(text: line.expectedQuantity.toString()),
        notesCtrl =
            TextEditingController(text: line.qualityNotes ?? ''),
        selectedVariantId = line.variantId {
    // Pre-fill expiry date from product's expiryDays
    if (line.expiryDays != null) {
      expiryDate =
          DateTime.now().add(Duration(days: line.expiryDays!));
    }
    // Pre-fill serial controllers based on expected quantity
    if (line.trackSerialNumbers) {
      _syncSerials(line.expectedQuantity.round().clamp(0, 200));
    }
  }

  /// Call after qty field changes to adjust serial controller count.
  void onQtyChanged() {
    if (!line.trackSerialNumbers) return;
    _syncSerials(receivedQty.round().clamp(0, 200));
  }

  void _syncSerials(int count) {
    while (serialControllers.length > count) {
      serialControllers.removeLast().dispose();
    }
    while (serialControllers.length < count) {
      serialControllers.add(TextEditingController());
    }
  }

  double get receivedQty => double.tryParse(qtyCtrl.text) ?? 0.0;
  double get variance => receivedQty - line.expectedQuantity;

  bool get serialsComplete {
    if (!line.trackSerialNumbers) return true;
    final count = receivedQty.round();
    if (serialControllers.length != count) return false;
    return serialControllers.every((c) => c.text.trim().isNotEmpty);
  }

  List<String> get serialNumbers =>
      serialControllers.map((c) => c.text.trim()).toList();

  void dispose() {
    qtyCtrl.dispose();
    notesCtrl.dispose();
    for (final c in serialControllers) {
      c.dispose();
    }
  }
}

// ─── Sheet ───────────────────────────────────────────────────────────────────

class ReceivePurchaseOrderSheet extends ConsumerStatefulWidget {
  final PurchaseOrderLocal order;
  final VoidCallback? onSuccess;

  const ReceivePurchaseOrderSheet({
    super.key,
    required this.order,
    this.onSuccess,
  });

  @override
  ConsumerState<ReceivePurchaseOrderSheet> createState() =>
      _ReceivePurchaseOrderSheetState();
}

class _ReceivePurchaseOrderSheetState
    extends ConsumerState<ReceivePurchaseOrderSheet> {
  late final List<_LineState> _lineStates;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lineStates = widget.order.lines.map(_LineState.new).toList();
  }

  @override
  void dispose() {
    for (final s in _lineStates) {
      s.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting && _lineStates.every((s) => s.serialsComplete);

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final lines = _lineStates
        .map((s) => <String, dynamic>{
              'purchaseOrderLineId': s.line.id,
              'receivedQuantity': s.receivedQty,
              if (s.notesCtrl.text.trim().isNotEmpty)
                'qualityNotes': s.notesCtrl.text.trim(),
              if (s.selectedVariantId != null)
                'variantId': s.selectedVariantId!,
              if (s.serialNumbers.isNotEmpty)
                'serialNumbers': s.serialNumbers,
              if (s.expiryDate != null)
                'expiresAt': s.expiryDate!.toIso8601String(),
              if (s.bestBeforeDate != null)
                'bestBeforeDate': s.bestBeforeDate!.toIso8601String(),
            })
        .toList();

    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      await repo.receiveOrder(widget.order.id, lines, tenantId);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_reception_ok'),
            content: Text(
                'Réception enregistrée — ${lines.length} mouvement(s) de stock créé(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réceptionner la commande',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.order.supplierName != null)
                        Text(
                          widget.order.supplierName!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lines
            ..._lineStates.asMap().entries.map((entry) {
              final idx = entry.key;
              final state = entry.value;
              return _ReceptionLineCard(
                key: Key('reception_line_$idx'),
                state: state,
                onChanged: () => setState(() {}),
              );
            }),

            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('reception_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Valider la réception'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Per-line card ────────────────────────────────────────────────────────────

class _ReceptionLineCard extends StatelessWidget {
  final _LineState state;
  final VoidCallback onChanged;

  const _ReceptionLineCard(
      {super.key, required this.state, required this.onChanged});

  String _variantLabel(Map<String, dynamic> v) {
    final sku = v['sku'] as String?;
    if (sku != null && sku.isNotEmpty) return sku;
    final attrs = v['attributes'] as Map<String, dynamic>? ?? {};
    final label = attrs.values.join(' ');
    return label.isNotEmpty ? label : 'Variante';
  }

  @override
  Widget build(BuildContext context) {
    final variance = state.variance;
    final varianceColor = variance >= 0 ? AppColors.success : AppColors.warning;
    final varianceText = variance >= 0
        ? '+${variance.toStringAsFixed(variance.truncateToDouble() == variance ? 0 : 2)}'
        : variance
            .toStringAsFixed(variance.truncateToDouble() == variance ? 0 : 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              state.line.itemName ?? state.line.catalogItemId ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Attendu : ${state.line.expectedQuantity}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),

            // CONDITIONAL — variant dropdown
            if (state.line.hasVariants && state.line.variants.isNotEmpty) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Variante',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedVariantId,
                    isDense: true,
                    isExpanded: true,
                    items: state.line.variants
                        .map((v) => DropdownMenuItem<String>(
                              value: v['id'] as String,
                              child: Text(_variantLabel(v)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      state.selectedVariantId = val;
                      onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Quantity + variance
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: state.qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantité reçue',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      state.onQtyChanged();
                      onChanged();
                    },
                  ),
                ),
                if (variance != 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    varianceText,
                    key: Key('variance_${state.line.id}'),
                    style: TextStyle(
                      color: varianceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // CONDITIONAL — serial number fields
            if (state.line.trackSerialNumbers &&
                state.serialControllers.isNotEmpty) ...[
              const Text(
                'Numéros de série',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              ...state.serialControllers.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      key: Key('serial_${state.line.id}_${e.key}'),
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: 'N° série ${e.key + 1}',
                        hintText: 'ex. IMEI 123456789',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  )),
              const SizedBox(height: 4),
            ],

            // CONDITIONAL — expiry date picker (expiryDays != null)
            if (state.line.expiryDays != null) ...[
              _DatePickerTile(
                key: Key('expiry_${state.line.id}'),
                label: "Date d'expiration",
                date: state.expiryDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                required: true,
                onPicked: (d) {
                  state.expiryDate = d;
                  onChanged();
                },
              ),
              const SizedBox(height: 4),
              _DatePickerTile(
                key: Key('bestbefore_${state.line.id}'),
                label: 'Date de garde optimale (optionnel)',
                date: state.bestBeforeDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                required: false,
                onPicked: (d) {
                  state.bestBeforeDate = d;
                  onChanged();
                },
              ),
              const SizedBox(height: 4),
            ],

            // Notes quality
            TextField(
              controller: state.notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes qualité (optionnel)',
                hintText: 'ex. produits trop mûrs',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable date picker tile ────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool required;
  final ValueChanged<DateTime?> onPicked;

  const _DatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.required,
    required this.onPicked,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        date == null ? label : '${label.split(' (')[0]} : ${_fmt(date!)}',
        style: TextStyle(
          fontSize: 13,
          color: date == null
              ? (required ? AppColors.error : AppColors.textSecondary)
              : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null && !required)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () => onPicked(null),
            ),
          const Icon(Icons.calendar_today_outlined, size: 16),
        ],
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}
