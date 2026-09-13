import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'wishlist.dart';
import 'wishlist_api.dart';

final wishlistApiProvider = Provider<WishlistApi>((ref) => WishlistApi(ref.watch(dioProvider)));

class WishlistController extends AsyncNotifier<List<WishlistEntry>> {
  @override
  Future<List<WishlistEntry>> build() => ref.read(wishlistApiProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(wishlistApiProvider).list());
  }

  Future<void> toggle(int productId) async {
    await ref.read(wishlistApiProvider).toggle(productId);
    await refresh();
  }
}

final wishlistControllerProvider = AsyncNotifierProvider<WishlistController, List<WishlistEntry>>(
  WishlistController.new,
);

extension WishlistLookup on List<WishlistEntry> {
  bool has(int productId) => any((e) => e.product.id == productId);
}
