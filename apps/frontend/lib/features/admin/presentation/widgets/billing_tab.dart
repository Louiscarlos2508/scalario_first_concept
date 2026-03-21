import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../data/services/invoice_service.dart';
import '../providers/admin_providers.dart';

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

        final billingStatus = tenant['billingStatus'] as String? ?? 'trial';
        final currentPlan = tenant['plan'] as String? ?? 'free';

        final plans = plansAsync.valueOrNull ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section Plan actuel ──────────────────────────────────────────
            _SectionCard(
              title: 'Plan actuel',
              child: _PlanSection(
                tenantId: tenantId,
                currentPlan: currentPlan,
                plans: plans,
                token: _token,
                ref: ref,
              ),
            ),
            const SizedBox(height: 12),

            // ── Section Période d'essai ──────────────────────────────────────
            _SectionCard(
              title: "Période d'essai",
              child: _TrialSection(
                tenantId: tenantId,
                billingStatus: billingStatus,
                trialEndsAt: tenant['trialEndsAt'] as String?,
                currentPlan: currentPlan,
                plans: plans,
                token: _token,
                ref: ref,
              ),
            ),
            const SizedBox(height: 12),

            // ── Section paidUntil ────────────────────────────────────────────
            if (tenant['billingStatus'] == 'active' && tenant['paidUntil'] != null)
              _PaidUntilCard(
                paidUntil: tenant['paidUntil'] as String,
                tenantId: tenantId,
                plans: plans,
                token: _token,
                ref: ref,
              ),
            if (tenant['billingStatus'] == 'active' && tenant['paidUntil'] != null)
              const SizedBox(height: 12),

            // ── Section Frais ────────────────────────────────────────────────
            _SectionCard(
              title: 'Frais',
              child: _FeesSection(
                tenantId: tenantId,
                tenant: tenant,
                token: _token,
                ref: ref,
              ),
            ),
            const SizedBox(height: 12),

            // ── Section Historique paiements ─────────────────────────────────
            _SectionCard(
              title: 'Historique paiements',
              action: FilledButton.icon(
                onPressed: () => _showAddPaymentDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6)),
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
            const SizedBox(height: 12),

            // ── Section Générer facture ───────────────────────────────────────
            _SectionCard(
              title: 'Facturation',
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _generateInvoice(context, ref),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('Générer facture du mois'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPaymentDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddPaymentDialog(),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(adminApiServiceProvider).recordBillingEvent(
            tenantId,
            result,
            token: _token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateInvoice(BuildContext context, WidgetRef ref) async {
    try {
      final invoiceData = await ref
          .read(adminApiServiceProvider)
          .generateInvoice(tenantId, token: _token);
      ref.invalidate(tenantBillingProvider(tenantId));
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

// ── Section Plan actuel ────────────────────────────────────────────────────────

class _PlanSection extends StatefulWidget {
  final String tenantId;
  final String currentPlan;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _PlanSection({
    required this.tenantId,
    required this.currentPlan,
    required this.plans,
    required this.token,
    required this.ref,
  });

  @override
  State<_PlanSection> createState() => _PlanSectionState();
}

class _PlanSectionState extends State<_PlanSection> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _resolveSelection(widget.currentPlan, widget.plans);
  }

  String _resolveSelection(String plan, List<Map<String, dynamic>> plans) {
    final codes = plans.map((p) => p['code'] as String).toList();
    if (codes.contains(plan)) return plan;
    return codes.isNotEmpty ? codes.first : plan;
  }

  @override
  void didUpdateWidget(_PlanSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPlan != widget.currentPlan) {
      _selected = _resolveSelection(widget.currentPlan, widget.plans);
    }
  }

  String _planLabel(String code) {
    final plan = widget.plans.where((p) => p['code'] == code).firstOrNull;
    if (plan == null) return code;
    final price = plan['monthlyPrice'] ?? plan['monthly_price'] ?? 0;
    return '${plan['name']} — ${_fmt(price)} FCFA/mois';
  }

  String _fmt(dynamic v) {
    final n = double.tryParse(v.toString()) ?? 0;
    return NumberFormat('#,###', 'fr_FR').format(n);
  }

  Future<void> _changePlan(BuildContext context) async {
    if (_selected == widget.currentPlan) return;

    final currentPlan = widget.plans
        .where((p) => p['code'] == widget.currentPlan)
        .firstOrNull;
    final newPlan =
        widget.plans.where((p) => p['code'] == _selected).firstOrNull;
    if (newPlan == null) return;

    final currentPrice =
        double.tryParse((currentPlan?['monthlyPrice'] ?? currentPlan?['monthly_price'] ?? 0).toString()) ?? 0;
    final newPrice =
        double.tryParse((newPlan['monthlyPrice'] ?? newPlan['monthly_price'] ?? 0).toString()) ?? 0;
    final isUpgrade = newPrice >= currentPrice;

    final newModules = (newPlan['includedModules'] ?? newPlan['included_modules'] ?? []) as List;
    final currentModules = (currentPlan?['includedModules'] ?? currentPlan?['included_modules'] ?? []) as List;

    final toActivate = newModules.where((m) => !currentModules.contains(m)).toList();
    final toDeactivate = currentModules.where((m) => !newModules.contains(m)).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isUpgrade ? 'Upgrade vers $_selected' : 'Downgrade vers $_selected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toActivate.isNotEmpty) ...[
              const Text('Modules qui seront activés :',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...toActivate.map((m) => Text('+ $m',
                  style: const TextStyle(color: Colors.green))),
              const SizedBox(height: 8),
            ],
            if (toDeactivate.isNotEmpty) ...[
              const Text('Modules qui seront désactivés :',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
              ...toDeactivate.map((m) => Text('- $m',
                  style: const TextStyle(color: Colors.orange))),
              const SizedBox(height: 8),
            ],
            Text('Abonnement mensuel : ${_fmt(newPrice)} FCFA'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await widget.ref.read(adminApiServiceProvider).assignPlan(
            widget.tenantId,
            _selected,
            confirmDowngrade: !isUpgrade,
            token: widget.token,
          );
      widget.ref.invalidate(tenantBillingProvider(widget.tenantId));
      widget.ref.invalidate(adminTenantsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isUpgrade
                  ? 'Plan mis à jour — upgrade vers $_selected'
                  : 'Plan mis à jour — downgrade vers $_selected')),
        );
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
    if (widget.plans.isEmpty) {
      return Text(widget.currentPlan,
          style: const TextStyle(fontWeight: FontWeight.bold));
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Plan',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: widget.plans
                .map((p) => DropdownMenuItem<String>(
                      value: p['code'] as String,
                      child: Text(_planLabel(p['code'] as String)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _selected == widget.currentPlan
              ? null
              : () => _changePlan(context),
          child: const Text('Changer'),
        ),
      ],
    );
  }
}

// ── Section Période d'essai ───────────────────────────────────────────────────

class _TrialSection extends StatelessWidget {
  final String tenantId;
  final String billingStatus;
  final String? trialEndsAt;
  final String currentPlan;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _TrialSection({
    required this.tenantId,
    required this.billingStatus,
    required this.trialEndsAt,
    required this.currentPlan,
    required this.plans,
    required this.token,
    required this.ref,
  });

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _convertToActive(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ActivateDialog(
        currentPlan: currentPlan,
        plans: plans,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(adminApiServiceProvider).activateTenant(
            tenantId,
            planCode: result['planCode'] as String,
            installationFee: result['installationFee'] as double?,
            trainingFee: result['trainingFee'] as double?,
            billingStartDate: result['billingStartDate'] as String?,
            token: token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
      ref.invalidate(adminTenantsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client activé ✓')),
        );
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
    if (billingStatus == 'trial') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: const Text('Essai en cours',
                    style: TextStyle(color: Colors.blue, fontSize: 12)),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                side: const BorderSide(color: Colors.blue),
              ),
              if (trialEndsAt != null) ...[
                const SizedBox(width: 8),
                Text('jusqu\'au ${_formatDate(trialEndsAt!)}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _convertToActive(context),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Convertir en client payant'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    }
    return const Text('—',
        style: TextStyle(color: Colors.grey, fontSize: 14));
  }
}

// ── Dialog activation trial → payant ─────────────────────────────────────────

class _ActivateDialog extends StatefulWidget {
  final String currentPlan;
  final List<Map<String, dynamic>> plans;

  const _ActivateDialog({required this.currentPlan, required this.plans});

  @override
  State<_ActivateDialog> createState() => _ActivateDialogState();
}

class _ActivateDialogState extends State<_ActivateDialog> {
  late String _plan;
  final _installCtrl = TextEditingController();
  final _trainingCtrl = TextEditingController();
  DateTime _billingStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    final codes = widget.plans.map((p) => p['code'] as String).toList();
    if (widget.plans.isEmpty) {
      _plan = widget.currentPlan;
    } else if (!codes.contains(widget.currentPlan) || widget.currentPlan == 'free') {
      _plan = widget.plans
          .firstWhere((p) => p['code'] == 'standard',
              orElse: () => widget.plans.first)['code'] as String;
    } else {
      _plan = widget.currentPlan;
    }
  }

  @override
  void dispose() {
    _installCtrl.dispose();
    _trainingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convertir en client payant'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _plan,
              decoration: const InputDecoration(
                  labelText: 'Plan', border: OutlineInputBorder()),
              items: widget.plans
                  .map((p) => DropdownMenuItem<String>(
                        value: p['code'] as String,
                        child: Text(p['name'] as String? ?? p['code'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _plan = v ?? _plan),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _installCtrl,
              decoration: const InputDecoration(
                  labelText: 'Frais installation (FCFA)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trainingCtrl,
              decoration: const InputDecoration(
                  labelText: 'Frais formation (FCFA, 0 si offert)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _billingStart,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _billingStart = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Début facturation',
                    border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(_billingStart)),
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
          onPressed: () {
            Navigator.pop(context, {
              'planCode': _plan,
              'installationFee':
                  double.tryParse(_installCtrl.text.isEmpty ? '0' : _installCtrl.text),
              'trainingFee':
                  double.tryParse(_trainingCtrl.text.isEmpty ? '0' : _trainingCtrl.text),
              'billingStartDate': _billingStart.toIso8601String(),
            });
          },
          child: const Text('Activer'),
        ),
      ],
    );
  }
}

// ── Section paidUntil (abonnement actif) ─────────────────────────────────────

class _PaidUntilCard extends StatelessWidget {
  final String paidUntil;
  final String tenantId;
  final List<Map<String, dynamic>> plans;
  final String token;
  final WidgetRef ref;

  const _PaidUntilCard({
    required this.paidUntil,
    required this.tenantId,
    required this.plans,
    required this.token,
    required this.ref,
  });

  String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  int _daysLeft(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 0;
    return dt.difference(DateTime.now()).inDays;
  }

  Future<void> _openRenewalDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SubscriptionRenewalDialog(plans: plans),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(adminApiServiceProvider).recordBillingEvent(
            tenantId,
            result,
            token: token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
      ref.invalidate(billingSummaryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renouvellement enregistré ✓')),
        );
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
    final days = _daysLeft(paidUntil);
    final Color color;
    final String message;

    if (days <= 3) {
      color = Colors.red;
      message = 'Expire dans $days jour(s) — urgent !';
    } else if (days <= 7) {
      color = Colors.orange;
      message = 'Expire dans $days jours';
    } else if (days <= 30) {
      color = Colors.blue;
      message = 'Valide jusqu\'au ${_fmt(paidUntil)}';
    } else {
      color = Colors.green;
      message = 'Payé jusqu\'au ${_fmt(paidUntil)} ($days jours)';
    }

    return Card(
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () => _openRenewalDialog(context),
              child: const Text('Renouveler'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog renouvellement abonnement ──────────────────────────────────────────

class _SubscriptionRenewalDialog extends StatefulWidget {
  final List<Map<String, dynamic>> plans;

  const _SubscriptionRenewalDialog({required this.plans});

  @override
  State<_SubscriptionRenewalDialog> createState() =>
      _SubscriptionRenewalDialogState();
}

class _SubscriptionRenewalDialogState
    extends State<_SubscriptionRenewalDialog> {
  int _months = 1;
  String _method = 'cash';
  final _refCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  double? _planPrice;

  @override
  void initState() {
    super.initState();
    // Try to get the standard plan price as default
    final std = widget.plans.firstWhere(
        (p) => p['code'] == 'standard',
        orElse: () => widget.plans.isNotEmpty ? widget.plans.first : {});
    _planPrice = std.isEmpty
        ? null
        : double.tryParse(
            (std['monthlyPrice'] ?? std['monthly_price'] ?? 0).toString());
    _updateAmount();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _updateAmount() {
    if (_planPrice != null) {
      _amountCtrl.text = (_planPrice! * _months).toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renouvellement abonnement'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Months selector
            Row(
              children: [
                const Text('Nombre de mois :',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                ...([1, 3, 6, 12].map((m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$m'),
                        selected: _months == m,
                        onSelected: (_) => setState(() {
                          _months = m;
                          _updateAmount();
                        }),
                      ),
                    ))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant total (FCFA)',
                border: OutlineInputBorder(),
                helperText: 'Modifiable si remise accordée',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                  labelText: 'Méthode', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(
                    value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(
                    value: 'bank_transfer', child: Text('Virement')),
              ],
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                  labelText: 'Référence (optionnel)',
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
                    labelText: 'Date paiement',
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
          onPressed: () {
            final amount = double.tryParse(
                    _amountCtrl.text.replaceAll(' ', '')) ??
                0;
            Navigator.pop(context, {
              'type': 'subscription',
              'amount': amount.toStringAsFixed(0),
              'monthsPaid': _months,
              'paymentMethod': _method,
              'paymentRef': _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
              'paidAt': _date.toIso8601String(),
              'description':
                  'Abonnement — $_months mois — ${DateFormat('MMMM yyyy', 'fr_FR').format(_date)}',
            });
          },
          child: const Text('Valider et générer reçu'),
        ),
      ],
    );
  }
}

// ── Section Frais ──────────────────────────────────────────────────────────────

class _FeesSection extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic> tenant;
  final String token;
  final WidgetRef ref;

  const _FeesSection({
    required this.tenantId,
    required this.tenant,
    required this.token,
    required this.ref,
  });

  @override
  State<_FeesSection> createState() => _FeesSectionState();
}

class _FeesSectionState extends State<_FeesSection> {
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(
        text: widget.tenant['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = double.tryParse(v.toString()) ?? 0;
    if (n == 0) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA';
  }

  Future<void> _toggle(String field, bool value) async {
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

  Future<void> _saveNotes() async {
    try {
      await widget.ref.read(adminApiServiceProvider).updateTenantBilling(
            widget.tenantId,
            {'notes': _notesCtrl.text},
            token: widget.token,
          );
      widget.ref.invalidate(tenantBillingProvider(widget.tenantId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final installPaid = widget.tenant['installationPaid'] as bool? ?? false;
    final trainingPaid = widget.tenant['trainingPaid'] as bool? ?? false;

    return Column(
      children: [
        _FeeRow(
          label: 'Installation',
          amount: _fmt(widget.tenant['installationFee']),
          paid: installPaid,
          onToggle: (v) => _toggle('installationPaid', v),
        ),
        _FeeRow(
          label: 'Formation',
          amount: _fmt(widget.tenant['trainingFee']),
          paid: trainingPaid,
          onToggle: (v) => _toggle('trainingPaid', v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'ex: remise early adopter 20%',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onEditingComplete: _saveNotes,
          onTapOutside: (_) => _saveNotes(),
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool paid;
  final ValueChanged<bool> onToggle;

  const _FeeRow({
    required this.label,
    required this.amount,
    required this.paid,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(amount)),
          Switch(value: paid, onChanged: onToggle),
          const SizedBox(width: 4),
          Text(
            paid ? 'Payé ✓' : 'Non payé ✗',
            style: TextStyle(
                color: paid ? Colors.green : Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── BillingEvent row avec facture + reçu ──────────────────────────────────────

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
        _ => 'En attente',
      };

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yy').format(dt);
  }

  String _formatAmount(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
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
      ref.invalidate(billingSummaryProvider);
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
    final invoiceNumber = event['invoiceNumber'] as String?;
    final receiptNumber = event['receiptNumber'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event['type']} — ${_formatAmount(event['amount'])}',
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (invoiceNumber case final String _)
                  IconButton(
                    icon: const Icon(Icons.description_outlined, size: 18),
                    tooltip: 'Télécharger facture',
                    onPressed: () => _redownloadInvoice(context),
                  ),
                if (receiptNumber case final String _)
                  IconButton(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    tooltip: 'Télécharger reçu',
                    onPressed: () => _redownloadReceipt(context),
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

  void _redownloadInvoice(BuildContext context) {
    // Re-generate a simple invoice from stored event data
    InvoiceService.generateAndDownloadInvoice({
      'invoiceNumber': event['invoiceNumber'],
      'date': event['createdAt'],
      'tenant': {'name': ''},
      'plan': {'code': '', 'name': ''},
      'lines': [
        {
          'description': event['description'] ?? event['type'],
          'amount': double.tryParse(event['amount']?.toString() ?? '0') ?? 0,
        }
      ],
      'total':
          double.tryParse(event['amount']?.toString() ?? '0') ?? 0,
    });
  }

  void _redownloadReceipt(BuildContext context) {
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

// ── Dialog Ajouter paiement ────────────────────────────────────────────────────

class _AddPaymentDialog extends StatefulWidget {
  const _AddPaymentDialog();

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  String _type = 'subscription';
  String _method = 'cash';
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _markPaid = true;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un paiement'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'subscription', child: Text('Abonnement')),
                DropdownMenuItem(
                    value: 'installation', child: Text('Installation')),
                DropdownMenuItem(
                    value: 'training', child: Text('Formation')),
                DropdownMenuItem(value: 'payment', child: Text('Paiement')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                  labelText: 'Méthode', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(
                    value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(
                    value: 'bank_transfer', child: Text('Virement')),
              ],
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                  labelText: 'Référence (optionnel)',
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
                    labelText: 'Date', border: OutlineInputBorder()),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _markPaid,
              onChanged: (v) => setState(() => _markPaid = v),
              title: const Text('Marquer comme payé'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            final amount =
                double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
            Navigator.pop(context, {
              'type': _type,
              'amount': amount.toStringAsFixed(0),
              'paymentMethod': _method,
              'paymentRef':
                  _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
              'paidAt': _markPaid ? _date.toIso8601String() : null,
              'dueDate': !_markPaid ? _date.toIso8601String() : null,
            });
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// ── Dialog Marquer payé (avec paiement) ───────────────────────────────────────

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
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                  labelText: 'Méthode', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(
                    value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(
                    value: 'bank_transfer', child: Text('Virement')),
              ],
              onChanged: (v) => setState(() => _method = v ?? _method),
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
