import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'rider_models.dart';
import 'riders_api.dart';

final ridersApiProvider = Provider<RidersApi>((ref) => RidersApi(ref.watch(dioProvider)));

/// `null` means the rider hasn't set up their vehicle details yet.
final riderVehicleProvider = FutureProvider<RiderVehicle?>((ref) => ref.read(ridersApiProvider).getVehicle());

final riderVerificationStatusProvider = FutureProvider<RiderVerificationStatus?>(
  (ref) => ref.read(ridersApiProvider).getVerificationStatus(),
);

/// `null` means no delivery is currently in progress.
final riderActiveDeliveryProvider = FutureProvider<RiderDelivery?>(
  (ref) => ref.read(ridersApiProvider).getActiveDelivery(),
);

final riderDeliveriesProvider = FutureProvider<List<RiderDelivery>>(
  (ref) => ref.read(ridersApiProvider).getDeliveries(),
);

final riderEarningsSummaryProvider = FutureProvider<RiderEarningsSummary>(
  (ref) => ref.read(ridersApiProvider).getEarningsSummary(),
);

final riderEarningsActivityProvider = FutureProvider<List<RiderActivityEntry>>(
  (ref) => ref.read(ridersApiProvider).getEarningsActivity(),
);

final riderPayoutMethodsProvider = FutureProvider<List<RiderPayoutMethod>>(
  (ref) => ref.read(ridersApiProvider).getPayoutMethods(),
);

final riderReviewsProvider = FutureProvider<List<RiderReview>>((ref) => ref.read(ridersApiProvider).getReviews());

final riderReviewSummaryProvider = FutureProvider<RiderReviewSummary>(
  (ref) => ref.read(ridersApiProvider).getReviewSummary(),
);

final riderDocumentsProvider = FutureProvider<List<RiderDocument>>(
  (ref) => ref.read(ridersApiProvider).getDocuments(),
);
