import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'address.dart';

/// The editable fields of an address — used for both create and update, so
/// callers never have to invent a placeholder `id` just to describe a new
/// address that doesn't have one yet.
class AddressInput {
  const AddressInput({
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.region,
    required this.country,
    this.isDefault = false,
    this.lat,
    this.lng,
  });

  final String label;
  final String recipientName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String country;
  final bool isDefault;

  /// **Unconfirmed** whether the backend's serializer accepts these — see
  /// `Address.lat`/`.lng`. Omitted from the payload entirely when null,
  /// rather than sent as explicit `null`, so an address save never
  /// regresses a previously-set pin by accident.
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
    'label': label,
    'recipient_name': recipientName,
    'phone': phone,
    'line1': line1,
    'line2': line2,
    'city': city,
    'region': region,
    'country': country,
    'is_default': isDefault,
    'lat': ?lat,
    'lng': ?lng,
  };
}

class AddressesApi {
  AddressesApi(this._dio);
  final Dio _dio;

  /// Fetches every page of `/accounts/addresses/` — the list is small
  /// enough (a user's saved addresses) that the UI doesn't paginate it.
  Future<List<Address>> list() => _guard(() async {
    final addresses = <Address>[];
    String? nextUrl = 'accounts/addresses/';
    while (nextUrl != null) {
      // `next` from the API is a full absolute URL; Dio uses it as-is
      // instead of appending it to baseUrl.
      final response = await _dio.get<Map<String, dynamic>>(nextUrl);
      final data = response.data!;
      addresses.addAll((data['results'] as List<dynamic>).map((e) => Address.fromJson(e as Map<String, dynamic>)));
      nextUrl = data['next'] as String?;
    }
    return addresses;
  });

  Future<Address> create(AddressInput input) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('accounts/addresses/', data: input.toJson());
    return Address.fromJson(response.data!);
  });

  Future<Address> update(int id, AddressInput input) => _guard(() async {
    final response = await _dio.put<Map<String, dynamic>>('accounts/addresses/$id/', data: input.toJson());
    return Address.fromJson(response.data!);
  });

  Future<void> delete(int id) => _guard(() => _dio.delete<dynamic>('accounts/addresses/$id/'));

  Future<Address> setDefault(int id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('accounts/addresses/$id/set_default/');
    return Address.fromJson(response.data!);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
