class CreateTenantDto {
  final String name;
  final String ownerEmail;
  final String ownerPassword;
  final String currency;
  final String timezone;

  const CreateTenantDto({
    required this.name,
    required this.ownerEmail,
    required this.ownerPassword,
    this.currency = 'XOF',
    this.timezone = 'Africa/Abidjan',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'ownerEmail': ownerEmail,
        'ownerPassword': ownerPassword,
        'currency': currency,
        'timezone': timezone,
      };
}
