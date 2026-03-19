class TenantHealthStatus {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final int membersCount;
  final DateTime? lastActivityAt;
  final int failedMutationsCount;

  const TenantHealthStatus({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.membersCount,
    this.lastActivityAt,
    required this.failedMutationsCount,
  });

  factory TenantHealthStatus.fromJson(Map<String, dynamic> json) {
    return TenantHealthStatus(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      membersCount: json['membersCount'] as int,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      failedMutationsCount: json['failedMutationsCount'] as int,
    );
  }
}

class MonitoringHealth {
  final int activeTenants;
  final int totalUsers;
  final List<TenantHealthStatus> tenants;

  const MonitoringHealth({
    required this.activeTenants,
    required this.totalUsers,
    required this.tenants,
  });

  factory MonitoringHealth.fromJson(Map<String, dynamic> json) {
    return MonitoringHealth(
      activeTenants: json['activeTenants'] as int,
      totalUsers: json['totalUsers'] as int,
      tenants: (json['tenants'] as List<dynamic>)
          .map((t) => TenantHealthStatus.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
