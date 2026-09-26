class RiderVehicle {
  const RiderVehicle({
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.plateNumber,
    required this.color,
  });

  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String plateNumber;
  final String color;

  static const empty = RiderVehicle(vehicleType: 'bicycle', vehicleMake: '', vehicleModel: '', plateNumber: '', color: '');

  /// Confirmed real (`GET riders/vehicle/` response) — the server's fields
  /// are `type`/`make`/`model`, not `vehicle_type`/`vehicle_make`/`vehicle_model`.
  factory RiderVehicle.fromJson(Map<String, dynamic> json) => RiderVehicle(
    vehicleType: json['type'] as String? ?? json['vehicle_type'] as String? ?? 'bicycle',
    vehicleMake: json['make'] as String? ?? json['vehicle_make'] as String? ?? '',
    vehicleModel: json['model'] as String? ?? json['vehicle_model'] as String? ?? '',
    plateNumber: json['plate_number'] as String? ?? '',
    color: json['color'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': vehicleType,
    'make': vehicleMake,
    'model': vehicleModel,
    'plate_number': plateNumber,
    'color': color,
  };
}

/// `GET riders/verification-status/` — confirmed real shape:
/// `{is_verified, documents: [{doc_type, status, expires_at, ...}]}`.
/// There's no aggregate status string; overall approval is the `is_verified`
/// boolean, and rejection is inferred from the per-document statuses.
class RiderVerificationStatus {
  const RiderVerificationStatus({required this.isVerified, required this.documents});

  final bool isVerified;
  final List<RiderDocument> documents;

  bool get isApproved => isVerified;
  bool get isRejected => documents.any((d) => d.isRejected);

  factory RiderVerificationStatus.fromJson(Map<String, dynamic> json) => RiderVerificationStatus(
    isVerified: json['is_verified'] as bool? ?? false,
    documents: (json['documents'] as List<dynamic>? ?? [])
        .map((e) => RiderDocument.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

const riderDocumentTypes = [
  ('government_id', 'Government ID'),
  ('drivers_licence', 'Driver\'s licence'),
  ('vehicle_registration', 'Vehicle registration'),
  ('profile_photo', 'Profile photo'),
];

class RiderDeliveryRequest {
  const RiderDeliveryRequest({
    required this.id,
    required this.kind,
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.amount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.itemCount,
  });

  final int id;
  final String kind;
  final String pickupLabel;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final double amount;
  final double distanceKm;
  final int etaMinutes;
  final int itemCount;

  String get kindLabel => kind.isEmpty ? 'Delivery' : '${kind[0].toUpperCase()}${kind.substring(1)}';

  factory RiderDeliveryRequest.fromJson(Map<String, dynamic> json) => RiderDeliveryRequest(
    id: json['id'] as int,
    kind: json['kind'] as String? ?? '',
    pickupLabel: json['pickup_label'] as String? ?? '',
    pickupAddress: json['pickup_address'] as String? ?? '',
    dropoffAddress: json['dropoff_address'] as String? ?? '',
    customerName: json['customer_name'] as String? ?? '',
    amount: _num(json['amount']),
    distanceKm: _num(json['distance_km']),
    etaMinutes: json['eta_minutes'] as int? ?? 0,
    itemCount: json['item_count'] as int? ?? 0,
  );
}

class RiderDelivery {
  const RiderDelivery({
    required this.id,
    required this.kind,
    required this.reference,
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.distanceKm,
    required this.status,
    required this.rating,
    required this.pickedUpAt,
    required this.completedAt,
  });

  final int id;
  final String kind;

  /// The underlying order number or parcel id, whichever the server sends.
  final String reference;
  final String pickupLabel;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final String customerPhone;
  final double amount;
  final double distanceKm;
  final String status;
  final double? rating;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;

  /// Confirmed real values (backend dev, `Trip.Status`) for the active
  /// delivery payload — `heading_to_pickup`, `picked_up`, `heading_to_dropoff`.
  bool get isHeadingToPickup => status == 'heading_to_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isHeadingToDropoff => status == 'heading_to_dropoff';

  bool get isDelivered => status.toLowerCase().contains('deliver') && !isHeadingToDropoff;
  bool get isCancelled => status.toLowerCase().contains('cancel');

  factory RiderDelivery.fromJson(Map<String, dynamic> json) => RiderDelivery(
    id: json['id'] as int,
    kind: json['kind'] as String? ?? '',
    reference:
        json['reference'] as String? ??
        json['order_number'] as String? ??
        json['parcel_id']?.toString() ??
        '',
    pickupLabel: json['pickup_label'] as String? ?? '',
    pickupAddress: json['pickup_address'] as String? ?? '',
    dropoffAddress: json['dropoff_address'] as String? ?? '',
    customerName: json['customer_name'] as String? ?? '',
    customerPhone: json['customer_phone'] as String? ?? '',
    amount: _num(json['amount']),
    distanceKm: _num(json['distance_km']),
    status: json['status'] as String? ?? '',
    rating: json['rating'] == null ? null : _num(json['rating']),
    pickedUpAt: DateTime.tryParse(json['picked_up_at'] as String? ?? ''),
    completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
  );
}

class RiderEarningsSummary {
  const RiderEarningsSummary({
    required this.availableBalance,
    required this.todayEarnings,
    required this.tripsToday,
    required this.onlineHoursToday,
    required this.week,
    required this.totalTrips,
    required this.avgPerTrip,
  });

  final double availableBalance;
  final double todayEarnings;
  final int tripsToday;
  final double onlineHoursToday;

  /// 7 daily totals, Monday first.
  final List<double> week;
  final int totalTrips;
  final double avgPerTrip;

  factory RiderEarningsSummary.fromJson(Map<String, dynamic> json) => RiderEarningsSummary(
    availableBalance: _num(json['available_balance']),
    todayEarnings: _num(json['today_earnings']),
    tripsToday: json['trips_today'] as int? ?? 0,
    onlineHoursToday: _num(json['online_hours_today']),
    week: (json['week'] as List<dynamic>? ?? []).map(_num).toList(),
    totalTrips: json['total_trips'] as int? ?? 0,
    avgPerTrip: _num(json['avg_per_trip']),
  );
}

class RiderActivityEntry {
  const RiderActivityEntry({required this.type, required this.label, required this.amount, required this.createdAt});

  final String type;
  final String label;
  final double amount;
  final DateTime? createdAt;

  bool get isCashOut => type.toLowerCase().contains('cash');

  factory RiderActivityEntry.fromJson(Map<String, dynamic> json) => RiderActivityEntry(
    type: json['type'] as String? ?? '',
    label: json['label'] as String? ?? '',
    amount: _num(json['amount']),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

class RiderPayoutMethod {
  const RiderPayoutMethod({required this.id, required this.title, required this.subtitle, required this.isDefault});

  final int id;
  final String title;
  final String subtitle;
  final bool isDefault;

  factory RiderPayoutMethod.fromJson(Map<String, dynamic> json) => RiderPayoutMethod(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );
}

class RiderReview {
  const RiderReview({required this.reviewerName, required this.rating, required this.comment, required this.createdAt});

  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory RiderReview.fromJson(Map<String, dynamic> json) => RiderReview(
    reviewerName: json['reviewer_name'] as String? ?? 'Anonymous',
    rating: json['rating'] as int? ?? 0,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

class RiderReviewSummary {
  const RiderReviewSummary({required this.average, required this.breakdown});

  final double average;

  /// Star count (5..1) → percent.
  final Map<int, int> breakdown;

  factory RiderReviewSummary.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['breakdown'] as Map<String, dynamic>? ?? {};
    return RiderReviewSummary(
      average: _num(json['average']),
      breakdown: {
        for (final entry in breakdownJson.entries) int.tryParse(entry.key) ?? 0: (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }
}

class RiderSettings {
  const RiderSettings({
    required this.isOnline,
    required this.isVerified,
    required this.ratingAvg,
    required this.acceptanceRate,
    required this.minTripValue,
    required this.pushNotificationsEnabled,
    required this.emailOffersEnabled,
  });

  final bool isOnline;
  final bool isVerified;
  final double ratingAvg;
  final double acceptanceRate;
  final double minTripValue;
  final bool pushNotificationsEnabled;
  final bool emailOffersEnabled;

  String get formattedAcceptanceRate {
    final pct = acceptanceRate <= 1 ? acceptanceRate * 100 : acceptanceRate;
    return '${pct.toStringAsFixed(0)}%';
  }

  factory RiderSettings.fromJson(Map<String, dynamic> json) => RiderSettings(
    isOnline: json['is_online'] as bool? ?? false,
    isVerified: json['is_verified'] as bool? ?? false,
    ratingAvg: _num(json['rating_avg']),
    acceptanceRate: _num(json['acceptance_rate']),
    minTripValue: _num(json['min_trip_value']),
    pushNotificationsEnabled: json['push_notifications_enabled'] as bool? ?? true,
    emailOffersEnabled: json['email_offers_enabled'] as bool? ?? false,
  );
}

class RiderDocument {
  const RiderDocument({
    required this.documentType,
    required this.status,
    required this.expiresAt,
    required this.fileUrl,
  });

  final String documentType;
  final String status;
  final DateTime? expiresAt;
  final String? fileUrl;

  bool get isVerified => status.toLowerCase().contains('verif') || status.toLowerCase().contains('approve');
  bool get isRejected => status.toLowerCase().contains('reject');

  factory RiderDocument.fromJson(Map<String, dynamic> json) => RiderDocument(
    documentType: json['doc_type'] as String? ?? json['document_type'] as String? ?? '',
    status: json['status'] as String? ?? '',
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    fileUrl: json['file'] as String? ?? json['file_url'] as String?,
  );
}
