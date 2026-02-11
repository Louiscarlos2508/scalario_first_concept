import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/auth/auth_state.dart';

class CustomerSelectionDialog extends ConsumerStatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  ConsumerState<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends ConsumerState<CustomerSelectionDialog> {
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
    final customers = await ref.read(customerRepositoryProvider).getCustomers();
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
    final results = await ref.read(customerRepositoryProvider).searchRemoteCustomers(
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
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name or Phone',
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
                      ? const Center(child: Text('No customers found.'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final customer = _searchResults[index];
                            final hasDebt = customer.balance > 0;
                            return ListTile(
                              title: Text(customer.name),
                              subtitle: Text(customer.phone ?? 'No phone'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${customer.balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: hasDebt ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasDebt)
                                    IconButton(
                                      icon: const Icon(Icons.payments_outlined, color: Colors.green),
                                      onPressed: () => _showRepayDialog(customer),
                                      tooltip: 'Settle Debt',
                                    ),
                                ],
                              ),
                              onTap: () {
                                ref.read(selectedCustomerProvider.notifier).state = customer;
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
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _showAddCustomerDialog,
          icon: const Icon(Icons.add),
          label: const Text('NEW CUSTOMER'),
        ),
      ],
    );
  }

  void _showRepayDialog(Customer customer) {
    final amountController = TextEditingController(text: customer.balance.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle Debt: ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: \$${customer.balance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Repayment Amount',
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;

              try {
                await ref.read(customerRepositoryProvider).settleDebt(customer.remoteId!, amount);
                if (context.mounted) {
                  Navigator.pop(context); // Close repay dialog
                  _loadInitialCustomers(); // Refresh list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repayment recorded successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Settle'),
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
        title: const Text('New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              final userProfile = ref.read(userProfileProvider).value;
              final customer = await ref.read(customerRepositoryProvider).createCustomer(
                userProfile?.tenantId ?? '',
                {
                  'name': nameController.text,
                  'phone': phoneController.text,
                },
              );
              
              ref.read(selectedCustomerProvider.notifier).state = customer;
              if (context.mounted) {
                Navigator.pop(context); // Close add dialog
                Navigator.pop(context); // Close selection dialog
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
