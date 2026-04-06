import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

String _fcfa(num v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

/// Arrêt de caisse — Étape 3/3 : Signature propriétaire
///
/// Vue mobile : Blandine signe (ou rejette) la clôture depuis son téléphone.
/// Affiche l'audit trail complet (caissier → gestionnaire → propriétaire).
class SessionSignScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionSignScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionSignScreen> createState() => _SessionSignScreenState();
}

class _SessionSignScreenState extends ConsumerState<SessionSignScreen> {
  final _noteController = TextEditingController();

  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _loadError;
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

  Future<void> _onSign(bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Signer et clôturer ?' : 'Rejeter vers le gestionnaire ?'),
        content: Text(
          approve
              ? 'Cette action est horodatée et archivée définitivement.'
              : 'La session sera renvoyée au gestionnaire pour révision.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: approve
                ? null
                : FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Signer' : 'Rejeter'),
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
                '${ApiConstants.baseUrl}/retail/sessions/sign/${widget.sessionId}'),
            headers: {
              'Content-Type': 'application/json',
              'x-tenant-id': tenantId,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'approved': approve,
              if (_noteController.text.trim().isNotEmpty)
                'note': _noteController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Caisse clôturée et signée.'
                : 'Session renvoyée au gestionnaire.'),
            backgroundColor:
                approve ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: AppColors.error),
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
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final session = summary['session'] as Map<String, dynamic>;
    final systemTotal = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
    final closingBalance = (summary['closingBalance'] as num?)?.toDouble();
    final variance = (summary['variance'] as num?)?.toDouble();
    final cashierNote = summary['varianceExplanation'] as String?;
    final managerNote = summary['managerNote'] as String?;
    final managerValidatedAt = summary['managerValidatedAt'] != null
        ? DateTime.tryParse(summary['managerValidatedAt'].toString())
        : null;

    final openedAtStr = session['opened_at'] as String?;
    final closedAtStr = session['closed_at'] as String?;
    final openedAt = openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final closedAt = closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress stepper ─────────────────────────────────────────────
          _ProgressStepper(currentStep: 2),

          const SizedBox(height: 20),

          // ── Session summary card ─────────────────────────────────────────
          _Card(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Session du jour',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      'En attente de vous',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      label: 'Date',
                      value: openedAt != null
                          ? DateFormat('d MMMM yyyy', 'fr_FR').format(openedAt)
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
            ],
          ),

          const SizedBox(height: 12),

          // ── Financial summary ────────────────────────────────────────────
          _Card(
            children: [
              const Text('Récapitulatif',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Total ventes système', value: _fcfa(systemTotal)),
              if (closingBalance != null)
                _SummaryRow(
                    label: 'Total compté caissier', value: _fcfa(closingBalance)),
              if (variance != null) ...[
                const Divider(height: 16),
                _SummaryRow(
                  label: variance == 0 ? 'Aucun écart' : 'Écart constaté',
                  value: variance == 0
                      ? '0 FCFA ✓'
                      : '${variance > 0 ? '+' : ''}${_fcfa(variance)}',
                  valueColor: variance == 0
                      ? Colors.green.shade700
                      : (variance > 0
                          ? Colors.orange.shade700
                          : AppColors.error),
                  bold: true,
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── Audit trail ──────────────────────────────────────────────────
          _Card(
            children: [
              const Text('Audit trail',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),

              // Step 1 — Cashier
              _AuditEntry(
                initials: 'C',
                avatarColor: Colors.amber.shade600,
                roleLabel: 'Caissier',
                roleBadgeColor: Colors.amber,
                timestamp: closedAt != null
                    ? 'Soumis le ${DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(closedAt)}'
                    : 'Soumis',
                note: cashierNote,
                showLine: true,
                done: true,
              ),

              // Step 2 — Manager
              _AuditEntry(
                initials: 'G',
                avatarColor: Colors.green.shade600,
                roleLabel: 'Gestionnaire',
                roleBadgeColor: Colors.green,
                timestamp: managerValidatedAt != null
                    ? 'Validé le ${DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(managerValidatedAt)}'
                    : 'Validé',
                note: managerNote,
                showLine: true,
                done: true,
              ),

              // Step 3 — Owner (pending)
              _AuditEntry(
                initials: 'P',
                avatarColor: AppColors.primary,
                roleLabel: 'Propriétaire',
                roleBadgeColor: AppColors.primary,
                timestamp: 'En attente de votre signature',
                note: null,
                showLine: false,
                done: false,
                isPending: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Owner note ───────────────────────────────────────────────────
          _Card(
            children: [
              const Row(
                children: [
                  Text('NOTE PERSONNELLE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                  SizedBox(width: 6),
                  Text('(optionnel)',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ex : Vérifier avec le gestionnaire l\'origine de l\'écart…',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  isDense: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Signature zone ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre signature engage la clôture',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cette action est horodatée et archivée de façon permanente.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Sign button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : () => _onSign(true),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.edit_outlined, size: 18),
                    label: Text(_isSubmitting ? 'Envoi…' : 'Signer et clôturer la caisse'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Reject button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                    onPressed: _isSubmitting ? null : () => _onSign(false),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Rejeter et renvoyer au gestionnaire'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
                color: i <= currentStep
                    ? (i < currentStep ? Colors.green : AppColors.primary)
                    : Colors.grey.shade300,
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
  const _StepDot(
      {required this.index,
      required this.label,
      required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;
    final color = isDone
        ? Colors.green
        : isCurrent
            ? AppColors.primary
            : Colors.grey.shade300;

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
            color: isDone
                ? Colors.green
                : isCurrent
                    ? AppColors.primary
                    : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

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
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold ? null : AppColors.textSecondary,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _AuditEntry extends StatelessWidget {
  final String initials;
  final Color avatarColor;
  final String roleLabel;
  final Color roleBadgeColor;
  final String timestamp;
  final String? note;
  final bool showLine;
  final bool done;
  final bool isPending;

  const _AuditEntry({
    required this.initials,
    required this.avatarColor,
    required this.roleLabel,
    required this.roleBadgeColor,
    required this.timestamp,
    required this.note,
    required this.showLine,
    required this.done,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + line
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPending
                      ? avatarColor
                      : (done
                          ? Colors.green.shade100
                          : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  boxShadow: isPending
                      ? [
                          BoxShadow(
                              color: avatarColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 2)
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isPending
                          ? Colors.white
                          : (done ? Colors.green.shade700 : Colors.grey),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: done ? Colors.green.shade200 : Colors.grey.shade200,
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBadgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: roleBadgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: roleBadgeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 11,
                    color: isPending ? AppColors.primary : AppColors.textSecondary,
                    fontWeight:
                        isPending ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      '"$note"',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
