import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/return_search_sheet.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

String _methodLabel(String? m) => switch ((m ?? '').toUpperCase()) {
      'CASH' => 'Espèces',
      'MOBILE_MONEY' => 'Mobile Money',
      'CARD' => 'Carte',
      'TRANSFER' => 'Virement',
      'CREDIT' => 'Crédit',
      'SPLIT' => 'Mixte',
      _ => m ?? '—',
    };

Color _methodColor(String? m) => switch ((m ?? '').toUpperCase()) {
      'CASH' => Colors.green,
      'MOBILE_MONEY' => Colors.orange,
      'CARD' => Colors.blue,
      'TRANSFER' => Colors.purple,
      'CREDIT' => Colors.red,
      'SPLIT' => Colors.teal,
      _ => Colors.grey,
    };

class SalesHistoryScreen extends ConsumerStatefulWidget {
  /// Pre-filters: force userId (commercial sees only own), set initial period.
  final String? fixedUserId;
  final String initialPeriod;

  const SalesHistoryScreen({
    super.key,
    this.fixedUserId,
    this.initialPeriod = '7d',
  });

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _periodKey = '7d';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _method; // null = all
  String? _cashierId; // null = all cashiers (owner/manager only)

  /// userId → displayName, populated from GET /tenant/my-users for owner/manager.
  Map<String, String> _cashierMap = {};

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _periodKey = widget.initialPeriod;
    _applyPeriod(_periodKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Fetches the tenant's user list to populate the cashier filter (owner/manager only).
  Future<void> _loadUsers() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final role = profile?.role ?? '';
    final config = ref.read(businessTypeConfigProvider).valueOrNull;
    final hasFullAccess =
        canAccessScreen(role, 'backoffice', config) ||
        canAccessScreen(role, 'backoffice_restricted', config);
    if (!hasFullAccess) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/tenant/my-users'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 && mounted) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _cashierMap = {
            for (final u in list)
              (u['userId'] as String): (() {
                final name = u['fullName'] as String?;
                return (name != null && name.isNotEmpty)
                    ? name
                    : (u['email'] as String? ?? '—');
              })(),
          };
        });
      }
    } catch (_) {
      // Best-effort — cashier filter will just stay hidden on error
    }
  }

  void _applyPeriod(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (key) {
      case 'today':
        _dateRange = DateTimeRange(start: today, end: today);
      case '7d':
        _dateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today);
      case '30d':
        _dateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: today);
      default:
        break; // 'custom' — keep current _dateRange
    }
  }

  Future<void> _load() async {
    final gen = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final profile = ref.read(userProfileProvider).valueOrNull;
      final role = profile?.role ?? '';
      final config = ref.read(businessTypeConfigProvider).valueOrNull;
      final showAll =
          canAccessScreen(role, 'backoffice', config) ||
          canAccessScreen(role, 'backoffice_restricted', config);

      final effectiveUserId = widget.fixedUserId ??
          (showAll ? _cashierId : profile?.id);

      // Snapshot filter state so the closure is stable across the await
      final snapshotMethod = _method;
      final snapshotSearch = _search;
      final snapshotRange = _dateRange;

      final params = <String, String>{
        'tenantId': tenantId,
        'limit': '200',
      };
      if (snapshotRange != null) {
        params['from'] = DateFormat('yyyy-MM-dd').format(snapshotRange.start);
        params['to'] = DateFormat('yyyy-MM-dd').format(snapshotRange.end);
      }
      if (snapshotSearch.isNotEmpty) params['search'] = snapshotSearch;
      if (snapshotMethod != null) params['paymentMethod'] = snapshotMethod;
      if (effectiveUserId != null) params['userId'] = effectiveUserId;

      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}/transactions')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (!mounted || gen != _loadGeneration) return;
      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Summary helpers ────────────────────────────────────────────────────────

  Map<String, double> _computeByMethod(List<dynamic> items) {
    final map = <String, double>{};
    for (final tx in items) {
      final m = (tx['paymentMethod'] as String?) ?? 'UNKNOWN';
      final amount = double.tryParse(tx['totalAmount']?.toString() ?? '0') ?? 0;
      map[m] = (map[m] ?? 0) + amount;
    }
    return map;
  }

  // ── Grouped list helpers ───────────────────────────────────────────────────

  List<_ListEntry> _buildEntries(List<dynamic> items) {
    final entries = <_ListEntry>[];
    String? lastDay;
    for (final tx in items) {
      final raw = tx['createdAt']?.toString() ?? '';
      final dt =
          raw.isEmpty ? DateTime.now() : DateTime.tryParse(raw) ?? DateTime.now();
      final dayKey = DateFormat('yyyy-MM-dd').format(dt.toLocal());
      if (dayKey != lastDay) {
        entries.add(_ListEntry.header(dayKey, dt));
        lastDay = dayKey;
      }
      entries.add(_ListEntry.tx(tx as Map<String, dynamic>, dt));
    }
    return entries;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  String? _resolveCashierName(Map<String, dynamic> tx) {
    final cashierId =
        (tx['retailSale'] as Map<String, dynamic>?)?['cashierId'] as String?;
    if (cashierId == null) return null;
    return _cashierMap[cashierId];
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final role = profile?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    // Only owner (full backoffice access) can cancel/return a sale.
    final canReturn = canAccessScreen(role, 'backoffice', config);

    final rawItems = (_data?['items'] as List<dynamic>?) ?? [];

    // Client-side filter as safeguard (server also filters, but this ensures
    // correctness even if the backend param doesn't take effect immediately).
    final items = _method == null
        ? rawItems
        : rawItems
            .where((tx) => tx['paymentMethod'] == _method)
            .toList();

    final total = items.fold<double>(
        0,
        (sum, tx) =>
            sum +
            (double.tryParse(tx['totalAmount']?.toString() ?? '0') ?? 0));
    final byMethod = _computeByMethod(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des ventes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterZone(context),
          if (!_loading && _error == null && items.isNotEmpty)
            _buildSummaryZone(context, items.length, total, byMethod),
          Expanded(child: _buildBody(items, canReturn: canReturn)),
        ],
      ),
    );
  }

  // ── Zone 1: Filters ────────────────────────────────────────────────────────

  Widget _buildFilterZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                    label: "Aujourd'hui",
                    key_: 'today',
                    selected: _periodKey == 'today',
                    onTap: () => _selectPeriod('today')),
                const SizedBox(width: 6),
                _PeriodChip(
                    label: '7 jours',
                    key_: '7d',
                    selected: _periodKey == '7d',
                    onTap: () => _selectPeriod('7d')),
                const SizedBox(width: 6),
                _PeriodChip(
                    label: '30 jours',
                    key_: '30d',
                    selected: _periodKey == '30d',
                    onTap: () => _selectPeriod('30d')),
                const SizedBox(width: 6),
                _PeriodChip(
                    label: _periodKey == 'custom' && _dateRange != null
                        ? '${DateFormat('dd/MM').format(_dateRange!.start)} – ${DateFormat('dd/MM').format(_dateRange!.end)}'
                        : 'Personnalisé',
                    key_: 'custom',
                    selected: _periodKey == 'custom',
                    onTap: _pickCustomRange),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search field
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'N° vente, client, produit…',
                prefixIcon:
                    const Icon(Icons.search, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _load();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
              ),
              onSubmitted: (v) {
                setState(() => _search = v.trim());
                _load();
              },
              onChanged: (v) {
                if (v.isEmpty) {
                  setState(() => _search = '');
                  _load();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          // Payment method chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MethodChip(
                    label: 'Tous',
                    selected: _method == null,
                    onTap: () => _setMethod(null)),
                const SizedBox(width: 6),
                ...(ref.watch(enabledPaymentMethodsProvider).valueOrNull ?? kDefaultPaymentMethods).map((m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _MethodChip(
                          label: _methodLabel(m),
                          selected: _method == m,
                          onTap: () => _setMethod(m)),
                    )),
              ],
            ),
          ),
          // Cashier dropdown — only for owner/manager when users are loaded
          if (widget.fixedUserId == null && _cashierMap.isNotEmpty) ...[
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Caissier',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _cashierId,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tous les caissiers'),
                    ),
                    ..._cashierMap.entries.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _cashierId = v;
                      _data = null;
                    });
                    _load();
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectPeriod(String key) {
    setState(() {
      _periodKey = key;
      _applyPeriod(key);
    });
    _load(); // _load snapshots _dateRange after setState has run
  }

  void _setMethod(String? m) {
    setState(() {
      _method = m;
      _data = null; // clear stale results immediately for instant visual feedback
    });
    _load();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _periodKey = 'custom';
        _dateRange = picked;
      });
      _load();
    }
  }

  // ── Zone 2: Summary ────────────────────────────────────────────────────────

  Widget _buildSummaryZone(BuildContext context, int count, double total,
      Map<String, double> byMethod) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count vente${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(_fcfa(total),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: byMethod.entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _methodColor(e.key).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_methodLabel(e.key)} ${_fcfa(e.value)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: _methodColor(e.key),
                        fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone 3: List ──────────────────────────────────────────────────────────

  Widget _buildBody(List<dynamic> items, {required bool canReturn}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur : $_error',
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('Aucune vente sur cette période.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final entries = _buildEntries(items);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        if (entry.isHeader) {
          return _DayHeader(date: entry.date!);
        }
        return _TxCard(
          tx: entry.tx!,
          date: entry.date!,
          cashierName: _resolveCashierName(entry.tx!),
          canReturn: canReturn,
          onReceipt: () => _showReceipt(context, entry.tx!),
          onReturn: () => _startReturn(context, entry.tx!),
        );
      },
    );
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> tx) {
    showDialog<void>(
      context: context,
      builder: (_) => _TxReceiptDialog(tx: tx),
    );
  }

  void _startReturn(BuildContext context, Map<String, dynamic> tx) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ReturnSearchSheet(initialTransaction: tx),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final String key_;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(
      {required this.label,
      required this.key_,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  const _DayHeader({required this.date});

  static const _frDays = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];
  static const _frMonths = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = "Aujourd'hui";
    } else if (d == yesterday) {
      label = 'Hier';
    } else {
      final dayName = _frDays[date.weekday - 1];
      final monthName = _frMonths[date.month - 1];
      label = '$dayName ${date.day} $monthName';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final DateTime date;
  final VoidCallback onReceipt;
  final VoidCallback onReturn;
  final String? cashierName;
  final bool canReturn;

  const _TxCard({
    required this.tx,
    required this.date,
    required this.onReceipt,
    required this.onReturn,
    required this.canReturn,
    this.cashierName,
  });

  @override
  Widget build(BuildContext context) {
    final retailSale = tx['retailSale'] as Map<String, dynamic>?;
    final receiptNumber = retailSale?['receiptNumber']?.toString();
    final method = tx['paymentMethod'] as String?;
    final amount =
        double.tryParse(tx['totalAmount']?.toString() ?? '0') ?? 0;
    final items = (tx['itemsJson'] as List<dynamic>?) ?? [];
    final customer = tx['customer'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: receipt# + time + amount
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiptNumber != null
                            ? 'Reçu #$receiptNumber'
                            : 'TX #${tx['id']?.toString().substring(0, 8) ?? '—'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        [
                          DateFormat('HH:mm').format(date.toLocal()),
                          if (cashierName case final String n) n,
                        ].join(' · '),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fcfa(amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _methodColor(method).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _methodLabel(method),
                        style: TextStyle(
                            fontSize: 10,
                            color: _methodColor(method),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (customer != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    customer['name']?.toString() ?? '—',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (customer['phone'] != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      customer['phone'].toString(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildItemsSummary(items),
            ],
            const SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReceipt,
                  icon: const Icon(Icons.receipt_long_outlined, size: 14),
                  label: const Text('Reçu'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                if (canReturn) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.undo_outlined, size: 14),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSummary(List<dynamic> items) {
    const maxShow = 2;
    final shown = items.take(maxShow).toList();
    final extra = items.length - maxShow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...shown.map((it) {
          final name = it['name']?.toString() ??
              it['catalogItemId']?.toString() ??
              '—';
          final qty = it['quantity']?.toString() ?? '1';
          return Text(
            '× $qty  $name',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        if (extra > 0)
          Text('+ $extra autre${extra > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Receipt dialog ─────────────────────────────────────────────────────────────

class _TxReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxReceiptDialog({required this.tx});

  @override
  Widget build(BuildContext context) {
    final retailSale = tx['retailSale'] as Map<String, dynamic>?;
    final receiptNumber = retailSale?['receiptNumber']?.toString();
    final method = tx['paymentMethod'] as String?;
    final amount =
        double.tryParse(tx['totalAmount']?.toString() ?? '0') ?? 0;
    final items = (tx['itemsJson'] as List<dynamic>?) ?? [];
    final customer = tx['customer'] as Map<String, dynamic>?;
    final raw = tx['createdAt']?.toString() ?? '';
    final dt = raw.isEmpty
        ? DateTime.now()
        : (DateTime.tryParse(raw) ?? DateTime.now()).toLocal();

    return AlertDialog(
      title: const Center(child: Text('Reçu')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              if (receiptNumber != null)
                _row('N° reçu :', receiptNumber),
              _row('Date :',
                  DateFormat('dd/MM/yyyy HH:mm').format(dt)),
              if (customer != null) ...[
                _row('Client :', customer['name']?.toString() ?? '—'),
                if (customer['phone'] != null)
                  _row('Tél :', customer['phone'].toString()),
              ],
              _row('Paiement :', _methodLabel(method)),
              const Divider(),
              ...items.map((it) {
                final name = it['name']?.toString() ??
                    it['catalogItemId']?.toString() ??
                    '—';
                final qty =
                    (it['quantity'] as num?)?.toInt() ?? 1;
                final price = double.tryParse(
                        (it['unitPrice'] ?? it['price'])?.toString() ??
                            '0') ??
                    0;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('$name × $qty',
                              style: const TextStyle(fontSize: 13))),
                      Text(_fcfa(price * qty),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  Text(_fcfa(amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(value),
          ],
        ),
      );
}

// ── Internal data model ────────────────────────────────────────────────────────

class _ListEntry {
  final bool isHeader;
  final Map<String, dynamic>? tx;
  final DateTime? date;

  const _ListEntry._({required this.isHeader, this.tx, this.date});

  factory _ListEntry.header(String _, DateTime date) =>
      _ListEntry._(isHeader: true, date: date);
  factory _ListEntry.tx(Map<String, dynamic> tx, DateTime date) =>
      _ListEntry._(isHeader: false, tx: tx, date: date);
}
