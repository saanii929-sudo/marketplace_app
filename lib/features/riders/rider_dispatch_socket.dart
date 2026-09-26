import '../../network/api_client.dart';

Uri buildRiderDispatchSocketUri({required String accessToken}) {
  final base = Uri.parse(apiBaseUrl);
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  return Uri(
    scheme: scheme,
    host: base.host,
    port: base.port,
    path: '/ws/riders/dispatch/',
    queryParameters: {'token': accessToken},
  );
}
