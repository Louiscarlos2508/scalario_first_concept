import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/contacts/presentation/widgets/settle_debt_dialog.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

String _fcfa(double amount) => NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(amount);

final customerSearchProvider = StateProvider<String>((ref) => '');

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final tenantId = ref.watch(activeTenantProvider);
  final query = ref.watch(customerSearchProvider);

  if (tenantId == null) return [];

  if (query.isNotEmpty) {
    return repo.searchRemoteCustomers(tenantId, query);
  } else {
    return repo.getCustomers();
  }
});

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final isReadOnly = config != null
        ? (config.canAccess(role, 'clients_view') &&
            !config.canAccess(role, 'clients'))
        : role == 'manager';

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Clients',
        actions: [
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
            onPressed: () => ref.invalidate(customersProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton(
              key: const Key('add_contact_fab'),
              onPressed: () => _showContactForm(context, ref),
              child: const Icon(Icons.person_add),
            ),
      body: customersAsync.when(
        data: (customers) =>
            _buildCustomerList(context, ref, customers, isReadOnly),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    WidgetRef ref,
    List<Customer> customers,
    bool isReadOnly,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    const Text(
                      'Solde :',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      _fcfa(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            hasDebt ? AppColors.error : AppColors.success,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (hasDebt && !isReadOnly) ...[
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
                if (!isReadOnly) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showContactForm(context, ref, existing: customer);
                      } else if (action == 'delete') {
                        _confirmDelete(context, ref, customer);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Modifier'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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
      BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => SettleDebtDialog(customer: customer),
    );
  }

  void _showContactForm(BuildContext context, WidgetRef ref,
      {Customer? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ContactFormSheet(existing: existing),
    ).then((_) => ref.invalidate(customersProvider));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer "${customer.name}" ?\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final remoteId = customer.remoteId;
    if (remoteId == null) return;

    try {
      await ref
          .read(customerRepositoryProvider)
          .deleteContact(id: remoteId, tenantId: tenantId);
      ref.invalidate(customersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.name} supprimé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }
}

// ── Contact form (create + edit) ─────────────────────────────────────────────

class ContactFormSheet extends ConsumerStatefulWidget {
  final Customer? existing;

  const ContactFormSheet({super.key, this.existing});

  @override
  ConsumerState<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _contactType = 'customer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _phoneController.text = widget.existing!.phone ?? '';
      _emailController.text = widget.existing!.email ?? '';
      _contactType = widget.existing!.contactType ?? 'customer';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final repo = ref.read(customerRepositoryProvider);
    final name = _nameController.text.trim();
    final phone =
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final email =
        _emailController.text.trim().isEmpty ? null : _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      if (widget.existing == null) {
        await repo.createContact(
          name: name,
          phone: phone,
          email: email,
          contactType: _contactType,
          tenantId: tenantId,
        );
      } else {
        await repo.updateContact(
          id: widget.existing!.remoteId!,
          name: name,
          phone: phone,
          email: email,
          tenantId: tenantId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.existing == null ? 'Contact créé' : 'Contact modifié'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Modifier le contact' : 'Nouveau contact',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Type selector (disabled in edit — contactType is immutable)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'customer', label: Text('Client')),
                ButtonSegment(value: 'supplier', label: Text('Fournisseur')),
              ],
              selected: {_contactType},
              onSelectionChanged: isEdit
                  ? null
                  : (val) => setState(() => _contactType = val.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Enregistrer' : 'Créer le contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
