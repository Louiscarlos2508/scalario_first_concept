class TenantUser {
  final String userId;
  final String email;
  final String role;
  final String? createdAt;
  final String? lastSignInAt;

  const TenantUser({
    required this.userId,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastSignInAt,
  });

  factory TenantUser.fromJson(Map<String, dynamic> json) {
    return TenantUser(
      userId: json['userId'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] as String?,
      lastSignInAt: json['lastSignInAt'] as String?,
    );
  }
}
