import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'discovery.dart';
import 'discovery_api.dart';

final discoveryApiProvider = Provider<DiscoveryApi>((ref) => DiscoveryApi(ref.watch(dioProvider)));

final discoveryHomeProvider = FutureProvider<DiscoveryHome>((ref) => ref.read(discoveryApiProvider).getHome());

final recentlyViewedProvider = FutureProvider<List<RecentlyViewedEntry>>(
  (ref) => ref.read(discoveryApiProvider).getRecentlyViewed(),
);

final recentSearchesProvider = FutureProvider<List<RecentSearch>>(
  (ref) => ref.read(discoveryApiProvider).getRecentSearches(),
);
