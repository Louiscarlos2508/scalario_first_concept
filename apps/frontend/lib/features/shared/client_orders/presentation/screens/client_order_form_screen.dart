import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/widgets/client_order_line_form_widget.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ClientOrderFormScreen extends ConsumerStatefulWidget {
  const ClientOrderFormScreen({super.key});

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

  // Each entry: nullable ClientOrderLineValue (null = incomplete line)
  final List<ClientOrderLineValue?> _lineValues = [];
  int _lineCount = 0;

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

    final validLines =
        _lineValues.whereType<ClientOrderLineValue>().toList();
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
        customerId:
            _selectedCustomer!.remoteId ?? _selectedCustomer!.uuid,
        lines: validLines.map((l) => l.toJson()).toList(),
        depositAmount: deposit,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        desiredDeliveryDate: _desiredDeliveryDate,
      );

      ref.invalidate(clientOrdersProvider);

      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final products = productsAsync.valueOrNull ?? [];

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Nouvelle commande client',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
            // ── Client selection ────────────────────────────────────────
            Text('Client', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            _CustomerAutocomplete(
              controller: _customerController,
              onSelected: (c) => setState(() => _selectedCustomer = c),
            ),
            const SizedBox(height: 16),

            // ── Lines ───────────────────────────────────────────────────
            Row(
              children: [
                Text('Articles',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un article'),
                  onPressed: _addLine,
                ),
              ],
            ),
            ...List.generate(_lineCount, (i) {
              return ClientOrderLineFormWidget(
                key: ValueKey('line_$i'),
                products: products,
                onRemove: () => _removeLine(i),
                onChange: (val) =>
                    setState(() => _lineValues[i] = val),
              );
            }),
            if (_lineCount == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun article — tapez "Ajouter un article"',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),

            // ── Optional fields ─────────────────────────────────────────
            Text('Options', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Desired delivery date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_desiredDeliveryDate == null
                  ? 'Date souhaitée (optionnel)'
                  : 'Date souhaitée : ${DateFormat('dd/MM/yyyy').format(_desiredDeliveryDate!)}'),
              trailing: _desiredDeliveryDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _desiredDeliveryDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _desiredDeliveryDate = picked);
                }
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _depositController,
              decoration: const InputDecoration(
                labelText: 'Acompte reçu (optionnel)',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Total + submit ──────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Total : ${_fcfa(_total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer la commande'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ],
  ),
);
  }
}

// ── Inline customer autocomplete ─────────────────────────────────────────────

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
      final results =
          await repo.searchRemoteCustomers(tenantId, query);
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Customer>(
      displayStringForOption: (c) => c.name,
      optionsBuilder: (_) async => _suggestions,
      onSelected: (c) {
        widget.controller.text = c.name;
        widget.onSelected(c);
      },
      fieldViewBuilder: (ctx, ctrl, focusNode, _) => TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: 'Client *',
          hintText: 'Rechercher un client…',
          prefixIcon: const Icon(Icons.person_outline),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: _search,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Veuillez sélectionner un client' : null,
      ),
    );
  }
}
