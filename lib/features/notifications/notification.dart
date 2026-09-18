class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as int? ?? 0,
    type: json['type'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
