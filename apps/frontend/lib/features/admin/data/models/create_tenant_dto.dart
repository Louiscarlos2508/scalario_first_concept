class CreateTenantDto {
  final String name;
  final String ownerEmail;
  final String ownerPassword;
  final String currency;
  final String timezone;
  final String billingStatus;
  final String plan;
  final String businessType;
  final String vertical;

  const CreateTenantDto({
    required this.name,
    required this.ownerEmail,
    required this.ownerPassword,
    this.currency = 'XOF',
    this.timezone = 'Africa/Ouagadougou',
    this.billingStatus = 'trial',
    this.plan = 'standard',
    this.businessType = 'generaliste',
    this.vertical = 'retail',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'ownerEmail': ownerEmail,
        'ownerPassword': ownerPassword,
        'currency': currency,
        'timezone': timezone,
        'billingStatus': billingStatus,
        'plan': plan,
        'businessType': businessType,
        'vertical': vertical,
      };
}
