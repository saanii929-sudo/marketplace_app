import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'order.dart';
import 'orders_api.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) => OrdersApi(ref.watch(dioProvider)));

final ordersProvider = FutureProvider<List<OrderSummary>>((ref) => ref.read(ordersApiProvider).list());

final orderDetailProvider = FutureProvider.family<OrderDetail, String>(
  (ref, orderNumber) => ref.read(ordersApiProvider).get(orderNumber),
);

final orderTrackingProvider = FutureProvider.family<OrderTracking, String>(
  (ref, orderNumber) => ref.read(ordersApiProvider).getTracking(orderNumber),
);
