import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../widgets/settle_debt_dialog.dart';

String _fcfa(double amount) => NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
).format(amount);

final customerSearchProvider = StateProvider<String>((ref) => '');

final dashboardCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final tenantId = ref.watch(activeTenantProvider);
  final query = ref.watch(customerSearchProvider);

  if (tenantId == null) return [];

  if (query.isNotEmpty) {
    return repo.searchRemoteCustomers(tenantId, query);
  } else {
    // For simplicity, we fetch all in the dashboard list
    return repo.getCustomers();
  }
});

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(dashboardCustomersProvider);
    final searchQuery = ref.watch(customerSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          // Search Bar
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                ref.read(customerSearchProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardCustomersProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: customersAsync.when(
        data: (customers) => _buildCustomerList(context, ref, customers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    WidgetRef ref,
    List<Customer> customers,
  ) {
    if (customers.isEmpty) {
      return const Center(child: Text('Aucun client trouvé.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final balance = customer.balance;
        final hasDebt = balance > 0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer.phone != null) Text(customer.phone!),
                if (customer.email != null) Text(customer.email!),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Solde :',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _fcfa(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasDebt ? AppColors.error : AppColors.success,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (hasDebt) ...[
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: () =>
                        _showSettleDebtDialog(context, ref, customer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('RÉGLER LA DETTE'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettleDebtDialog(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    showDialog(
      context: context,
      builder: (context) => SettleDebtDialog(customer: customer),
    );
  }
}
