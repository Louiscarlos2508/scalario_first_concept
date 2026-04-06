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
import 'session_validate_screen.dart';
import 'session_sign_screen.dart';
import 'session_history_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final pendingSessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final tenantId = ref.watch(activeTenantProvider) ?? '';
  if (tenantId.isEmpty) return [];

  final uri = Uri.parse('${ApiConstants.baseUrl}/retail/sessions/pending')
      .replace(queryParameters: {'tenantId': tenantId});
  final response = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'x-tenant-id': tenantId,
    if (token != null) 'Authorization': 'Bearer $token',
  }).timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
  throw Exception('Erreur ${response.statusCode}');
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Liste les sessions en attente de validation (PENDING_MANAGER)
/// ou de signature (PENDING_OWNER), selon le rôle de l'utilisateur.
class SessionsPendingScreen extends ConsumerWidget {
  const SessionsPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final sessionsAsync = ref.watch(pendingSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Sessions de caisse',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SessionHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingSessionsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          error: '$e',
          onRetry: () => ref.invalidate(pendingSessionsProvider),
        ),
        data: (sessions) {
          // Filter by role: managers see PENDING_MANAGER, owners see both
          final visible = sessions.where((s) {
            final status = s['status'] as String? ?? '';
            if (role == 'manager') return status == 'PENDING_MANAGER';
            // owner sees all pending
            return status == 'PENDING_MANAGER' || status == 'PENDING_OWNER';
          }).toList();

          if (visible.isEmpty) {
            return _EmptyState(role: role);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingSessionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _SessionCard(
                session: visible[i],
                role: role,
                onTap: () async {
                  final id = visible[i]['id'] as String;
                  final status = visible[i]['status'] as String? ?? '';
                  Widget screen;
                  if (status == 'PENDING_OWNER') {
                    screen = SessionSignScreen(sessionId: id);
                  } else {
                    screen = SessionValidateScreen(sessionId: id);
                  }
                  final result = await Navigator.push<bool>(
                    ctx,
                    MaterialPageRoute(builder: (_) => screen),
                  );
                  if (result == true) {
                    ref.invalidate(pendingSessionsProvider);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final String role;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = session['status'] as String? ?? '';
    final openedAtStr = session['opened_at'] as String?;
    final closedAtStr = session['closed_at'] as String?;
    final openedAt = openedAtStr != null ? DateTime.tryParse(openedAtStr) : null;
    final closedAt = closedAtStr != null ? DateTime.tryParse(closedAtStr) : null;

    final variance = session['variance'] != null
        ? double.tryParse(session['variance'].toString())
        : null;

    final isPendingManager = status == 'PENDING_MANAGER';

    final (statusColor, statusLabel, statusIcon) = isPendingManager
        ? (Colors.amber, 'En attente de validation', Icons.pending_outlined)
        : (AppColors.primary, 'En attente de signature', Icons.edit_outlined);

    final actionLabel = isPendingManager
        ? (role == 'manager' ? 'Valider' : 'Voir')
        : 'Signer';
    final actionColor =
        isPendingManager ? Colors.amber.shade800 : AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    actionLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: actionColor,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: actionColor),
                ],
              ),

              const SizedBox(height: 12),

              // ── Session info ──────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    openedAt != null
                        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                            .format(openedAt)
                        : '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if (openedAt != null)
                        DateFormat('HH:mm').format(openedAt),
                      if (closedAt != null)
                        DateFormat('HH:mm').format(closedAt),
                    ].join(' → '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // ── Variance badge ────────────────────────────────────────────
              if (variance != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      variance == 0
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: variance == 0
                          ? Colors.green.shade700
                          : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      variance == 0
                          ? 'Caisse équilibrée'
                          : 'Écart : ${variance > 0 ? '+' : ''}${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(variance)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: variance == 0
                              ? Colors.green.shade700
                              : AppColors.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String role;
  const _EmptyState({required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline,
                  size: 32, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tout est à jour',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              role == 'manager'
                  ? 'Aucune session en attente de votre validation.'
                  : 'Aucune session en attente de votre signature.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Impossible de charger les sessions',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
