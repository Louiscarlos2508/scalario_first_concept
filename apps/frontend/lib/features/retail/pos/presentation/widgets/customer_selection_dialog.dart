import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/auth/auth_state.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class CustomerSelectionDialog extends ConsumerStatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  ConsumerState<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState
    extends ConsumerState<CustomerSelectionDialog> {
  final _searchController = TextEditingController();
  List<Customer> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialCustomers() async {
    setState(() => _isLoading = true);
    final all = await ref.read(customerRepositoryProvider).getCustomers();
    // Only show synced customers (remoteId set) — unsynced ones can't be
    // linked to a sale on the backend.
    final customers = all.where((c) => c.remoteId != null).toList();
    setState(() {
      _searchResults = customers;
      _isLoading = false;
    });
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      _loadInitialCustomers();
      return;
    }
    setState(() => _isLoading = true);
    final userProfile = ref.read(userProfileProvider).value;
    final results = await ref
        .read(customerRepositoryProvider)
        .searchRemoteCustomers(userProfile?.tenantId ?? '', query);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
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
                icon: Icons.person_search_outlined,
                iconColor: kSheetBlue,
                title: 'Choisir un client',
              ),
              const SizedBox(height: 16),

              // ── Search field ────────────────────────────────────────────
              TextField(
                controller: _searchController,
                decoration: sheetInputDecoration(
                  label: 'Rechercher un client...',
                  prefixIcon: const Icon(Icons.search,
                      color: kSheetSlate500, size: 18),
                ).copyWith(
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          color: kSheetSlate500,
                          onPressed: () {
                            _searchController.clear();
                            _loadInitialCustomers();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (q) {
                  setState(() {});
                  _searchCustomers(q);
                },
              ),
              const SizedBox(height: 12),

              // ── Results ─────────────────────────────────────────────────
              SizedBox(
                height: 320,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined,
                                    size: 40, color: kSheetSlate200),
                                const SizedBox(height: 8),
                                const Text('Aucun client trouvé.',
                                    style:
                                        TextStyle(color: kSheetSlate500)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, _) =>
                                const SheetDivider(),
                            itemBuilder: (context, index) {
                              final customer = _searchResults[index];
                              final hasDebt = customer.balance > 0;
                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ref
                                      .read(
                                          selectedCustomerProvider.notifier)
                                      .state = customer;
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                  child: Row(
                                    children: [
                                      _CustomerAvatar(
                                          name: customer.name),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: kSheetSlate900),
                                            ),
                                            if (customer.phone != null)
                                              Text(
                                                customer.phone!,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: kSheetSlate500),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _fcfa(customer.balance),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: hasDebt
                                                  ? kSheetRed
                                                  : kSheetGreen,
                                            ),
                                          ),
                                          if (hasDebt)
                                            GestureDetector(
                                              onTap: () =>
                                                  _showRepayDialog(
                                                      customer),
                                              child: const Text(
                                                'Régler →',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: kSheetGreen,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              const SheetDivider(),
              const SizedBox(height: 16),

              // ── Bottom actions ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: sheetCancelButtonStyle(),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: sheetPrimaryButtonStyle(),
                      onPressed: _showAddCustomerDialog,
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Nouveau client'),
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

  void _showRepayDialog(Customer customer) {
    final amountController =
        TextEditingController(text: customer.balance.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: kSheetDialogShape,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetDialogHeader(
                icon: Icons.payments_outlined,
                iconColor: kSheetGreen,
                title: 'Régler la dette',
                subtitle: customer.name,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kSheetRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: kSheetRed.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: kSheetRed),
                    const SizedBox(width: 8),
                    Text('Solde actuel : ${_fcfa(customer.balance)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kSheetRed)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: sheetInputDecoration(
                    label: 'Montant du remboursement', suffix: 'FCFA'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              SheetActionRow(
                confirmLabel: 'Régler',
                confirmColor: kSheetGreen,
                onConfirm: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? 0.0;
                  if (amount <= 0) return;
                  try {
                    await ref
                        .read(customerRepositoryProvider)
                        .settleDebt(customer.remoteId!, amount);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadInitialCustomers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Remboursement enregistré'),
                            backgroundColor: kSheetGreen),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erreur : $e'),
                            backgroundColor: kSheetRed),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: kSheetDialogShape,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDialogHeader(
                icon: Icons.person_add_outlined,
                iconColor: kSheetBlue,
                title: 'Nouveau client',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: sheetInputDecoration(label: 'Nom complet *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: sheetInputDecoration(label: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SheetActionRow(
                confirmLabel: 'Enregistrer',
                onConfirm: () async {
                  if (nameController.text.isEmpty) return;
                  final userProfile = ref.read(userProfileProvider).value;
                  final customer = await ref
                      .read(customerRepositoryProvider)
                      .createCustomer(
                        userProfile?.tenantId ?? '',
                        {
                          'name': nameController.text,
                          'phone': phoneController.text,
                        },
                      );
                  ref.read(selectedCustomerProvider.notifier).state =
                      customer;
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Customer avatar ───────────────────────────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  final String name;
  const _CustomerAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green, Colors.red,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
