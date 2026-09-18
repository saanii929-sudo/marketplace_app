import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'seller_application.dart';
import 'sellers_api.dart';

final sellersApiProvider = Provider<SellersApi>((ref) => SellersApi(ref.watch(dioProvider)));

/// `null` means the caller hasn't applied to sell yet.
final sellerApplicationStatusProvider = FutureProvider<SellerApplicationStatus?>(
  (ref) => ref.read(sellersApiProvider).getStatus(),
);
