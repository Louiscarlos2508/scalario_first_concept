import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'return_resolution_dialog.dart';

class ReturnSearchSheet extends ConsumerStatefulWidget {
  /// When provided, skips the search step and goes straight to item selection.
  final Map<String, dynamic>? initialTransaction;

  const ReturnSearchSheet({super.key, this.initialTransaction});

  @override
  ConsumerState<ReturnSearchSheet> createState() => _ReturnSearchSheetState();
}

class _ReturnSearchSheetState extends ConsumerState<ReturnSearchSheet> {
  final _receiptController = TextEditingController();
  final _focusNode = FocusNode();

  _SheetState _state = const _SheetStateInitial();

  @override
  void initState() {
    super.initState();
    final preloaded = widget.initialTransaction;
    if (preloaded != null) {
      _state = _SheetStateFound(preloaded);
      final receipt = (preloaded['retailSale'] as Map<String, dynamic>?)?['receiptNumber']?.toString()
          ?? preloaded['id']?.toString()
          ?? '';
      _receiptController.text = receipt;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _receiptController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _receiptController.text.trim();
    if (query.isEmpty) return;

    setState(() => _state = const _SheetStateLoading());

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final repo = ref.read(returnsRepositoryProvider);
      final tx = await repo.searchTransaction(
        receiptNumber: query,
        tenantId: tenantId,
      );

      if (!mounted) return;
      if (tx == null) {
        setState(() => _state = const _SheetStateNotFound());
      } else {
        setState(() => _state = _SheetStateFound(tx));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _SheetStateError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Retour article',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _receiptController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        labelText: 'Numéro de reçu',
                        hintText: 'Saisir ou scanner le numéro',
                        border: const OutlineInputBorder(),
                        errorText: _state is _SheetStateNotFound
                            ? 'Vente introuvable — vérifiez le numéro de reçu'
                            : null,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _state is _SheetStateLoading ? null : _search,
                    child: _state is _SheetStateLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Rechercher'),
                  ),
                ],
              ),
            ),
            if (_state is _SheetStateError)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  (_state as _SheetStateError).message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _state is _SheetStateFound
                  ? _buildTransactionItems(
                      context, (_state as _SheetStateFound).transaction)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItems(
      BuildContext context, Map<String, dynamic> tx) {
    final items = (tx['itemsJson'] as List<dynamic>?) ?? [];
    final quantities = <int, int>{};

    return StatefulBuilder(builder: (context, setLocalState) {
      int totalSelected = 0;
      for (final qty in quantities.values) {
        totalSelected += qty;
      }

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final maxQty = (item['quantity'] as num?)?.toInt() ?? 1;
                final currentQty = quantities[index] ?? 0;
                return ListTile(
                  title: Text(item['name']?.toString() ?? item['catalogItemId']?.toString() ?? ''),
                  subtitle: Text(
                      'Prix : ${item['unitPrice'] ?? item['price']} FCFA'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: currentQty > 0
                            ? () => setLocalState(
                                () => quantities[index] = currentQty - 1)
                            : null,
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$currentQty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: currentQty < maxQty
                            ? () => setLocalState(
                                () => quantities[index] = currentQty + 1)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: totalSelected > 0
                    ? () => _confirmReturn(context, tx, items, quantities)
                    : null,
                icon: const Icon(Icons.undo),
                label: const Text('Confirmer le retour'),
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _confirmReturn(
    BuildContext context,
    Map<String, dynamic> tx,
    List<dynamic> items,
    Map<int, int> quantities,
  ) async {
    final selectedLines = <Map<String, dynamic>>[];
    for (final entry in quantities.entries) {
      if (entry.value > 0) {
        final item = items[entry.key] as Map<String, dynamic>;
        selectedLines.add({
          ...item,
          'returnQuantity': entry.value,
        });
      }
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ReturnResolutionDialog(
        originalTxId: tx['id']?.toString(),
        lines: selectedLines,
      ),
    );

    if (context.mounted) Navigator.of(context).pop();
  }
}

// State classes
abstract class _SheetState {
  const _SheetState();
}

class _SheetStateInitial extends _SheetState {
  const _SheetStateInitial();
}

class _SheetStateLoading extends _SheetState {
  const _SheetStateLoading();
}

class _SheetStateNotFound extends _SheetState {
  const _SheetStateNotFound();
}

class _SheetStateFound extends _SheetState {
  final Map<String, dynamic> transaction;
  const _SheetStateFound(this.transaction);
}

class _SheetStateError extends _SheetState {
  final String message;
  const _SheetStateError(this.message);
}
