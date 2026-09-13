class InterestSubcategory {
  const InterestSubcategory({required this.id, required this.name, required this.slug, required this.displayOrder});

  final int id;
  final String name;
  final String slug;
  final int displayOrder;

  factory InterestSubcategory.fromJson(Map<String, dynamic> json) => InterestSubcategory(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    displayOrder: json['display_order'] as int? ?? 0,
  );
}

class Interest {
  const Interest({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.subcategories,
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final List<InterestSubcategory> subcategories;

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    icon: json['icon'] as String?,
    displayOrder: json['display_order'] as int? ?? 0,
    isActive: json['is_active'] as bool? ?? true,
    subcategories: (json['subcategories'] as List<dynamic>? ?? [])
        .map((e) => InterestSubcategory.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.avatar,
    required this.bio,
    required this.role,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.pushNotificationsEnabled,
    required this.emailOffersEnabled,
    required this.interests,
    required this.dateJoined,
  });

  final int id;
  final String email;
  final String phone;
  final String fullName;
  final String? avatar;
  final String bio;
  final String role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool pushNotificationsEnabled;
  final bool emailOffersEnabled;
  final List<Interest> interests;
  final String dateJoined;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    avatar: json['avatar'] as String?,
    bio: json['bio'] as String? ?? '',
    role: json['role'] as String? ?? 'customer',
    isEmailVerified: json['is_email_verified'] as bool? ?? false,
    isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    pushNotificationsEnabled: json['push_notifications_enabled'] as bool? ?? true,
    emailOffersEnabled: json['email_offers_enabled'] as bool? ?? false,
    interests: (json['interests'] as List<dynamic>? ?? [])
        .map((e) => Interest.fromJson(e as Map<String, dynamic>))
        .toList(),
    dateJoined: json['date_joined'] as String? ?? '',
  );

  UserProfile copyWith({
    String? fullName,
    String? avatar,
    String? bio,
    bool? pushNotificationsEnabled,
    bool? emailOffersEnabled,
    List<Interest>? interests,
  }) {
    return UserProfile(
      id: id,
      email: email,
      phone: phone,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      role: role,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailOffersEnabled: emailOffersEnabled ?? this.emailOffersEnabled,
      interests: interests ?? this.interests,
      dateJoined: dateJoined,
    );
  }
}
