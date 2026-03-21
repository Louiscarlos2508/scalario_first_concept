class BusinessTypeSummary {
  final String code;
  final String name;
  final String? description;
  final Map<String, dynamic> defaultFlags;
  final List<String> visibleSections;
  final List<String> suggestedCategories;
  final String? icon;
  final bool isActive;
  final String vertical;
  final Map<String, dynamic> roleLabels;
  final String? documentType;

  const BusinessTypeSummary({
    required this.code,
    required this.name,
    this.description,
    required this.defaultFlags,
    required this.visibleSections,
    required this.suggestedCategories,
    this.icon,
    this.isActive = true,
    this.vertical = 'retail',
    this.roleLabels = const {},
    this.documentType,
  });

  factory BusinessTypeSummary.fromJson(Map<String, dynamic> json) {
    return BusinessTypeSummary(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      defaultFlags: (json['defaultFlags'] as Map<String, dynamic>?) ?? {},
      visibleSections: List<String>.from(json['visibleSections'] as List? ?? []),
      suggestedCategories: List<String>.from(json['suggestedCategories'] as List? ?? []),
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      vertical: json['vertical'] as String? ?? 'retail',
      roleLabels: (json['roleLabels'] as Map<String, dynamic>?) ?? {},
      documentType: json['documentType'] as String?,
    );
  }
}
