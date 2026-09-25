/// A rider's own vehicle info, from `GET`/`PATCH /riders/vehicle/`.
///
/// Neither endpoint's request/response body is documented in the given API
/// (both show "No response body" in the spec) — every field here is
/// therefore optional/defaulted so an unexpected shape degrades to blank
/// fields instead of a crash. The field names assumed are the vehicle
/// fields `POST /riders/register/` already documents, since that's the
/// only plausible shape for a sibling "vehicle" endpoint.
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

  factory RiderVehicle.fromJson(Map<String, dynamic> json) => RiderVehicle(
    vehicleType: json['vehicle_type'] as String? ?? 'bicycle',
    vehicleMake: json['vehicle_make'] as String? ?? '',
    vehicleModel: json['vehicle_model'] as String? ?? '',
    plateNumber: json['plate_number'] as String? ?? '',
    color: json['color'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'vehicle_type': vehicleType,
    'vehicle_make': vehicleMake,
    'vehicle_model': vehicleModel,
    'plate_number': plateNumber,
    'color': color,
  };
}

/// The rider's own verification status, from
/// `GET /riders/verification-status/` — undocumented response body in the
/// given spec, so only a generic `status` string is read (trying a couple
/// of plausible key names), matching the "defensive status-string" pattern
/// already used elsewhere in this app (e.g. order/Hubtel status).
class RiderVerificationStatus {
  const RiderVerificationStatus({required this.status});

  final String status;

  bool get isApproved {
    final s = status.toLowerCase();
    return s.contains('approve') || s.contains('verified');
  }

  bool get isRejected => status.toLowerCase().contains('reject');

  factory RiderVerificationStatus.fromJson(Map<String, dynamic> json) => RiderVerificationStatus(
    status: json['status'] as String? ?? json['verification_status'] as String? ?? '',
  );
}

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// The 4 documents the onboarding upload screen collects and the profile's
/// Documents screen displays — shared here so both stay in sync on the
/// (`document_type` value, display label) pairing.
const riderDocumentTypes = [
  ('government_id', 'Government ID'),
  ('drivers_license', 'Driver\'s licence'),
  ('vehicle_registration', 'Vehicle registration'),
  ('profile_photo', 'Profile photo'),
];

/// A pending delivery request pushed over the dispatch WebSocket as
/// `{"type": "delivery_request", "request": {...}}`. None of these field
/// names were confirmed against a live response yet — this is the exact
/// shape from the endpoint spec handed to the backend dev.
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

/// A rider's own delivery — returned by accept, the active-delivery check,
/// and the deliveries-history list.
class RiderDelivery {
  const RiderDelivery({
    required this.id,
    required this.kind,
    required this.reference,
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.rating,
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
  final double amount;
  final String status;
  final double? rating;
  final DateTime? completedAt;

  bool get isDelivered => status.toLowerCase().contains('deliver');
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
    amount: _num(json['amount']),
    status: json['status'] as String? ?? '',
    rating: json['rating'] == null ? null : _num(json['rating']),
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
    documentType: json['document_type'] as String? ?? '',
    status: json['status'] as String? ?? '',
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    fileUrl: json['file_url'] as String?,
  );
}
