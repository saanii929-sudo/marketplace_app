import '../orders/order.dart';

/// `GET /checkout/hubtel/status/` — the polling fallback for when the
/// browser returns from Hubtel's hosted checkout before the
/// server-to-server webhook has landed.
class HubtelCheckoutStatus {
  const HubtelCheckoutStatus({
    required this.reference,
    required this.checkoutUrl,
    required this.status,
    required this.failureReason,
    required this.order,
  });

  final String reference;
  final String checkoutUrl;
  final String status;
  final String failureReason;
  final OrderDetail? order;

  /// The given API only shows `"pending"` as an example value — the full
  /// set of terminal values isn't documented, so success/failure are
  /// matched defensively by keyword rather than an exact string.
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuccess {
    final s = status.toLowerCase();
    return s.contains('success') || s.contains('paid') || s.contains('complete');
  }

  bool get isFailure {
    final s = status.toLowerCase();
    return s.contains('fail') || s.contains('cancel') || s.contains('expire');
  }

  factory HubtelCheckoutStatus.fromJson(Map<String, dynamic> json) => HubtelCheckoutStatus(
    reference: json['reference'] as String? ?? '',
    checkoutUrl: json['checkout_url'] as String? ?? '',
    status: json['status'] as String? ?? '',
    failureReason: json['failure_reason'] as String? ?? '',
    order: json['order'] == null ? null : OrderDetail.fromJson(json['order'] as Map<String, dynamic>),
  );
}
