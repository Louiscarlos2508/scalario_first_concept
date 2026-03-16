import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  Future<void> _loadInitialCustomers() async {
    setState(() => _isLoading = true);
    final customers =
        await ref.read(customerRepositoryProvider).getCustomers();
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
        .searchRemoteCustomers(
          userProfile?.tenantId ?? '',
          query,
        );
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un client'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadInitialCustomers();
                  },
                ),
              ),
              onChanged: _searchCustomers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text('Aucun client trouvé.'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final customer = _searchResults[index];
                            final hasDebt = customer.balance > 0;
                            return ListTile(
                              title: Text(customer.name),
                              subtitle: Text(
                                  customer.phone ?? 'Sans téléphone'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _fcfa(customer.balance),
                                    style: TextStyle(
                                      color: hasDebt
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasDebt)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.payments_outlined,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _showRepayDialog(customer),
                                      tooltip: 'Régler la dette',
                                    ),
                                ],
                              ),
                              onTap: () {
                                ref
                                    .read(selectedCustomerProvider.notifier)
                                    .state = customer;
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _showAddCustomerDialog,
          icon: const Icon(Icons.add),
          label: const Text('NOUVEAU CLIENT'),
        ),
      ],
    );
  }

  void _showRepayDialog(Customer customer) {
    final amountController =
        TextEditingController(text: customer.balance.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Régler la dette : ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Solde actuel : ${_fcfa(customer.balance)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Montant du remboursement',
                suffixText: 'FCFA',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Régler'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            TextField(
              controller: phoneController,
              decoration:
                  const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
