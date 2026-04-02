import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/widgets/client_order_line_form_widget.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ClientOrderFormScreen extends ConsumerStatefulWidget {
  final List<ClientOrderLineValue>? initialItems;
  final bool isEmbedded;
  final VoidCallback? onCreated;

  const ClientOrderFormScreen({
    super.key,
    this.initialItems,
    this.isEmbedded = false,
    this.onCreated,
  });

  @override
  ConsumerState<ClientOrderFormScreen> createState() =>
      _ClientOrderFormScreenState();
}

class _ClientOrderFormScreenState
    extends ConsumerState<ClientOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime? _desiredDeliveryDate;
  bool _isSubmitting = false;

  final List<ClientOrderLineValue?> _lineValues = [];
  int _lineCount = 0;

  @override
  void initState() {
    super.initState();
    final items = widget.initialItems;
    if (items != null && items.isNotEmpty) {
      _lineValues.addAll(items);
      _lineCount = items.length;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _total => _lineValues
      .whereType<ClientOrderLineValue>()
      .fold(0.0, (sum, l) => sum + l.quantity * l.unitPrice);

  void _addLine() {
    setState(() {
      _lineValues.add(null);
      _lineCount++;
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lineValues.removeAt(index);
      _lineCount--;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un client'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final validLines = _lineValues.whereType<ClientOrderLineValue>().toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Au moins un article est requis'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final repo = ref.read(clientOrderRepositoryProvider);
      final deposit = double.tryParse(_depositController.text);

      await repo.createOrder(
        tenantId: tenantId,
        customerId: _selectedCustomer!.remoteId ?? _selectedCustomer!.uuid,
        lines: validLines.map((l) => l.toJson()).toList(),
        depositAmount: deposit,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        desiredDeliveryDate: _desiredDeliveryDate,
      );

      final userId = ref.read(userProfileProvider).valueOrNull?.id;
      ref.invalidate(clientOrdersProvider(ClientOrdersFilter(createdBy: userId)));

      if (!mounted) return;

      if (widget.isEmbedded) {
        setState(() {
          _lineValues.clear();
          _lineCount = 0;
          _selectedCustomer = null;
          _customerController.clear();
          _depositController.clear();
          _notesController.clear();
          _desiredDeliveryDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Commande créée avec succès'),
              backgroundColor: Colors.green),
        );
        widget.onCreated?.call();
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Commande créée avec succès'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildFormContent(BuildContext context, List products) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Client ────────────────────────────────────────────────────
        const SheetSectionLabel('Client'),
        const SizedBox(height: 6),
        _CustomerAutocomplete(
          controller: _customerController,
          onSelected: (c) => setState(() => _selectedCustomer = c),
        ),
        const SizedBox(height: 16),

        // ── Articles ──────────────────────────────────────────────────
        Row(
          children: [
            const SheetSectionLabel('Articles'),
            const Spacer(),
            GestureDetector(
              onTap: _addLine,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kSheetBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: kSheetBlue.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, size: 14, color: kSheetBlue),
                    SizedBox(width: 4),
                    Text('Ajouter un article',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kSheetBlue)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_lineCount, (i) {
          return ClientOrderLineFormWidget(
            key: ValueKey('line_$i'),
            products: List.from(products),
            onRemove: () => _removeLine(i),
            onChange: (val) => setState(() => _lineValues[i] = val),
            initialValue: i < _lineValues.length ? _lineValues[i] : null,
          );
        }),
        if (_lineCount == 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: kSheetSlate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSheetSlate200),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 28, color: kSheetSlate200),
                SizedBox(height: 8),
                Text('Aucun article ajouté',
                    style: TextStyle(fontSize: 12, color: kSheetSlate500)),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // ── Options ───────────────────────────────────────────────────
        const SheetSectionLabel('Options'),
        const SizedBox(height: 8),

        // Date picker
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _desiredDeliveryDate = picked);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _desiredDeliveryDate != null
                  ? kSheetBlue.withValues(alpha: 0.04)
                  : Colors.white,
              border: Border.all(
                color: _desiredDeliveryDate != null
                    ? kSheetBlue.withValues(alpha: 0.3)
                    : kSheetSlate200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: _desiredDeliveryDate != null
                      ? kSheetBlue
                      : kSheetSlate500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _desiredDeliveryDate == null
                        ? 'Date souhaitée (optionnel)'
                        : DateFormat('dd/MM/yyyy')
                            .format(_desiredDeliveryDate!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _desiredDeliveryDate != null
                          ? kSheetSlate900
                          : kSheetSlate500,
                    ),
                  ),
                ),
                if (_desiredDeliveryDate != null)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _desiredDeliveryDate = null),
                    child: const Icon(Icons.close,
                        size: 16, color: kSheetSlate500),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _depositController,
          decoration: sheetInputDecoration(
              label: 'Acompte reçu (optionnel)', suffix: 'FCFA'),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: sheetInputDecoration(label: 'Notes (optionnel)'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // ── Total + submit ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kSheetBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: kSheetBlue.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  size: 16, color: kSheetBlue),
              const SizedBox(width: 8),
              Text('Total estimé',
                  style: const TextStyle(
                      fontSize: 12, color: kSheetSlate500)),
              const Spacer(),
              Text(
                _fcfa(_total),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kSheetSlate900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: sheetPrimaryButtonStyle(),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Créer la commande',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final products = productsAsync.valueOrNull ?? [];

    if (widget.isEmbedded) {
      return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildFormContent(context, products),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: _buildFormContent(context, products),
        ),
      ),
    );
  }
}

// ── Customer autocomplete ─────────────────────────────────────────────────────

class _CustomerAutocomplete extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final void Function(Customer) onSelected;

  const _CustomerAutocomplete({
    required this.controller,
    required this.onSelected,
  });

  @override
  ConsumerState<_CustomerAutocomplete> createState() =>
      _CustomerAutocompleteState();
}

class _CustomerAutocompleteState
    extends ConsumerState<_CustomerAutocomplete> {
  List<Customer> _suggestions = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final repo = ref.read(customerRepositoryProvider);
      final results = await repo.searchRemoteCustomers(tenantId, query);
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(Customer c) {
    widget.controller.text = c.name;
    setState(() => _suggestions = []);
    widget.onSelected(c);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: sheetInputDecoration(
            label: 'Client *',
            hint: 'Rechercher un client…',
            prefixIcon: const Icon(Icons.person_outline,
                size: 18, color: kSheetSlate500),
          ).copyWith(
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          onChanged: _search,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Veuillez sélectionner un client' : null,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final c = _suggestions[i];
                return InkWell(
                  onTap: () => _pick(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(c.name,
                        style: const TextStyle(fontSize: 14)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
