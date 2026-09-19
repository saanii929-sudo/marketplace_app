import '../../network/api_client.dart';

/// Builds the live-message socket URL for one conversation:
/// `ws(s)://<api host>/ws/chat/<conversation_id>/?token=<access_token>`.
/// This route lives outside `/api/v1/` (it's wired directly in Channels'
/// routing, not DRF), so only the scheme/host/port of [apiBaseUrl] is
/// reused — its `/api/v1/` path is not.
Uri buildChatSocketUri({required int conversationId, required String accessToken}) {
  final base = Uri.parse(apiBaseUrl);
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  return Uri(
    scheme: scheme,
    host: base.host,
    port: base.port,
    path: '/ws/chat/$conversationId/',
    queryParameters: {'token': accessToken},
  );
}
