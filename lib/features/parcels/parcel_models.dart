import '../orders/order.dart' show OrderStatusEvent;

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
double? _numOrNull(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty) return null;
  return double.tryParse(s);
}

class Parcel {
  const Parcel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.pickupLine1,
    required this.pickupCity,
    required this.dropoffLine1,
    required this.dropoffCity,
    required this.packageSize,
    required this.description,
    required this.photo,
    required this.declaredValue,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  final int id;
  final String recipientName;
  final String recipientPhone;
  final String pickupLine1;
  final String pickupCity;
  final String dropoffLine1;
  final String dropoffCity;
  final String packageSize;
  final String description;
  final String? photo;
  final double? declaredValue;
  final String status;
  final double price;
  final DateTime? createdAt;

  bool get isCancelled => status.toLowerCase().contains('cancel');
  bool get isDelivered => status.toLowerCase().contains('deliver');

  factory Parcel.fromJson(Map<String, dynamic> json) => Parcel(
    id: json['id'] as int,
    recipientName: json['recipient_name'] as String? ?? '',
    recipientPhone: json['recipient_phone'] as String? ?? '',
    pickupLine1: json['pickup_line1'] as String? ?? '',
    pickupCity: json['pickup_city'] as String? ?? '',
    dropoffLine1: json['dropoff_line1'] as String? ?? '',
    dropoffCity: json['dropoff_city'] as String? ?? '',
    packageSize: json['package_size'] as String? ?? '',
    description: json['description'] as String? ?? '',
    photo: json['photo'] as String?,
    declaredValue: _numOrNull(json['declared_value']),
    status: json['status'] as String? ?? '',
    price: _num(json['price']),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

class ParcelTracking {
  const ParcelTracking({required this.status, required this.statusHistory, required this.tripId});

  final String status;
  final List<OrderStatusEvent> statusHistory;

  /// The trip this parcel is assigned to, for `POST trips/{id}/rate-rider/`
  /// once delivered — not documented on this endpoint, so tried under a
  /// couple of plausible key names; `null` just hides the "rate your
  /// rider" prompt rather than breaking anything.
  final int? tripId;

  factory ParcelTracking.fromJson(Map<String, dynamic> json) => ParcelTracking(
    status: json['status'] as String? ?? '',
    statusHistory: (json['status_history'] as List<dynamic>? ?? [])
        .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    tripId: json['trip_id'] as int? ?? (json['trip'] as Map<String, dynamic>?)?['id'] as int?,
  );
}
