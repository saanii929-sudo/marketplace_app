class Address {
  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.region,
    required this.country,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String country;
  final bool isDefault;

  String get fullAddress => [
    line1,
    if (line2.isNotEmpty) line2,
    city,
    region,
  ].where((s) => s.isNotEmpty).join(', ');

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as int,
    label: json['label'] as String? ?? '',
    recipientName: json['recipient_name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    line1: json['line1'] as String? ?? '',
    line2: json['line2'] as String? ?? '',
    city: json['city'] as String? ?? '',
    region: json['region'] as String? ?? '',
    country: json['country'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );
}
