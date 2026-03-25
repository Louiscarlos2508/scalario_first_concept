import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';

class InternalRequestForm extends ConsumerStatefulWidget {
  const InternalRequestForm({super.key});

  @override
  ConsumerState<InternalRequestForm> createState() =>
      _InternalRequestFormState();
}

class _InternalRequestFormState extends ConsumerState<InternalRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  Product? _selectedProduct;
  String _urgency = 'normal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedProduct == null) return false;
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return false;
    return !_isSubmitting;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final repo = ref.read(internalRequestsRepositoryProvider);

    try {
      await repo.create(
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: int.parse(_quantityController.text),
        urgency: _urgency,
        tenantId: tenantId,
      );

      ref.invalidate(internalRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductListProvider);
    final products = paginatedAsync.maybeWhen(
      data: (data) => (data['items'] as List).cast<Product>(),
      orElse: () => <Product>[],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouvelle demande de réapprovisionnement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Produit
            ProductAutocomplete(
              key: const Key('ir_product_field'),
              products: products,
              onSelected: (p) => setState(() => _selectedProduct = p),
            ),
            const SizedBox(height: 12),

            // Quantité
            TextFormField(
              key: const Key('ir_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final qty = int.tryParse(v ?? '');
                if (qty == null || qty <= 0) return 'Quantité invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Urgence
            Text('Urgence', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  key: const Key('ir_urgency_normal'),
                  label: const Text('Normal'),
                  selected: _urgency == 'normal',
                  onSelected: (_) => setState(() => _urgency = 'normal'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: const Key('ir_urgency_urgent'),
                  label: const Text('Urgent'),
                  selected: _urgency == 'urgent',
                  selectedColor: Colors.red.shade100,
                  onSelected: (_) => setState(() => _urgency = 'urgent'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              key: const Key('ir_submit_button'),
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer la demande'),
            ),
          ],
        ),
      ),
    );
  }
}
