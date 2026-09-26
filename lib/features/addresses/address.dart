double? _numOrNull(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty) return null;
  return double.tryParse(s);
}

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
    required this.lat,
    required this.lng,
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

  /// **Unconfirmed** — `accounts/addresses/` has never been verified to
  /// accept or return `lat`/`lng`. Always nullable/defensive: if the
  /// backend silently drops these, the app just falls back to GPS/manual
  /// pin-per-booking instead of crashing or trusting a bogus 0.0 default.
  final double? lat;
  final double? lng;

  bool get hasPin => lat != null && lng != null;

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
    lat: _numOrNull(json['lat']),
    lng: _numOrNull(json['lng']),
  );
}
