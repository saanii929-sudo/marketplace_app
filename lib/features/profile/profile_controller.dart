import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'profile_api.dart';
import 'user_profile.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(dioProvider)));

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.read(profileApiProvider).getMe();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(profileApiProvider).getMe());
  }

  Future<void> updateProfile({String? fullName, String? avatar, String? bio}) async {
    final updated = await ref.read(profileApiProvider).updateMe(fullName: fullName, avatar: avatar, bio: bio);
    state = AsyncData(updated);
  }

  Future<void> setPushNotifications(bool enabled) async {
    final previous = state;
    state = AsyncData(state.value!.copyWith(pushNotificationsEnabled: enabled));
    try {
      final updated = await ref.read(profileApiProvider).updateMe(pushNotificationsEnabled: enabled);
      state = AsyncData(updated);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> setEmailOffers(bool enabled) async {
    final previous = state;
    state = AsyncData(state.value!.copyWith(emailOffersEnabled: enabled));
    try {
      final updated = await ref.read(profileApiProvider).updateMe(emailOffersEnabled: enabled);
      state = AsyncData(updated);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> uploadAvatar(File file) async {
    final url = await ref.read(profileApiProvider).uploadAvatar(file);
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(avatar: url));
    }
  }

  Future<void> updateInterestIds(List<int> categoryIds) async {
    await ref.read(profileApiProvider).updateInterests(categoryIds);
    await refresh();
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);
