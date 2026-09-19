import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import '../cart/cart.dart';
import 'checkout_api.dart';
import 'delivery_method.dart';
import 'hubtel_status.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi(ref.watch(dioProvider)));

/// Re-fetched each time the Checkout screen opens (see `ref.invalidate` in
/// `CheckoutScreen.initState`) so it always reflects the cart's current
/// contents rather than a stale cached read.
final checkoutSummaryProvider = FutureProvider<Cart>((ref) => ref.read(checkoutApiProvider).getSummary());

final deliveryMethodsProvider = FutureProvider<List<DeliveryMethod>>(
  (ref) => ref.read(checkoutApiProvider).getDeliveryMethods(),
);

/// Re-fetched on a timer and on app-resume by `HubtelPaymentScreen` via
/// `ref.invalidate`, keyed by the `reference` the order-placement call
/// returned (the live server requires it despite the given spec listing no
/// parameters for this endpoint).
final hubtelCheckoutStatusProvider = FutureProvider.family<HubtelCheckoutStatus, String>(
  (ref, reference) => ref.read(checkoutApiProvider).getHubtelStatus(reference),
);
