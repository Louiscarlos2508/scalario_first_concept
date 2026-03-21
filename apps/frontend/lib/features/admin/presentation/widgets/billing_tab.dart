import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../data/services/invoice_service.dart';
import '../providers/admin_providers.dart';

// ── Main widget ───────────────────────────────────────────────────────────────

class BillingTab extends ConsumerWidget {
  final String tenantId;

  const BillingTab({super.key, required this.tenantId});

  String get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(tenantBillingProvider(tenantId));
    final plansAsync = ref.watch(planDefinitionsProvider);

    return billingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (data) {
        final tenant = data['tenant'] as Map<String, dynamic>;
        final events = (data['events'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final plans = plansAsync.valueOrNull ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Plan & Abonnement ─────────────────────────────────
            _SectionCard(
              title: 'Plan & Abonnement',
              child: _PlanSubscriptionSection(
                tenantId: tenantId,
                tenant: tenant,
                plans: plans,
                token: _token,
                ref: ref,
              ),
            ),
            const SizedBox(height: 12),

            // ── Section 2: Frais ponctuels ────────────────────────────────────
            _SectionCard(
              title: 'Frais ponctuels',
              child: _FeesSection(
                tenantId: tenantId,
                tenant: tenant,
                events: events,
                token: _token,
                ref: ref,
              ),
            ),
            const SizedBox(height: 12),

            // ── Section 3: Historique ─────────────────────────────────────────
            _SectionCard(
              title: 'Historique',
              action: OutlinedButton.icon(
                onPressed: () => _generateInvoice(context, ref),
                icon: const Icon(Icons.description, size: 14),
                label: const Text('Facture'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              child: events.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aucun événement de facturation'),
                    )
                  : Column(
                      children: events
                          .map((e) => _BillingEventRow(
                                event: e,
                                tenantId: tenantId,
                                token: _token,
                                ref: ref,
                              ))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateInvoice(BuildContext context, WidgetRef ref) async {
    try {
      final invoiceData = await ref
          .read(adminApiServiceProvider)
          .generateInvoice(tenantId, token: _token);
      ref.invalidate(tenantBillingProvider(tenantId));
      ref.invalidate(allBillingEventsProvider);
      await InvoiceService.generateAndDownloadInvoice(invoiceData);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Section 1: Plan & Abonnement ──────────────────────────────────────────────

class _PlanSubscriptionSection extends StatelessWidget {
  final String tenantId;
  final Map<String, dynamic> tenant;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _PlanSubscriptionSection({
    required this.tenantId,
    required this.tenant,
    required this.plans,
    required this.token,
    required this.ref,
  });

  Map<String, dynamic>? get _planDef {
    final code = tenant['plan'] as String? ?? '';
    return plans.where((p) => p['code'] == code).firstOrNull;
  }

  String _fmt(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    return NumberFormat('#,###', 'fr_FR').format(n);
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : iso;
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'trial' => (Colors.blue, 'Essai'),
      'active' => (Colors.green, 'Actif'),
      'overdue' => (Colors.orange, 'En retard'),
      'suspended' => (Colors.red, 'Suspendu'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _dateInfo(String status) {
    final trialEndsAt = tenant['trialEndsAt'] as String?;
    final paidUntil = tenant['paidUntil'] as String?;
    final now = DateTime.now();

    switch (status) {
      case 'trial':
        if (trialEndsAt != null) {
          final dt = DateTime.tryParse(trialEndsAt);
          if (dt != null) {
            final days = dt.difference(now).inDays;
            final color = days <= 3 ? Colors.red : Colors.blue;
            return Text(
              'Essai jusqu\'au ${_fmtDate(trialEndsAt)} ($days j restants)',
              style: TextStyle(color: color, fontSize: 13),
            );
          }
        }
        return const Text('Essai en cours',
            style: TextStyle(color: Colors.blue, fontSize: 13));

      case 'active':
        if (paidUntil != null) {
          final dt = DateTime.tryParse(paidUntil);
          if (dt != null) {
            final days = dt.difference(now).inDays;
            final color = days <= 3
                ? Colors.red
                : (days <= 7 ? Colors.orange : Colors.green);
            return Text(
              'Payé jusqu\'au ${_fmtDate(paidUntil)} ($days j)',
              style: TextStyle(color: color, fontSize: 13),
            );
          }
        }
        return const Text('Actif',
            style: TextStyle(color: Colors.green, fontSize: 13));

      case 'overdue':
        if (paidUntil != null) {
          final dt = DateTime.tryParse(paidUntil);
          if (dt != null) {
            final days = now.difference(dt).inDays;
            return Text(
              'Impayé depuis $days j (dû depuis ${_fmtDate(paidUntil)})',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            );
          }
        }
        return const Text('Impayé',
            style: TextStyle(color: Colors.orange, fontSize: 13));

      case 'suspended':
        return const Text('Compte suspendu',
            style: TextStyle(color: Colors.red, fontSize: 13));

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _openPaymentDialog(BuildContext context) async {
    final receiptData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PaymentDialog(
        tenantId: tenantId,
        tenant: tenant,
        plans: plans,
        token: token,
        ref: ref,
      ),
    );
    if (receiptData == null || !context.mounted) return;

    ref.invalidate(tenantBillingProvider(tenantId));
    ref.invalidate(adminTenantsProvider);
    ref.invalidate(billingSummaryProvider);
    ref.invalidate(adminMonitoringProvider);
    ref.invalidate(allBillingEventsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Paiement enregistré — Génération du reçu...'),
          action: SnackBarAction(
            label: 'Reçu',
            onPressed: () =>
                InvoiceService.generateAndDownloadReceipt(receiptData),
          ),
        ),
      );
      await InvoiceService.generateAndDownloadReceipt(receiptData);
    }
  }

  Future<void> _openPlanChangeDialog(BuildContext context) async {
    final currentPlan = tenant['plan'] as String? ?? '';
    await showDialog<void>(
      context: context,
      builder: (_) => _PlanChangeDialog(
        tenantId: tenantId,
        currentPlan: currentPlan,
        plans: plans,
        token: token,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = tenant['billingStatus'] as String? ?? 'trial';
    final planCode = tenant['plan'] as String? ?? 'free';
    final plan = _planDef;
    final planName = plan?['name'] as String? ?? planCode;
    final planPrice = double.tryParse(
            (plan?['monthlyPrice'] ?? plan?['monthly_price'] ?? 0).toString()) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if (planPrice > 0)
                    Text('${_fmt(planPrice)} FCFA/mois',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            _statusBadge(status),
          ],
        ),
        const SizedBox(height: 8),
        _dateInfo(status),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _openPlanChangeDialog(context),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Changer de plan'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _openPaymentDialog(context),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Enregistrer paiement'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Payment Dialog ────────────────────────────────────────────────────────────

class _PaymentDialog extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic> tenant;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _PaymentDialog({
    required this.tenantId,
    required this.tenant,
    required this.plans,
    required this.token,
    required this.ref,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  int _months = 1;
  bool _libre = false;
  final _libreCtrl = TextEditingController(text: '1');
  final _amountCtrl = TextEditingController();
  String _method = 'cash';
  final _refCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _includeInstallation = false;
  bool _includeTraining = false;
  bool _loading = false;

  double get _planPrice {
    final planCode = widget.tenant['plan'] as String? ?? '';
    final plan = widget.plans.where((p) => p['code'] == planCode).firstOrNull;
    if (plan == null) return 0;
    return double.tryParse(
            (plan['monthlyPrice'] ?? plan['monthly_price'] ?? 0).toString()) ??
        0;
  }

  int get _effectiveMonths {
    if (_libre) return int.tryParse(_libreCtrl.text) ?? 1;
    return _months;
  }

  double get _subscriptionAmount =>
      double.tryParse(_amountCtrl.text.replaceAll('\u202f', '').replaceAll(' ', '')) ?? 0;

  double get _installationFee =>
      double.tryParse(
          (widget.tenant['installationFee'] ?? '0').toString()) ??
          0;

  double get _trainingFee =>
      double.tryParse(
          (widget.tenant['trainingFee'] ?? '0').toString()) ??
          0;

  bool get _installationPaid =>
      widget.tenant['installationPaid'] as bool? ?? false;

  bool get _trainingPaid =>
      widget.tenant['trainingPaid'] as bool? ?? false;

  bool get _showInstallCheckbox => _installationFee > 0 && !_installationPaid;

  bool get _showTrainingCheckbox => _trainingFee > 0 && !_trainingPaid;

  double get _total {
    double t = _subscriptionAmount;
    if (_includeInstallation) t += _installationFee;
    if (_includeTraining) t += _trainingFee;
    return t;
  }

  void _updateAmount() {
    _amountCtrl.text = (_planPrice * _effectiveMonths).toStringAsFixed(0);
  }

  (DateTime, DateTime) _calcPeriod() {
    final status = widget.tenant['billingStatus'] as String? ?? 'trial';
    final trialEndsAtStr = widget.tenant['trialEndsAt'] as String?;
    final paidUntilStr = widget.tenant['paidUntil'] as String?;
    final now = DateTime.now();

    DateTime start;
    if (status == 'trial' && trialEndsAtStr != null) {
      final trialEndsAt = DateTime.tryParse(trialEndsAtStr);
      if (trialEndsAt != null && trialEndsAt.isAfter(now)) {
        start = trialEndsAt.add(const Duration(days: 1));
      } else {
        start = now;
      }
    } else if (paidUntilStr != null) {
      final paidUntil = DateTime.tryParse(paidUntilStr);
      start = (paidUntil != null && paidUntil.isAfter(now)) ? paidUntil : now;
    } else {
      start = now;
    }

    return (start, start.add(Duration(days: _effectiveMonths * 30)));
  }

  @override
  void initState() {
    super.initState();
    _updateAmount();
    _libreCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _libreCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  String _fmtAmount(double v) =>
      '${NumberFormat('#,###', 'fr_FR').format(v)} FCFA';

  Future<void> _submit() async {
    setState(() => _loading = true);
    final (start, end) = _calcPeriod();
    final description =
        'Abonnement — $_effectiveMonths mois — du ${_fmtDate(start)} au ${_fmtDate(end)}';

    try {
      final receiptData =
          await widget.ref.read(adminApiServiceProvider).recordPayment(
                widget.tenantId,
                months: _effectiveMonths,
                amount: _subscriptionAmount.toStringAsFixed(0),
                description: description,
                paymentMethod: _method,
                paymentRef: _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
                paymentDate: _date.toIso8601String(),
                includeInstallation: _includeInstallation,
                includeTraining: _includeTraining,
                token: widget.token,
              );
      if (mounted) Navigator.pop(context, receiptData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _calcPeriod();

    return AlertDialog(
      title: const Text('Enregistrer un paiement'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Months selector
              const Text('Durée :',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  ...[1, 3, 6, 12].map((m) => ChoiceChip(
                        label: Text('$m mois'),
                        selected: !_libre && _months == m,
                        onSelected: (_) => setState(() {
                          _libre = false;
                          _months = m;
                          _updateAmount();
                        }),
                      )),
                  ChoiceChip(
                    label: const Text('Libre'),
                    selected: _libre,
                    onSelected: (_) => setState(() {
                      _libre = true;
                      _updateAmount();
                    }),
                  ),
                ],
              ),
              if (_libre) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _libreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de mois',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'mois',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    setState(() {});
                    _updateAmount();
                  },
                ),
              ],
              const SizedBox(height: 12),

              // Subscription amount (editable)
              TextField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Montant abonnement (FCFA)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Modifiable si remise accordée',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),

              // Period display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Du ${_fmtDate(start)} au ${_fmtDate(end)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment method
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Méthode de paiement',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _method,
                    isDense: true,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                      DropdownMenuItem(
                          value: 'mobile_money', child: Text('Mobile Money')),
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Virement')),
                    ],
                    onChanged: (v) => setState(() => _method = v ?? _method),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reference
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Référence (optionnel)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Payment date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de paiement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(_fmtDate(_date)),
                ),
              ),

              // Fee checkboxes (only if applicable)
              if (_showInstallCheckbox || _showTrainingCheckbox) ...[
                const SizedBox(height: 12),
                const Text('Frais inclus :',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                if (_showInstallCheckbox)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _includeInstallation,
                    onChanged: (v) =>
                        setState(() => _includeInstallation = v ?? false),
                    title:
                        Text('Installation — ${_fmtAmount(_installationFee)}'),
                  ),
                if (_showTrainingCheckbox)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _includeTraining,
                    onChanged: (v) =>
                        setState(() => _includeTraining = v ?? false),
                    title: Text('Formation — ${_fmtAmount(_trainingFee)}'),
                  ),
              ],

              // Total (shown when fees are included)
              if (_includeInstallation || _includeTraining) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_fmtAmount(_total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Valider et générer reçu'),
        ),
      ],
    );
  }
}

// ── Plan Change Dialog ────────────────────────────────────────────────────────

class _PlanChangeDialog extends StatefulWidget {
  final String tenantId;
  final String currentPlan;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _PlanChangeDialog({
    required this.tenantId,
    required this.currentPlan,
    required this.plans,
    required this.token,
    required this.ref,
  });

  @override
  State<_PlanChangeDialog> createState() => _PlanChangeDialogState();
}

class _PlanChangeDialogState extends State<_PlanChangeDialog> {
  late String _selected;
  bool _loading = false;

  List<Map<String, dynamic>> get _visiblePlans => widget.plans
      .where((p) =>
          (double.tryParse(
                  (p['monthlyPrice'] ?? p['monthly_price'] ?? 0).toString()) ??
              0) >
          0)
      .toList();

  @override
  void initState() {
    super.initState();
    final others =
        _visiblePlans.where((p) => p['code'] != widget.currentPlan).toList();
    _selected =
        others.isNotEmpty ? others.first['code'] as String : widget.currentPlan;
  }

  Map<String, dynamic>? get _currentPlanDef =>
      widget.plans.where((p) => p['code'] == widget.currentPlan).firstOrNull;

  Map<String, dynamic>? get _newPlanDef =>
      widget.plans.where((p) => p['code'] == _selected).firstOrNull;

  List<String> _modules(Map<String, dynamic>? plan) =>
      ((plan?['includedModules'] ?? plan?['included_modules'] ?? []) as List)
          .cast<String>();

  List<String> get _toActivate {
    final cur = _modules(_currentPlanDef);
    return _modules(_newPlanDef).where((m) => !cur.contains(m)).toList();
  }

  List<String> get _toDeactivate {
    final next = _modules(_newPlanDef);
    return _modules(_currentPlanDef).where((m) => !next.contains(m)).toList();
  }

  String _fmtPrice(Map<String, dynamic>? plan) {
    if (plan == null) return '—';
    final v = plan['monthlyPrice'] ?? plan['monthly_price'] ?? 0;
    final n = double.tryParse(v.toString()) ?? 0;
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA/mois';
  }

  Future<void> _confirm(BuildContext context) async {
    if (_selected == widget.currentPlan) {
      Navigator.pop(context);
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.ref.read(adminApiServiceProvider).assignPlan(
            widget.tenantId,
            _selected,
            confirmDowngrade: _toDeactivate.isNotEmpty,
            token: widget.token,
          );
      widget.ref.invalidate(tenantBillingProvider(widget.tenantId));
      widget.ref.invalidate(adminTenantsProvider);
      widget.ref.invalidate(billingSummaryProvider);
      widget.ref.invalidate(adminMonitoringProvider);
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Plan changé vers $_selected ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final others =
        _visiblePlans.where((p) => p['code'] != widget.currentPlan).toList();

    if (others.isEmpty) {
      return AlertDialog(
        title: const Text('Changer de plan'),
        content: const Text('Aucun autre plan disponible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      );
    }

    final toActivate = _toActivate;
    final toDeactivate = _toDeactivate;

    return AlertDialog(
      title: const Text('Changer de plan'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan actuel : ${widget.currentPlan}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Nouveau plan',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selected,
                  isDense: true,
                  isExpanded: true,
                  items: others
                      .map((p) => DropdownMenuItem<String>(
                            value: p['code'] as String,
                            child: Text(
                                p['name'] as String? ?? p['code'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v ?? _selected),
                ),
              ),
            ),
            if (toActivate.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Modules activés :',
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ...toActivate.map((m) => Text('+ $m',
                  style: const TextStyle(color: Colors.green, fontSize: 13))),
            ],
            if (toDeactivate.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Modules désactivés :',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                      fontSize: 13)),
              ...toDeactivate.map((m) => Text('- $m',
                  style:
                      const TextStyle(color: Colors.orange, fontSize: 13))),
            ],
            const SizedBox(height: 10),
            Text(
              'Nouveau tarif : ${_fmtPrice(_newPlanDef)} — applicable dès le prochain paiement.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading || _selected == widget.currentPlan
              ? null
              : () => _confirm(context),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}

// ── Section 2: Frais ponctuels ────────────────────────────────────────────────

class _FeesSection extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic> tenant;
  final List<Map<String, dynamic>> events;
  final String token;
  final WidgetRef ref;

  const _FeesSection({
    required this.tenantId,
    required this.tenant,
    required this.events,
    required this.token,
    required this.ref,
  });

  @override
  State<_FeesSection> createState() => _FeesSectionState();
}

class _FeesSectionState extends State<_FeesSection> {
  late TextEditingController _installCtrl;
  late TextEditingController _trainingCtrl;
  late TextEditingController _notesCtrl;

  String _fmtFeeRaw(dynamic v) {
    if (v == null) return '';
    final n = double.tryParse(v.toString()) ?? 0;
    return n > 0 ? n.toStringAsFixed(0) : '';
  }

  @override
  void initState() {
    super.initState();
    _installCtrl = TextEditingController(
        text: _fmtFeeRaw(widget.tenant['installationFee']));
    _trainingCtrl = TextEditingController(
        text: _fmtFeeRaw(widget.tenant['trainingFee']));
    _notesCtrl =
        TextEditingController(text: widget.tenant['notes'] as String? ?? '');
  }

  @override
  void didUpdateWidget(_FeesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenant['installationFee'] != widget.tenant['installationFee']) {
      _installCtrl.text = _fmtFeeRaw(widget.tenant['installationFee']);
    }
    if (oldWidget.tenant['trainingFee'] != widget.tenant['trainingFee']) {
      _trainingCtrl.text = _fmtFeeRaw(widget.tenant['trainingFee']);
    }
    if (oldWidget.tenant['notes'] != widget.tenant['notes']) {
      _notesCtrl.text = widget.tenant['notes'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _installCtrl.dispose();
    _trainingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String field, dynamic value) async {
    try {
      await widget.ref.read(adminApiServiceProvider).updateTenantBilling(
            widget.tenantId,
            {field: value},
            token: widget.token,
          );
      widget.ref.invalidate(tenantBillingProvider(widget.tenantId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fmtDisplayFromEvent(String type, dynamic tenantFee) {
    final n = double.tryParse(tenantFee?.toString() ?? '') ?? 0;
    if (n > 0) return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA';
    // Fallback : chercher le montant dans le billing event correspondant
    final event = widget.events
        .where((e) => e['type'] == type)
        .firstOrNull;
    if (event == null) return '—';
    final en = double.tryParse(event['amount']?.toString() ?? '') ?? 0;
    if (en == 0) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(en)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final installPaid = widget.tenant['installationPaid'] as bool? ?? false;
    final trainingPaid = widget.tenant['trainingPaid'] as bool? ?? false;

    return Column(
      children: [
        _FeeEditRow(
          label: 'Installation',
          displayAmount: _fmtDisplayFromEvent('installation', widget.tenant['installationFee']),
          paid: installPaid,
          onMarkPaid: () => _save('installationPaid', true),
          controller: _installCtrl,
          onSave: (v) {
            final n = double.tryParse(v);
            if (n != null) _save('installationFee', n.toStringAsFixed(2));
          },
        ),
        const SizedBox(height: 6),
        _FeeEditRow(
          label: 'Formation',
          displayAmount: _fmtDisplayFromEvent('training', widget.tenant['trainingFee']),
          paid: trainingPaid,
          onMarkPaid: () => _save('trainingPaid', true),
          controller: _trainingCtrl,
          onSave: (v) {
            final n = double.tryParse(v);
            if (n != null) _save('trainingFee', n.toStringAsFixed(2));
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'ex: remise early adopter 20%',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
          onEditingComplete: () => _save('notes', _notesCtrl.text),
          onTapOutside: (_) => _save('notes', _notesCtrl.text),
        ),
      ],
    );
  }
}

class _FeeEditRow extends StatelessWidget {
  final String label;
  final String displayAmount;
  final bool paid;
  final VoidCallback onMarkPaid;
  final TextEditingController controller;
  final ValueChanged<String> onSave;

  const _FeeEditRow({
    required this.label,
    required this.displayAmount,
    required this.paid,
    required this.onMarkPaid,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
          child: paid
              ? Text(
                  displayAmount == '—' ? 'Payé' : displayAmount,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: displayAmount == '—' ? Colors.green : null),
                )
              : TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Montant',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'FCFA',
                  ),
                  keyboardType: TextInputType.number,
                  onEditingComplete: () => onSave(controller.text),
                  onTapOutside: (_) => onSave(controller.text),
                ),
        ),
        const SizedBox(width: 8),
        if (paid)
          const Icon(Icons.check_circle, color: Colors.green, size: 20)
        else
          TextButton(
            onPressed: onMarkPaid,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child:
                const Text('Marquer payé', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

// ── BillingEvent row ──────────────────────────────────────────────────────────

class _BillingEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final String tenantId;
  final String token;
  final WidgetRef ref;

  const _BillingEventRow({
    required this.event,
    required this.tenantId,
    required this.token,
    required this.ref,
  });

  Color _statusColor(String status) => switch (status) {
        'paid' => Colors.green,
        'overdue' => Colors.orange,
        'cancelled' => Colors.grey,
        _ => Colors.blue,
      };

  String _statusLabel(String status) => switch (status) {
        'paid' => 'Payé',
        'overdue' => 'En retard',
        'cancelled' => 'Annulé',
        'completed' => 'Effectué',
        _ => 'En attente',
      };

  String _typeLabel(String type) => switch (type) {
        'subscription' => 'Abonnement',
        'installation' => 'Installation',
        'training' => 'Formation',
        'activation' => 'Activation',
        'plan_change' => 'Changement de plan',
        'invoice' => 'Facture',
        _ => type,
      };

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    return dt != null ? DateFormat('dd/MM/yy').format(dt) : iso;
  }

  String _formatAmount(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    if (n == 0) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA';
  }

  Future<void> _markPaid(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MarkPaidDialog(),
    );
    if (result == null || !context.mounted) return;

    try {
      final receiptData = await ref.read(adminApiServiceProvider).generateReceipt(
            event['id'] as String,
            paymentMethod: result['paymentMethod'] as String,
            paymentRef: result['paymentRef'] as String?,
            paymentDate: result['paymentDate'] as String?,
            token: token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
      ref.invalidate(adminTenantsProvider);
      ref.invalidate(billingSummaryProvider);
      ref.invalidate(adminMonitoringProvider);
      ref.invalidate(allBillingEventsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paiement enregistré — Génération du reçu...'),
            action: SnackBarAction(
              label: 'Télécharger',
              onPressed: () =>
                  InvoiceService.generateAndDownloadReceipt(receiptData),
            ),
          ),
        );
        await InvoiceService.generateAndDownloadReceipt(receiptData);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = event['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final type = event['type'] as String? ?? '';
    final invoiceNumber = event['invoiceNumber'] as String?;
    final receiptNumber = event['receiptNumber'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color),
              ),
              child: Text(_statusLabel(status),
                  style: TextStyle(color: color, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_typeLabel(type)} — ${_formatAmount(event['amount'])}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    [
                      _formatDate(event['createdAt'] as String?),
                      if (invoiceNumber case final String n) n,
                      if (receiptNumber case final String r) r,
                      if (event['description'] != null &&
                          (event['description'] as String).isNotEmpty)
                        event['description'] as String,
                    ].join(' • '),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (invoiceNumber != null)
                  IconButton(
                    icon: const Icon(Icons.description, size: 18),
                    tooltip: 'Facture',
                    onPressed: () => _redownloadInvoice(),
                  ),
                if (receiptNumber != null)
                  IconButton(
                    icon: const Icon(Icons.receipt, size: 18),
                    tooltip: 'Reçu',
                    onPressed: () => _redownloadReceipt(),
                  ),
                if (status == 'pending')
                  TextButton(
                    onPressed: () => _markPaid(context),
                    child: const Text('Marquer payé',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _redownloadInvoice() {
    InvoiceService.generateAndDownloadInvoice({
      'invoiceNumber': event['invoiceNumber'],
      'date': event['createdAt'],
      'tenant': {'name': ''},
      'plan': {'code': '', 'name': ''},
      'lines': [
        {
          'description': event['description'] ?? event['type'],
          'amount':
              double.tryParse(event['amount']?.toString() ?? '0') ?? 0,
        }
      ],
      'total': double.tryParse(event['amount']?.toString() ?? '0') ?? 0,
    });
  }

  void _redownloadReceipt() {
    InvoiceService.generateAndDownloadReceipt({
      'receiptNumber': event['receiptNumber'],
      'invoiceNumber': event['invoiceNumber'],
      'date': event['paidAt'] ?? event['createdAt'],
      'tenant': {'name': ''},
      'amount': double.tryParse(event['amount']?.toString() ?? '0') ?? 0,
      'description': event['description'] ?? event['type'],
      'paymentMethod': event['paymentMethod'] ?? '',
      'paymentRef': event['paymentRef'],
    });
  }
}

// ── Mark Paid Dialog ──────────────────────────────────────────────────────────

class _MarkPaidDialog extends StatefulWidget {
  const _MarkPaidDialog();

  @override
  State<_MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<_MarkPaidDialog> {
  String _method = 'cash';
  final _refCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer le paiement'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Méthode',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _method,
                  isDense: true,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(
                        value: 'mobile_money', child: Text('Mobile Money')),
                    DropdownMenuItem(
                        value: 'bank_transfer', child: Text('Virement')),
                  ],
                  onChanged: (v) => setState(() => _method = v ?? _method),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                  labelText: 'Référence transaction (optionnel)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date de paiement',
                    border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'paymentMethod': _method,
            'paymentRef':
                _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
            'paymentDate': _date.toIso8601String(),
          }),
          child: const Text('Confirmer et générer reçu'),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (action case final Widget a) a,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
