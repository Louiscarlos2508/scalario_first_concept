import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

/// Arrêt de caisse — Étape 1/3 : Soumission
///
/// Affiche :
///   • Stepper 3 étapes (Soumission · Validation · Signature)
///   • Infos session (date, caissier, ouverture, fermeture)
///   • Ventes système par méthode (lecture seule)
///   • Comptage physique (espèces éditables, mobile money auto-confirmé)
///   • Écart calculé en temps réel
///   • Note optionnelle
///   • Action : Soumettre au gestionnaire
class SessionCloseScreen extends ConsumerStatefulWidget {
  const SessionCloseScreen({super.key});

  @override
  ConsumerState<SessionCloseScreen> createState() => _SessionCloseScreenState();
}

class _SessionCloseScreenState extends ConsumerState<SessionCloseScreen> {
  final _cashController = TextEditingController();
  final _noteController = TextEditingController();

  Map<String, dynamic>? _summary;
  bool _isLoadingSummary = true;
  bool _loadError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _cashController.addListener(_onCashChanged);
  }

  @override
  void dispose() {
    _cashController.removeListener(_onCashChanged);
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCashChanged() => setState(() {});

  Future<void> _loadSummary() async {
    if (mounted) setState(() { _loadError = false; _isLoadingSummary = true; });
    try {
      final summary = await ref
          .read(sessionProvider.notifier)
          .calculateSessionSummary()
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _summary = summary.isEmpty ? _fallbackSummary() : summary;
          _isLoadingSummary = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[SessionClose] calculateSessionSummary error: $e\n$stack');
      if (mounted) setState(() { _loadError = true; _isLoadingSummary = false; });
    }
  }

  static Map<String, dynamic> _fallbackSummary() => {
        'openingBalance': 0.0,
        'totalsByMethod': <String, double>{},
        'countsByMethod': <String, int>{},
        'totalSales': 0.0,
        'orderCount': 0,
        'splitCount': 0,
        'theoreticalCash': 0.0,
      };

  double get _physicalCash =>
      double.tryParse(_cashController.text.replaceAll(' ', '')) ?? 0.0;

  double get _theoreticalCash =>
      (_summary?['theoreticalCash'] as double?) ?? 0.0;

  double get _variance => _physicalCash - _theoreticalCash;

  bool get _cashEntered => _cashController.text.isNotEmpty;

  double get _systemTotal {
    final m = (_summary?['totalsByMethod'] as Map<String, double>?) ?? {};
    return m.values.fold(0.0, (a, b) => a + b);
  }

  double get _physicalTotal {
    final m = (_summary?['totalsByMethod'] as Map<String, double>?) ?? {};
    final nonCash = m.entries
        .where((e) => e.key.toUpperCase() != 'CASH')
        .fold(0.0, (a, e) => a + e.value);
    return (_cashEntered ? _physicalCash : 0.0) + nonCash;
  }

  Future<void> _onSubmit() async {
    if (_cashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le comptage physique des espèces.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la soumission'),
        content: const Text(
          'La session sera soumise au gestionnaire pour validation. '
          'Vous ne pourrez plus modifier les données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    await ref.read(sessionProvider.notifier).closeSession(
          _physicalCash,
          _theoreticalCash,
          varianceExplanation:
              _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final employee = ref.watch(selectedEmployeeProvider);
    final cashierName =
        employee?.name ?? profile?.fullName ?? profile?.email ?? 'Caissier';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ScalarioAppBar(title: 'Arrêt de caisse'),
      body: _isLoadingSummary
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? _buildErrorState()
              : _buildContent(session, cashierName),
      bottomNavigationBar: (_isLoadingSummary || _loadError) ? null : _buildBottomBar(),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(dynamic session, String cashierName) {
    final summary = _summary!;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final openedAt = session?.openedAt as DateTime?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress stepper ───────────────────────────────────────────────
          _ProgressStepper(currentStep: 0),

          const SizedBox(height: 20),

          // ── Session info ───────────────────────────────────────────────────
          _SectionCard(
            children: [
              _InfoGrid(rows: [
                _InfoCell(label: 'Date', value: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now())),
                _InfoCell(label: 'Caissier', value: cashierName),
                _InfoCell(
                  label: 'Ouverture',
                  value: openedAt != null ? DateFormat('HH:mm').format(openedAt) : '—',
                ),
                _InfoCell(
                  label: 'Fermeture',
                  value: '${DateFormat('HH:mm').format(DateTime.now())} (maintenant)',
                  muted: true,
                ),
              ]),
            ],
          ),

          const SizedBox(height: 12),

          // ── Two-panel: system sales vs physical count ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SystemSalesPanel(totalsByMethod: totalsByMethod)),
              const SizedBox(width: 12),
              Expanded(
                child: _PhysicalCountPanel(
                  totalsByMethod: totalsByMethod,
                  cashController: _cashController,
                  physicalTotal: _physicalTotal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Écart ──────────────────────────────────────────────────────────
          if (_cashEntered) _VarianceCard(
            variance: _variance,
            systemTotal: _systemTotal,
            physicalTotal: _physicalTotal,
          ),

          if (_cashEntered) const SizedBox(height: 12),

          // ── Note optionnelle ───────────────────────────────────────────────
          _SectionLabel(label: 'Note ou commentaire', optional: true),
          _SectionCard(
            children: [
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ex : 500 FCFA manquants, probable erreur de rendu monnaie…',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  isDense: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Info notice ────────────────────────────────────────────────────
          _NoticeRow(
            text: 'La soumission notifiera le gestionnaire pour validation.',
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _onSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(_isSubmitting ? 'Envoi…' : 'Soumettre au gestionnaire'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger le résumé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez que la session est bien active et réessayez.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress stepper ──────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final int currentStep; // 0=Soumission, 1=Validation, 2=Signature

  const _ProgressStepper({required this.currentStep});

  static const _steps = ['Soumission', 'Validation', 'Signature'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentStep ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          _StepDot(index: i, label: _steps[i], currentStep: currentStep),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final int currentStep;

  const _StepDot({required this.index, required this.label, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;
    final color = (isDone || isCurrent) ? AppColors.primary : Colors.grey.shade300;
    final textColor = (isDone || isCurrent) ? AppColors.primary : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isCurrent) ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ── System sales panel ────────────────────────────────────────────────────────

class _SystemSalesPanel extends StatelessWidget {
  final Map<String, double> totalsByMethod;

  const _SystemSalesPanel({required this.totalsByMethod});

  double get _total => totalsByMethod.values.fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ventes système',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Auto',
                style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...totalsByMethod.entries
            .where((e) => e.value > 0)
            .map((e) => _MethodRow(
                  method: e.key,
                  amount: e.value,
                  dotColor: _dotColor(e.key),
                )),
        if (totalsByMethod.isEmpty)
          const Text('Aucune vente', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total système', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(_fcfa(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Color _dotColor(String method) {
    switch (method.toUpperCase()) {
      case 'CASH': return Colors.green;
      case 'MOBILE_MONEY': return Colors.orange;
      case 'CARD': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

// ── Physical count panel ──────────────────────────────────────────────────────

class _PhysicalCountPanel extends StatelessWidget {
  final Map<String, double> totalsByMethod;
  final TextEditingController cashController;
  final double physicalTotal;

  const _PhysicalCountPanel({
    required this.totalsByMethod,
    required this.cashController,
    required this.physicalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final nonCashEntries = totalsByMethod.entries
        .where((e) => e.key.toUpperCase() != 'CASH' && e.value > 0)
        .toList();

    return _SectionCard(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Comptage physique',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                'À saisir',
                style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Cash — editable
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espèces comptées',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            TextField(
              controller: cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                suffixText: 'FCFA',
                suffixStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),

        // Non-cash — readonly
        ...nonCashEntries.map((e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(paymentMethodLabel(e.key),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Text('(système)',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _fcfa(e.value),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )),

        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total compté', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(_fcfa(physicalTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

// ── Variance card ─────────────────────────────────────────────────────────────

class _VarianceCard extends StatelessWidget {
  final double variance;
  final double systemTotal;
  final double physicalTotal;

  const _VarianceCard({
    required this.variance,
    required this.systemTotal,
    required this.physicalTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isBalanced = variance == 0;
    final isOver = variance > 0;

    final bgColor = isBalanced ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor = isBalanced ? Colors.green.shade200 : Colors.red.shade200;
    final iconBgColor = isBalanced ? Colors.green.shade100 : Colors.red.shade100;
    final iconColor = isBalanced ? Colors.green.shade700 : Colors.red.shade700;
    final titleColor = isBalanced ? Colors.green.shade800 : Colors.red.shade800;
    final amountColor = isBalanced ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              isBalanced ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBalanced ? 'Caisse équilibrée' : 'Écart détecté',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                ),
                Text(
                  'Système − Comptage',
                  style: TextStyle(fontSize: 11, color: titleColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isBalanced
                    ? '0 FCFA'
                    : '${isOver ? '+' : ''}${_fcfa(variance)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
              ),
              if (!isBalanced)
                Text(
                  isOver ? 'Excédent' : 'Manquant',
                  style: TextStyle(fontSize: 11, color: amountColor, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool optional;

  const _SectionLabel({required this.label, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            const Text(
              '(optionnel)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoCell> rows;

  const _InfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: rows,
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _InfoCell({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted ? AppColors.textSecondary : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  final String method;
  final double amount;
  final Color dotColor;

  const _MethodRow({required this.method, required this.amount, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(paymentMethodLabel(method),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(_fcfa(amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final String text;

  const _NoticeRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
