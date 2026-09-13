import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import '../cart/cart.dart';
import 'checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi(ref.watch(dioProvider)));

/// Re-fetched each time the Checkout screen opens (see `ref.invalidate` in
/// `CheckoutScreen.initState`) so it always reflects the cart's current
/// contents rather than a stale cached read.
final checkoutSummaryProvider = FutureProvider<Cart>((ref) => ref.read(checkoutApiProvider).getSummary());
