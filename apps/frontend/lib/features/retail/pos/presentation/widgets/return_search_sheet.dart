import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/sheet_style.dart';
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
      final receipt =
          (preloaded['retailSale'] as Map<String, dynamic>?)?['receiptNumber']
                  ?.toString() ??
              preloaded['id']?.toString() ??
              '';
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
      setState(() =>
          _state = tx == null ? const _SheetStateNotFound() : _SheetStateFound(tx));
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _SheetStateError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              SheetTitleRow(
                title: 'Retour article',
                icon: Icons.undo_outlined,
                iconColor: kSheetAmber,
              ),
              const SheetDivider(),
              const SizedBox(height: 16),

              // ── Search row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _receiptController,
                      focusNode: _focusNode,
                      decoration: sheetInputDecoration(
                        label: 'Numéro de reçu',
                        hint: 'Saisir ou scanner le numéro',
                        prefixIcon: const Icon(Icons.receipt_outlined,
                            size: 18, color: kSheetSlate500),
                      ).copyWith(
                        errorText: _state is _SheetStateNotFound
                            ? 'Vente introuvable — vérifiez le numéro'
                            : null,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: sheetPrimaryButtonStyle(),
                      onPressed:
                          _state is _SheetStateLoading ? null : _search,
                      child: _state is _SheetStateLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Chercher'),
                    ),
                  ),
                ],
              ),

              // ── Error state ──────────────────────────────────────────────
              if (_state is _SheetStateError)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSheetRed.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: kSheetRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 15, color: kSheetRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              (_state as _SheetStateError).message,
                              style: const TextStyle(
                                  fontSize: 12, color: kSheetRed)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // ── Items list ───────────────────────────────────────────────
              Expanded(
                child: _state is _SheetStateFound
                    ? _buildTransactionItems(
                        context,
                        (_state as _SheetStateFound).transaction,
                        scrollController,
                      )
                    : _state is _SheetStateInitial
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 48, color: kSheetSlate200),
                                const SizedBox(height: 12),
                                const Text(
                                    'Saisissez un numéro de reçu pour commencer',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: kSheetSlate500, fontSize: 13)),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItems(
    BuildContext context,
    Map<String, dynamic> tx,
    ScrollController scrollController,
  ) {
    final items = (tx['itemsJson'] as List<dynamic>?) ?? [];
    final quantities = <int, int>{};

    return StatefulBuilder(builder: (context, setLocalState) {
      int totalSelected = 0;
      for (final qty in quantities.values) {
        totalSelected += qty;
      }

      return Column(
        children: [
          const SizedBox(height: 12),
          // Confirmed banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kSheetGreen.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: kSheetGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 14, color: kSheetGreen),
                const SizedBox(width: 8),
                const Text('Vente trouvée — sélectionnez les articles à retourner',
                    style: TextStyle(fontSize: 12, color: kSheetGreen)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final maxQty = (item['quantity'] as num?)?.toInt() ?? 1;
                final currentQty = quantities[index] ?? 0;
                final name = item['name']?.toString() ??
                    item['catalogItemId']?.toString() ??
                    '';
                final price = (item['unitPrice'] ?? item['price'] as num? ?? 0)
                    .toDouble();

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentQty > 0
                        ? kSheetBlue.withValues(alpha: 0.04)
                        : kSheetSlate50,
                    border: Border.all(
                      color: currentQty > 0 ? kSheetBlue : kSheetSlate200,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kSheetSlate900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('${price.toStringAsFixed(0)} FCFA · max $maxQty',
                                style: const TextStyle(
                                    fontSize: 11, color: kSheetSlate500)),
                          ],
                        ),
                      ),
                      // Qty controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyBtn(
                            icon: Icons.remove,
                            enabled: currentQty > 0,
                            onTap: () => setLocalState(
                                () => quantities[index] = currentQty - 1),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('$currentQty',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kSheetSlate900)),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            enabled: currentQty < maxQty,
                            onTap: () => setLocalState(
                                () => quantities[index] = currentQty + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: sheetPrimaryButtonStyle(color: kSheetAmber),
              onPressed: totalSelected > 0
                  ? () => _confirmReturn(context, tx, items, quantities)
                  : null,
              icon: const Icon(Icons.undo, size: 16),
              label: Text('Retourner $totalSelected article${totalSelected > 1 ? 's' : ''}'),
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
        selectedLines.add({...item, 'returnQuantity': entry.value});
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

// ── Qty button ─────────────────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : kSheetSlate50,
          border: Border.all(
            color: enabled ? kSheetSlate200 : const Color(0xFFEFF2F7),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 14,
            color: enabled ? kSheetSlate900 : kSheetSlate200),
      ),
    );
  }
}

// ── State classes ─────────────────────────────────────────────────────────────

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
