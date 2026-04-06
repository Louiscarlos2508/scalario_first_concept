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
import 'package:frontend/features/shared/business_type/utils/role_label_utils.dart';
import 'team_member_form_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

String? _token() =>
    Supabase.instance.client.auth.currentSession?.accessToken;

final teamUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final token = _token();
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/my-users'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as List;
    return body.cast<Map<String, dynamic>>();
  }
  return [];
});

// ── Role config ───────────────────────────────────────────────────────────────

enum _UserFilter { all, active, inactive }

const _kRoleOrder = ['commercial', 'manager', 'owner'];

class _RoleConfig {
  final String code;
  final String label;
  final String shortPermissions;
  final Color color;

  const _RoleConfig({
    required this.code,
    required this.label,
    required this.shortPermissions,
    required this.color,
  });
}

const _kRoles = [
  _RoleConfig(
    code: 'commercial',
    label: 'Vendeur',
    shortPermissions: 'POS uniquement',
    color: Color(0xFF0D9488), // teal
  ),
  _RoleConfig(
    code: 'manager',
    label: 'Responsable',
    shortPermissions: 'POS · Stock · Rapports partiels',
    color: Color(0xFF7C3AED), // violet
  ),
  _RoleConfig(
    code: 'owner',
    label: 'Propriétaire',
    shortPermissions: 'Accès complet',
    color: Color(0xFF1A73E8), // blue
  ),
];

_RoleConfig _roleConfig(String code) =>
    _kRoles.firstWhere((r) => r.code == code,
        orElse: () => _RoleConfig(
              code: code,
              label: getRoleLabel(code, {}),
              shortPermissions: '',
              color: AppColors.textSecondary,
            ));

// ── Screen ────────────────────────────────────────────────────────────────────

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  _UserFilter _filter = _UserFilter.all;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(teamUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: 'Équipe & Utilisateurs',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teamUsersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Impossible de charger l\'équipe',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$err',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(teamUsersProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (users) => _buildBody(users),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> users) {
    // Count per role
    final counts = <String, int>{};
    for (final u in users) {
      final role = u['role'] as String? ?? '';
      counts[role] = (counts[role] ?? 0) + 1;
    }

    // Apply filter + search
    final filtered = users.where((u) {
      final isActive = (u['isActive'] as bool?) ?? true;
      if (_filter == _UserFilter.active && !isActive) return false;
      if (_filter == _UserFilter.inactive && isActive) return false;

      if (_search.isNotEmpty) {
        final name =
            (u['fullName'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        final q = _search.toLowerCase();
        if (!name.contains(q) && !email.contains(q)) return false;
      }
      return true;
    }).toList();

    // Sort: owner first, then manager, then commercial
    filtered.sort((a, b) {
      final ai = _kRoleOrder.indexOf(a['role'] as String? ?? '');
      final bi = _kRoleOrder.indexOf(b['role'] as String? ?? '');
      return ai.compareTo(bi);
    });

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teamUsersProvider),
      child: CustomScrollView(
        slivers: [
          // Role summary cards
          SliverToBoxAdapter(
            child: _RoleCardsRow(counts: counts),
          ),

          // Search + filter bar
          SliverToBoxAdapter(
            child: _SearchFilterBar(
              searchCtrl: _searchCtrl,
              filter: _filter,
              onSearchChanged: (v) => setState(() => _search = v),
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),

          // "Nouvel utilisateur" button (always visible, owner-only)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: FilledButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Nouvel utilisateur'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final added = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeamMemberFormScreen()),
                  );
                  if (added == true) ref.invalidate(teamUsersProvider);
                },
              ),
            ),
          ),

          // User list or empty state
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                  isSearch: _search.isNotEmpty,
                  filter: _filter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) => _UserRow(
                  user: filtered[i],
                  key: Key('user_${filtered[i]['userId']}'),
                  onRoleChanged: () => ref.invalidate(teamUsersProvider),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Role cards row ────────────────────────────────────────────────────────────

class _RoleCardsRow extends StatelessWidget {
  final Map<String, int> counts;
  const _RoleCardsRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: _kRoles.map((r) {
          final count = counts[r.code] ?? 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: r.code == 'owner' ? 0 : 8,
              ),
              child: _RoleCard(config: r, count: count),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleConfig config;
  final int count;
  const _RoleCard({required this.config, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: config.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  config.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: config.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            config.shortPermissions,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search + filter bar ───────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _UserFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_UserFilter> onFilterChanged;

  const _SearchFilterBar({
    required this.searchCtrl,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un membre...',
              hintStyle:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          Row(
            children: _UserFilter.values.map((f) {
              final label = switch (f) {
                _UserFilter.all => 'Tous',
                _UserFilter.active => 'Actifs',
                _UserFilter.inactive => 'Inactifs',
              };
              final isSelected = f == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged(f),
                  selectedColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── User row ──────────────────────────────────────────────────────────────────

class _UserRow extends ConsumerWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRoleChanged;

  const _UserRow({
    super.key,
    required this.user,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = user['userId'] as String? ?? '';
    final fullName = user['fullName'] as String?;
    final email = user['email'] as String? ?? '—';
    final role = user['role'] as String? ?? '';
    final isActive = (user['isActive'] as bool?) ?? true;
    final lastLoginStr = user['lastLoginAt'] as String?;

    final displayName =
        (fullName != null && fullName.isNotEmpty) ? fullName : email;
    final initials = _initials(displayName);
    final config = _roleConfig(role);
    final tenantId = ref.read(activeTenantProvider) ?? '';

    String lastLogin = '—';
    if (lastLoginStr != null) {
      final dt = DateTime.tryParse(lastLoginStr);
      if (dt != null) lastLogin = DateFormat('dd MMM', 'fr_FR').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: config.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (fullName != null && fullName.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Last login
          if (lastLogin != '—') ...[
            Text(
              lastLogin,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
          ],

          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              config.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: config.color,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status dot
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Actions (only for non-owner)
          if (role != 'owner')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit / change role
                InkWell(
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeamMemberFormScreen(existingUser: user),
                      ),
                    );
                    if (changed == true) onRoleChanged();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                // Disable / enable
                InkWell(
                  onTap: () =>
                      _confirmDisable(context, ref, tenantId, userId,
                          displayName, isActive),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 16,
                      color: isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDisable(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    String userId,
    String name,
    bool isActive,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? 'Désactiver $name ?' : 'Réactiver $name ?'),
        content: Text(isActive
            ? 'Ce compte sera désactivé. L\'employé ne pourra plus se connecter.'
            : 'Ce compte sera réactivé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isActive ? AppColors.error : AppColors.success,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isActive ? 'Désactiver' : 'Réactiver'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      await http.patch(
        Uri.parse(
            '${ApiConstants.baseUrl}/organizations/$tenantId/members/$userId'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
        body: jsonEncode({'isActive': !isActive}),
      );
      if (context.mounted) onRoleChanged();
    } catch (_) {
      // Silent — refresh will show current state
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final _UserFilter filter;
  const _EmptyState({required this.isSearch, required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = isSearch
        ? 'Aucun résultat pour cette recherche.'
        : filter == _UserFilter.inactive
            ? 'Aucun compte inactif pour le moment.'
            : 'Aucun membre dans l\'équipe.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
