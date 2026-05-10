/// Immutable snapshot of the authenticated user's runtime context.
///
/// Populated from JWT public claims by the Auth layer (STORY-009).
/// This class is consumed by [RuleEvaluator] — it knows nothing about
/// network, sessions, or persistence.
///
/// SECURITY: Store only public claims here (roles, tenant, department).
/// Never store passwords, raw JWT tokens, or private attributes.
/// The real security enforcement is backend-side (FR-010 RBAC Guards,
/// FR-011 PostgreSQL RLS). See architecture line 858 (NFR-003).
///
/// AC-04: immutable, constructible from JWT claims.
library;

import 'package:meta/meta.dart';

/// Immutable runtime identity of the current user for BDUI rule evaluation.
@immutable
final class UserContext {
  const UserContext({
    required this.userId,
    required this.tenantId,
    required this.roles,
    this.departmentId,
    this.attributes = const {},
  });

  /// Stable user identifier (UUID from JWT `sub`).
  final String userId;

  /// Tenant the user belongs to (multi-tenant isolation).
  final String tenantId;

  /// Set of role strings assigned to the user (e.g. {'MANAGER', 'CASHIER'}).
  final Set<String> roles;

  /// Optional department identifier for departmental access rules.
  final String? departmentId;

  /// Arbitrary key→value context from JWT custom claims or local state.
  /// Examples: feature flags, plan tier, per-tenant feature toggles.
  final Map<String, Object?> attributes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserContext) return false;
    return userId == other.userId &&
        tenantId == other.tenantId &&
        departmentId == other.departmentId &&
        _setEquals(roles, other.roles) &&
        _mapEquals(attributes, other.attributes);
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(userId, tenantId, departmentId);

  @override
  String toString() =>
      'UserContext(userId: $userId, tenantId: $tenantId, roles: $roles)';
}
