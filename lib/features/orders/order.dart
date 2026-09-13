double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

/// Humanizes a raw status string (e.g. `out_for_delivery` → `Out for
/// delivery`) — the given API never enumerates its full set of status
/// values, so this displays whatever the server actually sends rather
/// than forcing it into a guessed fixed set.
String humanizeStatus(String status) {
  if (status.isEmpty) return 'Processing';
  final words = status.split('_');
  return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class DeliveryMethodRef {
  const DeliveryMethodRef({
    required this.id,
    required this.name,
    required this.price,
    required this.etaDaysMin,
    required this.etaDaysMax,
  });

  final int id;
  final String name;
  final double price;
  final int etaDaysMin;
  final int etaDaysMax;

  factory DeliveryMethodRef.fromJson(Map<String, dynamic> json) => DeliveryMethodRef(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    price: _num(json['price']),
    etaDaysMin: json['eta_days_min'] as int? ?? 0,
    etaDaysMax: json['eta_days_max'] as int? ?? 0,
  );
}

class OrderPaymentMethodRef {
  const OrderPaymentMethodRef({required this.id, required this.name});

  final int id;
  final String name;

  factory OrderPaymentMethodRef.fromJson(Map<String, dynamic> json) =>
      OrderPaymentMethodRef(id: json['id'] as int? ?? 0, name: json['name'] as String? ?? '');
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String productName;
  final String productSlug;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as int? ?? 0,
    productId: json['product'] as int? ?? 0,
    productName: json['product_name'] as String? ?? '',
    productSlug: json['product_slug'] as String? ?? '',
    qty: json['qty'] as int? ?? 1,
    unitPrice: _num(json['unit_price']),
    lineTotal: _num(json['line_total']),
  );
}

class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.gateway,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  final int id;
  final String gateway;
  final String status;
  final double amount;
  final DateTime? createdAt;

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
    id: json['id'] as int? ?? 0,
    gateway: json['gateway'] as String? ?? '',
    status: json['status'] as String? ?? '',
    amount: _num(json['amount']),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

/// Slim shape from `GET /orders/` (the list/history view).
class OrderSummary {
  const OrderSummary({required this.orderNumber, required this.status, required this.total, required this.placedAt});

  final String orderNumber;
  final String status;
  final double total;
  final DateTime? placedAt;

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    orderNumber: json['order_number'] as String? ?? '',
    status: json['status'] as String? ?? '',
    total: _num(json['total']),
    placedAt: DateTime.tryParse(json['placed_at'] as String? ?? ''),
  );
}

/// Full shape from `GET /orders/{order_number}/` (and echoed by
/// create/cancel).
class OrderDetail {
  const OrderDetail({
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.deliveryRecipientName,
    required this.deliveryPhone,
    required this.deliveryLine1,
    required this.deliveryLine2,
    required this.deliveryCity,
    required this.deliveryRegion,
    required this.deliveryCountry,
    required this.items,
    required this.payments,
    required this.placedAt,
  });

  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final DeliveryMethodRef? deliveryMethod;
  final OrderPaymentMethodRef? paymentMethod;
  final String deliveryRecipientName;
  final String deliveryPhone;
  final String deliveryLine1;
  final String deliveryLine2;
  final String deliveryCity;
  final String deliveryRegion;
  final String deliveryCountry;
  final List<OrderItem> items;
  final List<OrderPayment> payments;
  final DateTime? placedAt;

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get deliveryAddress => [
    deliveryLine1,
    if (deliveryLine2.isNotEmpty) deliveryLine2,
    deliveryCity,
    deliveryRegion,
  ].where((s) => s.isNotEmpty).join(', ');

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    orderNumber: json['order_number'] as String? ?? '',
    status: json['status'] as String? ?? '',
    subtotal: _num(json['subtotal']),
    deliveryFee: _num(json['delivery_fee']),
    discountAmount: _num(json['discount_amount']),
    total: _num(json['total']),
    deliveryMethod: json['delivery_method'] == null
        ? null
        : DeliveryMethodRef.fromJson(json['delivery_method'] as Map<String, dynamic>),
    paymentMethod: json['payment_method'] == null
        ? null
        : OrderPaymentMethodRef.fromJson(json['payment_method'] as Map<String, dynamic>),
    deliveryRecipientName: json['delivery_recipient_name'] as String? ?? '',
    deliveryPhone: json['delivery_phone'] as String? ?? '',
    deliveryLine1: json['delivery_line1'] as String? ?? '',
    deliveryLine2: json['delivery_line2'] as String? ?? '',
    deliveryCity: json['delivery_city'] as String? ?? '',
    deliveryRegion: json['delivery_region'] as String? ?? '',
    deliveryCountry: json['delivery_country'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? []).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    payments: (json['payments'] as List<dynamic>? ?? [])
        .map((e) => OrderPayment.fromJson(e as Map<String, dynamic>))
        .toList(),
    placedAt: DateTime.tryParse(json['placed_at'] as String? ?? ''),
  );
}

class OrderStatusEvent {
  const OrderStatusEvent({required this.status, required this.note, required this.createdAt});

  final String status;
  final String note;
  final DateTime? createdAt;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
    status: json['status'] as String? ?? '',
    note: json['note'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

class ShipmentInfo {
  const ShipmentInfo({required this.courierName, required this.trackingNumber, required this.currentStatus});

  final String courierName;
  final String trackingNumber;
  final String currentStatus;

  factory ShipmentInfo.fromJson(Map<String, dynamic> json) => ShipmentInfo(
    courierName: json['courier_name'] as String? ?? '',
    trackingNumber: json['tracking_number'] as String? ?? '',
    currentStatus: json['current_status'] as String? ?? '',
  );
}

class OrderTracking {
  const OrderTracking({required this.status, required this.statusHistory, required this.shipment});

  final String status;
  final List<OrderStatusEvent> statusHistory;
  final ShipmentInfo? shipment;

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
    status: json['status'] as String? ?? '',
    statusHistory: (json['status_history'] as List<dynamic>? ?? [])
        .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    shipment: json['shipment'] == null ? null : ShipmentInfo.fromJson(json['shipment'] as Map<String, dynamic>),
  );
}
