import '../../network/api_client.dart';

/// Builds the live delivery-dispatch socket URL:
/// `ws(s)://<api host>/ws/riders/dispatch/?token=<access_token>`.
/// Mirrors `buildChatSocketUri` exactly — this route also lives outside
/// `/api/v1/` (wired directly in Channels' routing), authenticated the same
/// way via `chat.middleware.JWTAuthMiddleware`. The server closes the
/// connection with code 4001 (missing/invalid token) or 4003 (no rider
/// profile on this account).
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
