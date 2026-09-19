double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// An option a customer can pick at checkout, from `GET /delivery-methods/`.
class DeliveryMethod {
  const DeliveryMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.etaDaysMin,
    required this.etaDaysMax,
  });

  final int id;
  final String name;
  final String code;
  final double price;
  final int etaDaysMin;
  final int etaDaysMax;

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) => DeliveryMethod(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    price: _num(json['price']),
    etaDaysMin: json['eta_days_min'] as int? ?? 0,
    etaDaysMax: json['eta_days_max'] as int? ?? 0,
  );
}
