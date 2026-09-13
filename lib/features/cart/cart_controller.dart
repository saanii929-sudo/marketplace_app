import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'cart.dart';
import 'cart_api.dart';

final cartApiProvider = Provider<CartApi>((ref) => CartApi(ref.watch(dioProvider)));

/// The signed-in user's cart, fetched from `GET /cart/`. Every mutation
/// calls the corresponding endpoint then refetches — the write endpoints
/// mostly echo just the submitted fields back, not the recomputed cart
/// totals, so a refetch is the only reliable way to get the new subtotal/
/// discount/total.
class CartController extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() => ref.read(cartApiProvider).getCart();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cartApiProvider).getCart());
  }

  Future<void> addItem({required int productId, int? variantId, int qty = 1}) async {
    await ref.read(cartApiProvider).addItem(productId: productId, variantId: variantId, qty: qty);
    await refresh();
  }

  Future<void> updateQty(int itemId, int qty) async {
    await ref.read(cartApiProvider).updateQty(itemId, qty);
    await refresh();
  }

  Future<void> removeItem(int itemId) async {
    await ref.read(cartApiProvider).removeItem(itemId);
    await refresh();
  }

  Future<void> clear() async {
    await ref.read(cartApiProvider).clear();
    await refresh();
  }

  Future<void> applyCoupon(String code) async {
    await ref.read(cartApiProvider).applyCoupon(code);
    await refresh();
  }

  Future<void> removeCoupon() async {
    await ref.read(cartApiProvider).removeCoupon();
    await refresh();
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, Cart>(CartController.new);
