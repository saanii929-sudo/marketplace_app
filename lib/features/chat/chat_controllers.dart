import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'chat_api.dart';
import 'chat_models.dart';

final chatApiProvider = Provider<ChatApi>((ref) => ChatApi(ref.watch(dioProvider)));

final conversationsProvider = FutureProvider<List<ConversationSummary>>(
  (ref) => ref.read(chatApiProvider).getConversations(),
);

final supportContactsProvider = FutureProvider<List<SupportContact>>(
  (ref) => ref.read(chatApiProvider).getSupportContacts(),
);
