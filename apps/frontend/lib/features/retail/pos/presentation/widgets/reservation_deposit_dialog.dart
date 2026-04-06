import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReservationDepositDialog extends ConsumerStatefulWidget {
  final CartState cartState;
  final double minDepositPct;
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
  final _contactCtrl = TextEditingController();
  Map<String, dynamic>? _selectedContact;
  List<Map<String, dynamic>> _contactSuggestions = [];
  bool _contactLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _depositError;

  double get _totalAmount => widget.cartState.totalAmount;

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
    _depositController.text = (_totalAmount * 0.3).round().toString();
    _depositController.addListener(_onDepositChanged);
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
            "Acompte entre $minFcfa ($minPct%) et $maxFcfa ($maxPct%)";
      } else {
        _depositError = null;
      }
    });
  }

  Future<void> _searchContacts(String query) async {
    if (query.trim().length < 2) {
      setState(() => _contactSuggestions = []);
      return;
    }
    setState(() => _contactLoading = true);
    try {
      final results = await _fetchContacts(query);
      if (mounted) setState(() => _contactSuggestions = results.toList());
    } catch (_) {
      if (mounted) setState(() => _contactSuggestions = []);
    } finally {
      if (mounted) setState(() => _contactLoading = false);
    }
  }

  void _pickContact(Map<String, dynamic> contact) {
    _contactCtrl.text = contact['name']?.toString() ?? '';
    setState(() {
      _selectedContact = contact;
      _contactSuggestions = [];
    });
  }

  @override
  void dispose() {
    _depositController.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<Iterable<Map<String, dynamic>>> _fetchContacts(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final uri =
          Uri.parse('${ApiConstants.baseUrl}/contacts/search').replace(
        queryParameters: {
          'tenantId': tenantId,
          'q': query.trim(),
          'contactType': 'customer',
        },
      );
      final response = await http
          .get(uri,
              headers:
                  ApiConstants.headers(tenantId: tenantId, token: token))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data is List
            ? data
            : (data is Map ? (data['items'] as List? ?? []) : []);
        return items.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
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

      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(reservationsKpiProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Réservation créée — Solde restant : ${_fcfa(_remainingAmount)}'),
          backgroundColor: kSheetGreen,
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
    return Dialog(
      shape: kSheetDialogShape,
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              const SheetDialogHeader(
                icon: Icons.bookmark_add_outlined,
                iconColor: kSheetBlue,
                title: 'Réservation avec acompte',
                subtitle: 'Enregistrez la commande et encaissez l\'acompte',
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Error ─────────────────────────────────────────
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: kSheetRed.withValues(alpha: 0.07),
                            border: Border.all(
                                color: kSheetRed.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 15, color: kSheetRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        fontSize: 12, color: kSheetRed)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Contact autocomplete ───────────────────────────
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _contactCtrl,
                            decoration: sheetInputDecoration(
                              label: 'Client *',
                              hint: 'Taper au moins 2 caractères…',
                              prefixIcon: const Icon(
                                  Icons.person_search_outlined,
                                  size: 18,
                                  color: kSheetSlate500),
                            ).copyWith(
                              suffixIcon: _contactLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                            onChanged: _searchContacts,
                          ),
                          if (_contactSuggestions.isNotEmpty)
                            Container(
                              constraints:
                                  const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black12),
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _contactSuggestions.length,
                                separatorBuilder: (_, _) =>
                                    const SheetDivider(),
                                itemBuilder: (_, i) {
                                  final contact = _contactSuggestions[i];
                                  final name =
                                      contact['name']?.toString() ?? '—';
                                  final phone =
                                      contact['phone']?.toString();
                                  final rawBalance = contact['balance'];
                                  final balance = rawBalance is num
                                      ? rawBalance.toDouble()
                                      : double.tryParse(
                                              rawBalance?.toString() ??
                                                  '') ??
                                          0.0;
                                  return InkWell(
                                    onTap: () => _pickContact(contact),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          _ContactAvatar(name: name),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: kSheetSlate900)),
                                                if (phone != null)
                                                  Text(phone,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              kSheetSlate500)),
                                              ],
                                            ),
                                          ),
                                          if (balance > 0)
                                            Text(
                                              'Doit ${_fcfa(balance)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: kSheetRed,
                                                  fontWeight:
                                                      FontWeight.w500),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Total / min / max banner ───────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSheetBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: kSheetBlue.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                                label: 'Total panier',
                                value: _fcfa(_totalAmount),
                                valueStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kSheetSlate900)),
                            const SizedBox(height: 6),
                            _InfoRow(
                              label:
                                  'Min (${(widget.minDepositPct * 100).round()}%)',
                              value: _fcfa(_totalAmount * widget.minDepositPct),
                              valueStyle: const TextStyle(
                                  fontSize: 12, color: kSheetSlate500),
                            ),
                            _InfoRow(
                              label:
                                  'Max (${(widget.maxDepositPct * 100).round()}%)',
                              value: _fcfa(_totalAmount * widget.maxDepositPct),
                              valueStyle: const TextStyle(
                                  fontSize: 12, color: kSheetSlate500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Deposit field ──────────────────────────────────
                      TextField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        decoration: sheetInputDecoration(
                          label: 'Acompte *',
                          suffix: 'FCFA',
                        ).copyWith(errorText: _depositError),
                      ),
                      const SizedBox(height: 10),

                      // ── % shortcuts ────────────────────────────────────
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [10, 25, 30, 50].map((pct) {
                          final amount =
                              (_totalAmount * pct / 100).round();
                          final isActive =
                              (_depositController.text) ==
                                  amount.toString();
                          return GestureDetector(
                            onTap: () => setState(() {
                              _depositController.text = amount.toString();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? kSheetBlue
                                    : kSheetSlate50,
                                border: Border.all(
                                  color: isActive
                                      ? kSheetBlue
                                      : kSheetSlate200,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$pct% · ${_fcfa(amount.toDouble())}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : kSheetSlate500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // ── Live summary ───────────────────────────────────
                      if (_depositValid) ...[
                        const SizedBox(height: 14),
                        const SheetDivider(),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Acompte encaissé',
                          value: _fcfa(_depositAmount),
                          color: kSheetGreen,
                        ),
                        const SizedBox(height: 4),
                        _SummaryRow(
                          label: 'Solde à régler au retrait',
                          value: _fcfa(_remainingAmount.clamp(0, double.infinity)),
                          color: kSheetAmber,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Actions ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: sheetCancelButtonStyle(),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: sheetPrimaryButtonStyle(),
                      onPressed: _canConfirm ? _confirm : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirmer',
                              style:
                                  TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ContactAvatar extends StatelessWidget {
  final String name;
  const _ContactAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green, Colors.red,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7)),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: kSheetSlate500)),
        Text(value,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kSheetSlate900)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: kSheetSlate500)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
