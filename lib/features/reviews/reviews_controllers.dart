import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'reviews_api.dart';

final reviewsApiProvider = Provider<ReviewsApi>((ref) => ReviewsApi(ref.watch(dioProvider)));
