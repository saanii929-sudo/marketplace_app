class ConversationCustomerRef {
  const ConversationCustomerRef({required this.id, required this.fullName});

  final int id;
  final String fullName;

  factory ConversationCustomerRef.fromJson(Map<String, dynamic> json) =>
      ConversationCustomerRef(id: json['id'] as int? ?? 0, fullName: json['full_name'] as String? ?? '');
}

class ConversationSellerRef {
  const ConversationSellerRef({
    required this.id,
    required this.businessName,
    required this.slug,
    required this.logo,
  });

  final int id;
  final String businessName;
  final String slug;
  final String logo;

  factory ConversationSellerRef.fromJson(Map<String, dynamic> json) => ConversationSellerRef(
    id: json['id'] as int? ?? 0,
    businessName: json['business_name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    logo: json['logo'] as String? ?? '',
  );
}

/// A short preview of the thread's most recent message for the inbox list.
/// The given API leaves `last_message`'s shape generic (an arbitrary
/// object in the spec), so this pulls out a display body defensively
/// instead of assuming an exact schema.
class ConversationLastMessagePreview {
  const ConversationLastMessagePreview({required this.body});

  final String body;

  static ConversationLastMessagePreview? fromJson(dynamic json) {
    if (json is! Map) return null;
    final body = json['body'] ?? json['text'] ?? json['message'];
    if (body is! String || body.isEmpty) return null;
    return ConversationLastMessagePreview(body: body);
  }
}

/// `GET /chat/conversations/` list item, and the response of
/// `POST /chat/conversations/start/`.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.kind,
    required this.customer,
    required this.seller,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.createdAt,
  });

  final int id;
  final String kind;
  final ConversationCustomerRef? customer;
  final ConversationSellerRef? seller;
  final DateTime? lastMessageAt;
  final ConversationLastMessagePreview? lastMessagePreview;
  final int unreadCount;
  final DateTime? createdAt;

  /// Customer-facing thread title: the seller's store name for a
  /// `customer_seller` thread, otherwise the support inbox.
  String get displayTitle => seller != null ? seller!.businessName : 'Support';

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
    id: json['id'] as int,
    kind: json['kind'] as String? ?? '',
    customer: json['customer'] == null
        ? null
        : ConversationCustomerRef.fromJson(json['customer'] as Map<String, dynamic>),
    seller: json['seller'] == null ? null : ConversationSellerRef.fromJson(json['seller'] as Map<String, dynamic>),
    lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
    lastMessagePreview: ConversationLastMessagePreview.fromJson(json['last_message']),
    unreadCount: json['unread_count'] as int? ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

/// A single chat message — the shape returned by both
/// `GET/POST /chat/conversations/{id}/messages/` and the `message` payload
/// broadcast over the conversation's WebSocket group.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String body;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as int? ?? 0,
    conversationId: json['conversation_id'] as int? ?? 0,
    senderId: json['sender_id'] as int? ?? 0,
    senderName: json['sender_name'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

/// `GET /support/contacts/` — the email/phone fallback for a customer who
/// wants to reach support without live chat.
class SupportContact {
  const SupportContact({
    required this.id,
    required this.kind,
    required this.label,
    required this.value,
    required this.displayOrder,
  });

  final int id;
  final String kind;
  final String label;
  final String value;
  final int displayOrder;

  bool get isEmail => kind.toLowerCase().contains('email');
  bool get isPhone => kind.toLowerCase().contains('phone');

  factory SupportContact.fromJson(Map<String, dynamic> json) => SupportContact(
    id: json['id'] as int? ?? 0,
    kind: json['kind'] as String? ?? '',
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
    displayOrder: json['display_order'] as int? ?? 0,
  );
}
