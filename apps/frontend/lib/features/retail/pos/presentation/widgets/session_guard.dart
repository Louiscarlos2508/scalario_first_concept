import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pos_providers.dart';
import '../screens/employee_pin_screen.dart';
import '../../data/models/pos_session.dart';
import '../../data/services/z_report_service.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/printing/printer_config_provider.dart';
import 'package:frontend/core/services/device_identity_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';

class SessionGuard extends ConsumerWidget {
  final Widget child;

  const SessionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(
              child: Text('User profile not found. Please log in again.'),
            ),
          );
        }

        // ── Vérification accès POS ──────────────────────────────────────────
        final config = ref.watch(businessTypeConfigProvider).valueOrNull;
        final hasPosAccess = canAccessScreen(profile.role, 'pos', config);

        if (!hasPosAccess) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accès non autorisé',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Votre rôle ne permet pas d'accéder à la caisse.",
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          );
        }

        // Shared-device mode: owner or manager is logged in, employees
        // identify themselves at the start of each shift via PIN.
        // Cashiers/commercials who have their own Supabase account are already
        // identified — no PIN needed.
        final needsPin = profile.role == 'owner';

        return sessionAsync.when(
          data: (session) {
            if (session == null) {
              // PIN gate: show employee selection before opening a new session.
              if (needsPin) {
                final employee = ref.watch(selectedEmployeeProvider);
                if (employee == null) return const EmployeePinScreen();
              }
              return OpenSessionScreen(profile: profile);
            }
            if (session.status == 'CLOSED') {
              return SessionClosedScreen(profile: profile);
            }
            return child;
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error loading session: $err')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error loading profile: $err'))),
    );
  }
}

// ── Session closed screen ─────────────────────────────────────────────────────

class SessionClosedScreen extends ConsumerStatefulWidget {
  final dynamic profile;
  const SessionClosedScreen({super.key, required this.profile});

  @override
  ConsumerState<SessionClosedScreen> createState() =>
      _SessionClosedScreenState();
}

class _SessionClosedScreenState extends ConsumerState<SessionClosedScreen> {
  Map<String, dynamic>? _summary;
  bool _loadingSummary = true;
  double _physicalCash = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await ref
          .read(sessionProvider.notifier)
          .calculateSessionSummary()
          .timeout(const Duration(seconds: 10));
      // Grab closing balance already stored on the session as physical count.
      final session = ref.read(sessionProvider).valueOrNull;
      if (mounted) {
        setState(() {
          _summary = summary.isEmpty ? null : summary;
          _physicalCash = (session?.closingBalance ?? 0).toDouble();
          _loadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _onZReportTap() async {
    final summary = _summary;
    if (summary == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ZReportSheet(
        onSavePdf: () async {
          Navigator.of(ctx).pop();
          final profile = ref.read(userProfileProvider).valueOrNull;
          final employee = ref.read(selectedEmployeeProvider);
          try {
            await ZReportService.savePdf(
              summary: summary,
              physicalCount: _physicalCash,
              userName: employee?.name ??
                  profile?.fullName ??
                  profile?.email ??
                  'Caissier',
              tenantName:
                  profile?.memberships.firstOrNull?.tenantName ?? 'Scalario POS',
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Erreur PDF : $e'),
                  backgroundColor: Colors.red.shade700));
            }
          }
        },
        onPrintThermal: () async {
          Navigator.of(ctx).pop();
          final printerConfig =
              ref.read(printerConfigProvider).valueOrNull;
          if (printerConfig == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Imprimante non configurée — Paramètres > Imprimante'),
                  backgroundColor: Colors.orange));
            }
            return;
          }
          final profile = ref.read(userProfileProvider).valueOrNull;
          final employee = ref.read(selectedEmployeeProvider);
          try {
            await ZReportService.printThermal(
              summary: summary,
              physicalCount: _physicalCash,
              userName: employee?.name ??
                  profile?.fullName ??
                  profile?.email ??
                  'Caissier',
              tenantName:
                  profile?.memberships.firstOrNull?.tenantName ?? 'Scalario POS',
              printerConfig: printerConfig,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Rapport envoyé à l\'imprimante.'),
                  backgroundColor: Colors.green));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Erreur impression : $e'),
                  backgroundColor: Colors.red.shade700));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Success header ──────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Caisse fermée',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                      .format(DateTime.now()),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),

                const SizedBox(height: 24),

                // ── Summary card ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _loadingSummary
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _summary == null
                          ? const Text('Résumé indisponible',
                              style: TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Résumé de session',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 12),
                                _SummaryRow(
                                  label: 'Total ventes',
                                  value: currency.format(
                                      _summary!['totalSales'] as double),
                                  bold: true,
                                ),
                                _SummaryRow(
                                  label: 'Transactions',
                                  value:
                                      '${_summary!['orderCount']} vente${(_summary!['orderCount'] as int) != 1 ? "s" : ""}',
                                ),
                                _SummaryRow(
                                  label: 'Caisse théorique',
                                  value: currency.format(
                                      _summary!['theoreticalCash'] as double),
                                ),
                                if (_physicalCash > 0) ...[
                                  _SummaryRow(
                                    label: 'Montant déclaré',
                                    value: currency.format(_physicalCash),
                                  ),
                                  _SummaryRow(
                                    label: 'Écart',
                                    value: currency.format(_physicalCash -
                                        (_summary!['theoreticalCash']
                                            as double)),
                                    valueColor: (_physicalCash -
                                                (_summary!['theoreticalCash']
                                                    as double)) ==
                                            0
                                        ? Colors.green.shade700
                                        : AppColors.error,
                                  ),
                                ],
                              ],
                            ),
                ),

                const SizedBox(height: 12),

                // ── Z-Report button ─────────────────────────────────────
                if (_summary != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onZReportTap,
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Rapport Z'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── New session button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Ouvrir une nouvelle session'),
                    onPressed: () {
                      ref.read(selectedEmployeeProvider.notifier).state =
                          null;
                      ref
                          .read(sessionProvider.notifier)
                          .resetForNewSession();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared summary row ────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

// ── Z-Report bottom sheet ─────────────────────────────────────────────────────

class _ZReportSheet extends StatelessWidget {
  final VoidCallback onSavePdf;
  final VoidCallback onPrintThermal;

  const _ZReportSheet(
      {required this.onSavePdf, required this.onPrintThermal});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rapport Z',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text('Choisissez le format de sortie',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _ReportOption(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: Colors.red.shade700,
              title: 'Enregistrer en PDF',
              subtitle: 'Prévisualisation et impression / sauvegarde',
              onTap: onSavePdf,
            ),
            const SizedBox(height: 8),
            _ReportOption(
              icon: Icons.print_outlined,
              iconColor: AppColors.primary,
              title: 'Imprimer (thermique)',
              subtitle: 'Envoyer à l\'imprimante thermique configurée',
              onTap: onPrintThermal,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Open session screen ───────────────────────────────────────────────────────

class OpenSessionScreen extends ConsumerStatefulWidget {
  final dynamic profile;
  const OpenSessionScreen({super.key, required this.profile});

  @override
  ConsumerState<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

class _OpenSessionScreenState extends ConsumerState<OpenSessionScreen> {
  final _amountController = TextEditingController();
  bool _submitted = false;
  bool _isOpening = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? get _amountError {
    if (!_submitted) return null;
    final text = _amountController.text.trim();
    if (text.isEmpty) return 'Veuillez saisir le fond de caisse';
    if (double.tryParse(text) == null) return 'Montant invalide';
    return null;
  }

  Future<void> _open() async {
    setState(() => _submitted = true);
    if (_amountError != null) return;

    setState(() => _isOpening = true);
    final amount =
        double.tryParse(_amountController.text.trim()) ?? 0;
    final deviceId = await DeviceIdentityService().getDeviceId();
    final session = PosSession()
      ..userId = widget.profile.id
      ..tenantId = widget.profile.tenantId
      ..status = 'OPEN'
      ..openingBalance = amount
      ..deviceId = deviceId
      ..openedAt = DateTime.now();

    await ref.read(sessionProvider.notifier).openSession(session);
    if (mounted) setState(() => _isOpening = false);
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(selectedEmployeeProvider);
    final cashierName = employee?.name ??
        widget.profile.fullName ??
        widget.profile.email ??
        'Caissier';
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand header ───────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.point_of_sale_outlined,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ouvrir la caisse',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ── Card ───────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cashier identity row
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline,
                                size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cashierName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                Text(
                                  widget.profile.role == 'owner'
                                      ? 'Propriétaire'
                                      : widget.profile.role == 'manager'
                                          ? 'Gestionnaire'
                                          : 'Caissier',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // Amount field
                      const Text(
                        'Fond de caisse initial',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Comptez les billets et pièces dans le tiroir',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        autofocus: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        onChanged: (_) {
                          if (_submitted) setState(() {});
                        },
                        onSubmitted: (_) => _open(),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: 'FCFA',
                          border: const OutlineInputBorder(),
                          errorText: _amountError,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Open button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isOpening ? null : _open,
                          icon: _isOpening
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.lock_open_outlined,
                                  size: 18),
                          label: Text(_isOpening
                              ? 'Ouverture…'
                              : 'Ouvrir la caisse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
