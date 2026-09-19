import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'chat_models.dart';

class ChatApi {
  ChatApi(this._dio);
  final Dio _dio;

  /// First page only — matches the existing "My Orders" precedent, and a
  /// customer/seller inbox is never expected to be large enough to need
  /// pagination UI.
  Future<List<ConversationSummary>> getConversations() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('chat/conversations/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Fetches every page (oldest message first) so the chat screen can open
  /// straight to full history — a support/seller thread isn't expected to
  /// run into the thousands of messages that would make this expensive.
  Future<List<Message>> getMessages(int conversationId) => _guard(() async {
    final messages = <Message>[];
    String? nextUrl = 'chat/conversations/$conversationId/messages/';
    while (nextUrl != null) {
      final response = await _dio.get<Map<String, dynamic>>(nextUrl);
      final data = response.data!;
      messages.addAll((data['results'] as List<dynamic>).map((e) => Message.fromJson(e as Map<String, dynamic>)));
      nextUrl = data['next'] as String?;
    }
    return messages;
  });

  /// Persists the message (and the server broadcasts it over the
  /// conversation's WebSocket group, including back to this device) — the
  /// live socket is used only to *receive* messages, sending always goes
  /// through this REST call for a well-defined success/error contract.
  Future<Message> sendMessage(int conversationId, String body) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      'chat/conversations/$conversationId/messages/',
      data: {'body': body},
    );
    return Message.fromJson(response.data!);
  });

  Future<void> markRead(int conversationId) =>
      _guard(() => _dio.post<dynamic>('chat/conversations/$conversationId/read/'));

  /// Gets-or-creates the conversation — safe to call every time a
  /// "Message seller" / "Chat with us" button is pressed.
  Future<ConversationSummary> startConversation({required String kind, String? sellerSlug}) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      'chat/conversations/start/',
      data: {'kind': kind, 'seller_slug': ?sellerSlug},
    );
    return ConversationSummary.fromJson(response.data!);
  });

  Future<List<SupportContact>> getSupportContacts() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('support/contacts/');
    return (response.data ?? []).map((e) => SupportContact.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
