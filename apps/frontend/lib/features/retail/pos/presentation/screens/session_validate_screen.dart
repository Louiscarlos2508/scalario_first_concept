import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

String _fcfa(num v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

/// Arrêt de caisse — Étape 2/3 : Validation gestionnaire
///
/// Le gestionnaire examine la soumission du caissier et choisit de valider
/// (→ envoie à Blandine pour signature) ou de rejeter (→ renvoie au caissier).
class SessionValidateScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionValidateScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionValidateScreen> createState() =>
      _SessionValidateScreenState();
}

class _SessionValidateScreenState
    extends ConsumerState<SessionValidateScreen> {
  final _noteController = TextEditingController();

  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _loadError;

  bool _approve = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/retail/sessions/summary/${widget.sessionId}');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _summary = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _loadError = 'Erreur ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _loadError = '$e'; _isLoading = false; });
    }
  }

  Future<void> _onSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_approve ? 'Valider la session ?' : 'Rejeter la soumission ?'),
        content: Text(
          _approve
              ? 'La session sera transmise à la propriétaire pour signature finale.'
              : 'La soumission sera renvoyée au caissier pour correction.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: _approve
                ? null
                : FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_approve ? 'Valider' : 'Rejeter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}/retail/sessions/validate/${widget.sessionId}'),
            headers: {
              'Content-Type': 'application/json',
              'x-tenant-id': tenantId,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'approved': _approve,
              if (_noteController.text.trim().isNotEmpty)
                'note': _noteController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_approve
                ? 'Session validée — Blandine sera notifiée.'
                : 'Soumission rejetée — le caissier devra re-soumettre.'),
            backgroundColor:
                _approve ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ScalarioAppBar(title: 'Arrêt de caisse'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: (!_isLoading && _loadError == null)
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final session = summary['session'] as Map<String, dynamic>;
    final totalsByMethod =
        (summary['totalsByMethod'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
    final systemTotal = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = (summary['closingBalance'] as num?)?.toDouble();
    final variance = (summary['variance'] as num?)?.toDouble();
    final cashierNote = summary['varianceExplanation'] as String?;

    final openedAtStr = session['opened_at'] as String?;
    final closedAtStr = session['closed_at'] as String?;
    final openedAt = openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final closedAt = closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;

    final nonCash = totalsByMethod.entries
        .where((e) => e.key.toUpperCase() != 'CASH')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress stepper ─────────────────────────────────────────────
          _ProgressStepper(currentStep: 1),

          const SizedBox(height: 20),

          // ── Submission banner (who submitted, when) ───────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('C',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Soumis par le caissier',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (closedAt != null)
                        Text(
                          DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR')
                              .format(closedAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    'En attente',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Session info ─────────────────────────────────────────────────
          _InfoCard(children: [
            Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    label: 'Date',
                    value: openedAt != null
                        ? DateFormat('EEEE d MMMM', 'fr_FR').format(openedAt)
                        : '—',
                  ),
                ),
                Expanded(
                  child: _InfoCell(
                    label: 'Durée',
                    value: [
                      if (openedAt != null) DateFormat('HH:mm').format(openedAt),
                      if (closedAt != null) DateFormat('HH:mm').format(closedAt),
                    ].join(' → '),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 12),

          // ── System sales vs cashier count (read-only) ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReadOnlyPanel(
                  title: 'Ventes système',
                  badge: 'Lecture seule',
                  entries: [
                    ...totalsByMethod.entries
                        .where((e) => e.value > 0)
                        .map((e) => _PanelEntry(
                            label: paymentMethodLabel(e.key),
                            value: _fcfa(e.value))),
                  ],
                  total: _fcfa(systemTotal),
                  totalLabel: 'Total système',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReadOnlyPanel(
                  title: 'Comptage caissier',
                  badge: 'Lecture seule',
                  entries: [
                    _PanelEntry(
                        label: 'Espèces',
                        value: closingBalance != null
                            ? _fcfa(closingBalance)
                            : '—'),
                    ...nonCash.map((e) => _PanelEntry(
                        label: paymentMethodLabel(e.key),
                        value: _fcfa(e.value))),
                  ],
                  total: closingBalance != null
                      ? _fcfa(closingBalance +
                          nonCash.fold(0.0, (s, e) => s + e.value))
                      : '—',
                  totalLabel: 'Total compté',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Variance ─────────────────────────────────────────────────────
          if (variance != null) _VarianceCard(variance: variance),

          if (variance != null) const SizedBox(height: 12),

          // ── Cashier note ─────────────────────────────────────────────────
          if (cashierNote != null && cashierNote.isNotEmpty) ...[
            _SectionLabel(label: 'Note du caissier'),
            _InfoCard(children: [
              Text(
                '"$cashierNote"',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          // ── Decision ─────────────────────────────────────────────────────
          _SectionLabel(label: 'Votre décision'),
          Row(
            children: [
              Expanded(
                child: _DecisionTile(
                  icon: Icons.check_circle_outline,
                  label: 'Valider',
                  sublabel: 'Envoyer à Blandine',
                  selected: _approve,
                  selectedColor: Colors.green,
                  onTap: () => setState(() => _approve = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DecisionTile(
                  icon: Icons.cancel_outlined,
                  label: 'Rejeter',
                  sublabel: 'Renvoyer au caissier',
                  selected: !_approve,
                  selectedColor: AppColors.error,
                  onTap: () => setState(() => _approve = false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Manager note ─────────────────────────────────────────────────
          _SectionLabel(label: 'Commentaire', optional: true),
          _InfoCard(children: [
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _approve
                    ? 'Ex : Écart accepté, erreur de rendu confirmée…'
                    : 'Ex : L\'écart dépasse le seuil autorisé, recompter…',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                isDense: true,
              ),
            ),
          ]),

          const SizedBox(height: 8),

          _NoticeRow(
            text: _approve
                ? 'La validation notifiera la propriétaire pour signature finale.'
                : 'Le rejet renverra la soumission au caissier.',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
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
                style: _approve
                    ? FilledButton.styleFrom(backgroundColor: Colors.green.shade700)
                    : FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: _isSubmitting ? null : _onSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_approve ? Icons.check_circle_outline : Icons.cancel_outlined,
                        size: 18),
                label: Text(_isSubmitting
                    ? 'Envoi…'
                    : (_approve ? 'Valider et notifier' : 'Rejeter la soumission')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Impossible de charger la session',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_loadError ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
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

// ── Shared widgets (reused by sign screen) ────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final int currentStep;
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
    final color = isDone
        ? Colors.green
        : isCurrent
            ? AppColors.primary
            : Colors.grey.shade300;
    final textColor = (isDone || isCurrent) ? color : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : AppColors.textSecondary,
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

class _VarianceCard extends StatelessWidget {
  final double variance;
  const _VarianceCard({required this.variance});

  @override
  Widget build(BuildContext context) {
    final isBalanced = variance == 0;
    final isOver = variance > 0;
    final bg = isBalanced ? Colors.green.shade50 : Colors.red.shade50;
    final border = isBalanced ? Colors.green.shade200 : Colors.red.shade200;
    final color = isBalanced
        ? Colors.green.shade700
        : isOver
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isBalanced ? 'Caisse équilibrée' : 'Écart détecté',
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
            ),
          ),
          Text(
            isBalanced ? '0 FCFA' : '${isOver ? '+' : ''}${_fcfa(variance)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _DecisionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? selectedColor : AppColors.textSecondary,
                size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? selectedColor : null,
                    ),
                  ),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyPanel extends StatelessWidget {
  final String title;
  final String badge;
  final List<_PanelEntry> entries;
  final String total;
  final String totalLabel;

  const _ReadOnlyPanel({
    required this.title,
    required this.badge,
    required this.entries,
    required this.total,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.label,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(totalLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text(total,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelEntry {
  final String label;
  final String value;
  const _PanelEntry({required this.label, required this.value});
}

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
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          if (optional) ...[
            const SizedBox(width: 6),
            const Text('(optionnel)',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal)),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ],
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
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
