class TenantSummary {
  final String id;
  final String name;
  final String status;
  final String currency;
  final int membersCount;
  final List<String> activeModules;
  final String plan;
  final String billingStatus;
  final String businessType;
  final String vertical;
  final DateTime? trialEndsAt;
  final DateTime? paidUntil;

  const TenantSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.currency,
    required this.membersCount,
    required this.activeModules,
    this.plan = 'free',
    this.billingStatus = 'trial',
    this.businessType = 'generaliste',
    this.vertical = 'retail',
    this.trialEndsAt,
    this.paidUntil,
  });

  factory TenantSummary.fromJson(Map<String, dynamic> json) {
    return TenantSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'active',
      currency: json['currency'] as String? ?? 'XOF',
      membersCount: json['membersCount'] as int? ?? 0,
      activeModules: List<String>.from(json['activeModules'] as List? ?? []),
      plan: json['plan'] as String? ?? 'free',
      billingStatus: json['billingStatus'] as String? ?? 'trial',
      businessType: json['businessType'] as String? ?? 'generaliste',
      vertical: json['vertical'] as String? ?? 'retail',
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'] as String)
          : null,
      paidUntil: json['paidUntil'] != null
          ? DateTime.tryParse(json['paidUntil'] as String)
          : null,
    );
  }
}
