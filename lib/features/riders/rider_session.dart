import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'riders_controllers.dart';

enum RiderEntryDestination {
  home,

  documentsNeeded,

  verificationPending,
}

Future<RiderEntryDestination> resolveRiderEntryDestination(WidgetRef ref) async {
  try {
    final status = await ref.read(ridersApiProvider).getVerificationStatus();
    if (status == null) return RiderEntryDestination.documentsNeeded;
    if (status.isApproved) return RiderEntryDestination.home;
    return RiderEntryDestination.verificationPending;
  } catch (_) {
    return RiderEntryDestination.verificationPending;
  }
}
