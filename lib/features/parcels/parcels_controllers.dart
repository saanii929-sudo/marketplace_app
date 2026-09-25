import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'parcel_models.dart';
import 'parcels_api.dart';

final parcelsApiProvider = Provider<ParcelsApi>((ref) => ParcelsApi(ref.watch(dioProvider)));

final parcelsProvider = FutureProvider<List<Parcel>>((ref) => ref.read(parcelsApiProvider).getParcels());

final parcelTrackingProvider = FutureProvider.family<ParcelTracking?, int>(
  (ref, id) => ref.read(parcelsApiProvider).getTracking(id),
);
