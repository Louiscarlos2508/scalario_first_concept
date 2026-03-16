class TenantMembership {
  final String tenantId;
  final String role;
  final String? tenantName;

  TenantMembership({
    required this.tenantId,
    required this.role,
    this.tenantName,
  });
}

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final List<TenantMembership> memberships;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.memberships,
  });

  String get primaryTenantId => memberships.first.tenantId;

  // Convenience getters for existing code
  String get role => memberships.first.role;
  String get tenantId => memberships.first.tenantId;

  factory UserProfile.fromMemberships(List<Map<String, dynamic>> memberRows, String email, String userId) {
    final memberships = memberRows.map((row) => TenantMembership(
      tenantId: row['organization_id'] as String,
      role: (row['role'] as Map?)?['name'] as String? ?? row['role_id'] as String,
      tenantName: row['tenant']?['name'] as String?,
    )).toList();

    return UserProfile(
      id: userId,
      email: email,
      fullName: memberRows.first['full_name'] as String?,
      memberships: memberships,
    );
  }
}
