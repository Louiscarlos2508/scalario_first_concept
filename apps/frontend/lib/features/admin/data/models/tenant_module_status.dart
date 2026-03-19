class TenantModuleStatus {
  final String moduleCode;
  final String name;
  final String type; // 'shared' | 'vertical'
  final String status; // 'active' | 'inactive'
  final String? activatedAt;
  final List<String> dependencies;

  const TenantModuleStatus({
    required this.moduleCode,
    required this.name,
    required this.type,
    required this.status,
    this.activatedAt,
    this.dependencies = const [],
  });

  bool get isActive => status == 'active';

  factory TenantModuleStatus.fromJson(Map<String, dynamic> json) {
    return TenantModuleStatus(
      moduleCode: json['moduleCode'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'shared',
      status: json['status'] as String? ?? 'inactive',
      activatedAt: json['activatedAt'] as String?,
      dependencies: List<String>.from(json['dependencies'] as List? ?? []),
    );
  }
}
