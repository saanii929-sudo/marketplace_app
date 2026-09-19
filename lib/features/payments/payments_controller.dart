import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'payment_method.dart';
import 'payments_api.dart';

final paymentsApiProvider = Provider<PaymentsApi>((ref) => PaymentsApi(ref.watch(dioProvider)));

class PaymentMethodsController extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() => ref.read(paymentsApiProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(paymentsApiProvider).list());
  }

  Future<void> create({
    required String gateway,
    required String brand,
    required String last4,
    int? expiryMonth,
    int? expiryYear,
  }) async {
    await ref
        .read(paymentsApiProvider)
        .create(
          gateway: gateway,
          // Placeholder until a real gateway SDK is integrated — see the
          // doc comment on PaymentsApi.
          token: 'demo_${DateTime.now().millisecondsSinceEpoch}',
          brand: brand,
          last4: last4,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
        );
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(paymentsApiProvider).delete(id);
    await refresh();
  }

  Future<void> setDefault(int id) async {
    await ref.read(paymentsApiProvider).setDefault(id);
    await refresh();
  }
}

final paymentMethodsControllerProvider = AsyncNotifierProvider<PaymentMethodsController, List<PaymentMethod>>(
  PaymentMethodsController.new,
);
