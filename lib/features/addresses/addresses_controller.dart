import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'address.dart';
import 'addresses_api.dart';

final addressesApiProvider = Provider<AddressesApi>((ref) => AddressesApi(ref.watch(dioProvider)));

/// Holds the current user's saved addresses, fetched from
/// `GET /accounts/addresses/`. Also used (read-only) by the Checkout
/// screen's address picker, so both stay in sync automatically.
class AddressesController extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() => ref.read(addressesApiProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(addressesApiProvider).list());
  }

  Future<void> create(AddressInput input) async {
    await ref.read(addressesApiProvider).create(input);
    await refresh();
  }

  Future<void> updateAddress(int id, AddressInput input) async {
    await ref.read(addressesApiProvider).update(id, input);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(addressesApiProvider).delete(id);
    await refresh();
  }

  Future<void> setDefault(int id) async {
    await ref.read(addressesApiProvider).setDefault(id);
    await refresh();
  }
}

final addressesControllerProvider = AsyncNotifierProvider<AddressesController, List<Address>>(
  AddressesController.new,
);
