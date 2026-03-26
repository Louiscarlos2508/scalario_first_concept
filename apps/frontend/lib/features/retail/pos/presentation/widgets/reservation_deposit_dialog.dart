import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReservationDepositDialog extends ConsumerStatefulWidget {
  final CartState cartState;

  /// Fraction of total allowed as minimum deposit (default 10 %).
  final double minDepositPct;

  /// Fraction of total allowed as maximum deposit (default 50 %).
  final double maxDepositPct;

  const ReservationDepositDialog({
    super.key,
    required this.cartState,
    this.minDepositPct = 0.10,
    this.maxDepositPct = 0.50,
  });

  @override
  ConsumerState<ReservationDepositDialog> createState() =>
      _ReservationDepositDialogState();
}

class _ReservationDepositDialogState
    extends ConsumerState<ReservationDepositDialog> {
  final _depositController = TextEditingController();
  Map<String, dynamic>? _selectedContact;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _depositError;

  double get _totalAmount => widget.cartState.totalAmount;

  /// Parses the deposit field, stripping locale artefacts (spaces, NBSP, commas).
  double? _parseDeposit() {
    final cleaned = _depositController.text
        .replaceAll(' ', '')
        .replaceAll('\u00a0', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  double get _depositAmount => _parseDeposit() ?? (_totalAmount * 0.3);

  double get _remainingAmount => _totalAmount - _depositAmount;

  bool get _depositValid {
    final d = _parseDeposit();
    if (d == null || d <= 0) return false;
    return d >= _totalAmount * widget.minDepositPct &&
        d <= _totalAmount * widget.maxDepositPct;
  }

  bool get _canConfirm =>
      _selectedContact != null && _depositValid && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    // int.toString() is locale-neutral — no spaces, no commas
    _depositController.text = (_totalAmount * 0.3).round().toString();
    _depositController.addListener(_onDepositChanged);
    // Force an initial evaluation once the frame is built so the
    // button reflects the pre-filled value immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onDepositChanged() {
    final d = _parseDeposit();
    final minFcfa = _fcfa(_totalAmount * widget.minDepositPct);
    final maxFcfa = _fcfa(_totalAmount * widget.maxDepositPct);
    final minPct = (widget.minDepositPct * 100).round();
    final maxPct = (widget.maxDepositPct * 100).round();
    setState(() {
      if (d == null || d <= 0) {
        _depositError = 'Montant invalide';
      } else if (d < _totalAmount * widget.minDepositPct ||
          d > _totalAmount * widget.maxDepositPct) {
        _depositError =
            "L'acompte doit être entre $minFcfa ($minPct %) et $maxFcfa ($maxPct %)";
      } else {
        _depositError = null;
      }
    });
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  Future<Iterable<Map<String, dynamic>>> _fetchContacts(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final uri =
          Uri.parse('${ApiConstants.baseUrl}/contacts/search').replace(
        queryParameters: {
          'tenantId': tenantId,
          'q': query.trim(),
          'contactType': 'customer',
        },
      );
      final response = await http
          .get(uri, headers: ApiConstants.headers(tenantId: tenantId, token: token))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data is List
            ? data
            : (data is Map ? (data['items'] as List? ?? []) : []);
        return items.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // fail silently
    }
    return const [];
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final userProfile = ref.read(userProfileProvider).value;
      final userId = userProfile?.id ?? '';
      final repo = ref.read(reservationsRepositoryProvider);

      final items = widget.cartState.items
          .where((i) => !i.isFreeItem)
          .map((i) => {
                'catalogItemId': i.product.remoteId ?? '',
                if (i.variantId != null) 'variantId': i.variantId,
                'name': i.variantLabel != null
                    ? '${i.product.name} — ${i.variantLabel}'
                    : i.product.name,
                'quantity': i.quantity,
                'unitPrice': i.unitPrice,
              })
          .toList();

      await repo.createReservation(
        tenantId: tenantId,
        userId: userId,
        customerId: _selectedContact!['id'].toString(),
        items: items,
        totalAmount: _totalAmount,
        depositAmount: _depositAmount,
        paymentMethod: widget.cartState.paymentMethod,
      );

      // Clear cart and invalidate KPI
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(reservationsKpiProvider);

      if (!mounted) return;
      Navigator.of(context).pop();

      final remaining = _totalAmount - _depositAmount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Réservation créée — Solde restant : ${_fcfa(remaining)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réservation avec acompte'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),
              // Contact autocomplete
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (c) {
                  final name = c['name']?.toString() ?? '';
                  final phone = c['phone']?.toString();
                  return phone != null ? '$name — $phone' : name;
                },
                optionsBuilder: (textEditingValue) =>
                    _fetchContacts(textEditingValue.text),
                onSelected: (contact) =>
                    setState(() => _selectedContact = contact),
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Client *',
                      hintText: 'Taper au moins 2 caractères…',
                      prefixIcon: Icon(Icons.person_search_outlined),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final contact = options.elementAt(index);
                            final name =
                                contact['name']?.toString() ?? '—';
                            final phone = contact['phone']?.toString();
                            final rawBalance = contact['balance'];
                            final balance = rawBalance is num
                                ? rawBalance.toDouble()
                                : double.tryParse(
                                        rawBalance?.toString() ?? '') ??
                                    0.0;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(name),
                              subtitle:
                                  phone != null ? Text(phone) : null,
                              trailing: balance > 0
                                  ? Text(
                                      'Doit ${_fcfa(balance)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    )
                                  : null,
                              onTap: () => onSelected(contact),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Info banner: total / min / max
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow('Total panier', _fcfa(_totalAmount)),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Acompte min (${(widget.minDepositPct * 100).round()} %)',
                      _fcfa((_totalAmount * widget.minDepositPct).roundToDouble()),
                      color: Colors.grey,
                    ),
                    _infoRow(
                      'Acompte max (${(widget.maxDepositPct * 100).round()} %)',
                      _fcfa((_totalAmount * widget.maxDepositPct).roundToDouble()),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Deposit field
              TextField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Acompte (FCFA)',
                  border: const OutlineInputBorder(),
                  errorText: _depositError,
                ),
              ),
              const SizedBox(height: 8),
              // Quick % shortcuts
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [10, 25, 30, 50].map((pct) {
                  final amount = (_totalAmount * pct / 100).round();
                  return ActionChip(
                    label: Text('$pct % — ${_fcfa(amount.toDouble())}'),
                    onPressed: () {
                      _depositController.text = amount.toString();
                    },
                  );
                }).toList(),
              ),
              // Live summary
              if (_depositValid) ...[
                const Divider(height: 24),
                _summaryRow(
                  'Acompte encaissé maintenant',
                  _fcfa(_depositAmount),
                  color: Colors.green.shade700,
                  bold: true,
                ),
                _summaryRow(
                  'Solde à régler lors du retrait',
                  _fcfa(_remainingAmount.clamp(0, double.infinity)),
                  color: Colors.orange.shade800,
                  bold: true,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _canConfirm ? _confirm : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirmer la réservation'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color ?? Colors.grey)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color ?? Colors.grey)),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              )),
        ],
      ),
    );
  }
}
