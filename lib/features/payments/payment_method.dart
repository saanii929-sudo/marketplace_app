enum PaymentType { visa, mastercard, momo, other }

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.gateway,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
  });

  final int id;
  final String gateway;
  final String brand;
  final String last4;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;

  /// Best-effort mapping to a known card network for [PaymentCardLogo] —
  /// the real API only gives free-text `brand`/`gateway` strings, no
  /// enumerated network type.
  PaymentType get type {
    final b = brand.toLowerCase();
    if (b.contains('visa')) return PaymentType.visa;
    if (b.contains('master')) return PaymentType.mastercard;
    final g = gateway.toLowerCase();
    if (g.contains('momo') || g.contains('hubtel') || b.contains('momo')) return PaymentType.momo;
    return PaymentType.other;
  }

  String get subtitle =>
      expiryMonth != null && expiryYear != null
          ? 'Expires ${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear! % 100).toString().padLeft(2, '0')}'
          : gateway.isNotEmpty
          ? gateway
          : 'Saved payment method';

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as int,
    gateway: json['gateway'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    last4: json['last4'] as String? ?? '',
    expiryMonth: json['expiry_month'] as int?,
    expiryYear: json['expiry_year'] as int?,
    isDefault: json['is_default'] as bool? ?? false,
  );
}
