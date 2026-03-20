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

  const ReservationDepositDialog({super.key, required this.cartState});

  @override
  ConsumerState<ReservationDepositDialog> createState() =>
      _ReservationDepositDialogState();
}

class _ReservationDepositDialogState
    extends ConsumerState<ReservationDepositDialog> {
  final _depositController = TextEditingController();
  Map<String, dynamic>? _selectedContact;
  List<Map<String, dynamic>> _contactSuggestions = [];
  bool _isSearchingContacts = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _depositError;

  double get _totalAmount => widget.cartState.totalAmount;

  double get _depositAmount =>
      double.tryParse(_depositController.text) ?? (_totalAmount * 0.3);

  double get _remainingAmount => _totalAmount - _depositAmount;

  bool get _depositValid {
    final d = double.tryParse(_depositController.text);
    if (d == null) return false;
    return d >= _totalAmount * 0.1 && d <= _totalAmount * 0.5;
  }

  bool get _canConfirm => _selectedContact != null && _depositValid && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _depositController.text = (_totalAmount * 0.3).toStringAsFixed(0);
    _depositController.addListener(_onDepositChanged);
  }

  void _onDepositChanged() {
    final d = double.tryParse(_depositController.text);
    setState(() {
      if (d == null) {
        _depositError = 'Montant invalide';
      } else if (d < _totalAmount * 0.1 || d > _totalAmount * 0.5) {
        _depositError = "L'acompte doit être entre 10 % et 50 % du total";
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

  Future<void> _searchContacts(String query) async {
    if (query.length < 2) return;
    setState(() => _isSearchingContacts = true);
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final uri = Uri.parse('${ApiConstants.baseUrl}/contacts').replace(
        queryParameters: {'q': query, 'tenantId': tenantId, 'limit': '10'},
      );
      final response = await http.get(
        uri,
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['items'] ?? data) as List<dynamic>;
        setState(() {
          _contactSuggestions = items.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      // fail silently
    } finally {
      setState(() => _isSearchingContacts = false);
    }
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
                displayStringForOption: (c) => c['name']?.toString() ?? '',
                optionsBuilder: (textEditingValue) async {
                  await _searchContacts(textEditingValue.text);
                  return _contactSuggestions;
                },
                onSelected: (contact) =>
                    setState(() => _selectedContact = contact),
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Client *',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isSearchingContacts
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Total (read-only)
              _infoRow('Montant total :', _fcfa(_totalAmount)),
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
              const SizedBox(height: 12),
              // Live indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Acompte : ${_fcfa(_depositAmount)}',
                      style: const TextStyle(color: Colors.blue)),
                  Text('Solde : ${_fcfa(_remainingAmount.clamp(0, double.infinity))}',
                      style: const TextStyle(color: Colors.orange)),
                ],
              ),
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

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
