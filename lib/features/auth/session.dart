import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_exception.dart';
import '../../network/token_storage.dart';
import '../addresses/addresses_controller.dart';
import '../cart/cart_controller.dart';
import '../chat/chat_controllers.dart';
import '../checkout/checkout_controllers.dart';
import '../discovery/discovery_controllers.dart';
import '../notifications/notifications_controller.dart';
import '../orders/orders_controllers.dart';
import '../parcels/parcels_controllers.dart';
import '../payments/payments_controller.dart';
import '../profile/profile_controller.dart';
import '../riders/riders_controllers.dart';
import '../wishlist/wishlist_controller.dart';
import 'auth_controller.dart';

enum SessionStatus {
  /// A valid, non-expired session for a `role == 'customer'` account.
  authenticatedCustomer,

  /// A valid, non-expired session for a `role == 'rider'` account.
  authenticatedRider,

  /// No stored session, or the stored session couldn't be confirmed right
  /// now (expired token that survived refresh, or a transient error) — the
  /// tokens are left alone in the transient-error case so a later launch
  /// with connectivity can still succeed.
  unauthenticated,

  /// A valid session, but for a role this app has no experience for
  /// (neither customer nor rider) — logged out immediately.
  wrongRole,
}

/// Resolves whether the stored session (if any) belongs to a signed-in
/// customer or rider. This app has no local cache of the user's role, so a
/// stored access token is only ever a hint — `GET /accounts/me/` is the
/// source of truth, called once here via [profileControllerProvider].
Future<SessionStatus> resolveSessionStatus(WidgetRef ref) async {
  final access = await TokenStorage.instance.readAccess();
  if (access == null || access.isEmpty) return SessionStatus.unauthenticated;

  try {
    final profile = await ref.read(profileControllerProvider.future);
    if (profile.role == 'customer') return SessionStatus.authenticatedCustomer;
    if (profile.role == 'rider') return SessionStatus.authenticatedRider;
    await ref.read(authControllerProvider.notifier).logout();
    clearUserScopedProviders(ref);
    return SessionStatus.wrongRole;
  } on ApiException {
    return SessionStatus.unauthenticated;
  }
}

/// Invalidates every provider that holds data scoped to the signed-in
/// user, so a subsequent sign-in (by the same or a different account)
/// never shows a stale cached cart/wishlist/profile/etc. left over from
/// the previous session.
void clearUserScopedProviders(WidgetRef ref) {
  ref.invalidate(profileControllerProvider);
  ref.invalidate(addressesControllerProvider);
  ref.invalidate(cartControllerProvider);
  ref.invalidate(wishlistControllerProvider);
  ref.invalidate(paymentMethodsControllerProvider);
  ref.invalidate(ordersProvider);
  ref.invalidate(orderDetailProvider);
  ref.invalidate(orderTrackingProvider);
  ref.invalidate(checkoutSummaryProvider);
  ref.invalidate(recentlyViewedProvider);
  ref.invalidate(recentSearchesProvider);
  ref.invalidate(notificationsControllerProvider);
  ref.invalidate(conversationsProvider);
  ref.invalidate(supportContactsProvider);
  ref.invalidate(riderVehicleProvider);
  ref.invalidate(riderVerificationStatusProvider);
  ref.invalidate(riderSettingsProvider);
  ref.invalidate(riderActiveDeliveryProvider);
  ref.invalidate(riderDeliveriesProvider);
  ref.invalidate(riderEarningsSummaryProvider);
  ref.invalidate(riderEarningsActivityProvider);
  ref.invalidate(riderPayoutMethodsProvider);
  ref.invalidate(riderReviewsProvider);
  ref.invalidate(riderReviewSummaryProvider);
  ref.invalidate(riderDocumentsProvider);
  ref.invalidate(parcelsProvider);
  ref.invalidate(parcelTrackingProvider);
}
