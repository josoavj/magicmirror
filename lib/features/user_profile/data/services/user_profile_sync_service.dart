import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class UserProfileSyncService {
  UserProfileSyncService();

  static const String avatarBucket = 'avatars';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveUserId({String? fallback}) async {
    final client = _client;
    if (client == null) {
      return fallback;
    }

    return client.auth.currentUser?.id ?? fallback;
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) {
      return null;
    }

    final resolvedUserId = await resolveUserId(fallback: userId);
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return null;
    }

    final data = await client
        .from('profiles')
        .select()
        .eq('user_id', resolvedUserId)
        .maybeSingle();

    if (data != null) {
      final profileJson = {
        'userId': data['user_id'],
        'displayName': data['display_name'],
        'avatarUrl': data['avatar_url'],
        'gender': data['gender'],
        'age': data['age'],
        'birthDate': data['birth_date'],
        'morphology': data['morphology'],
        'preferredStyles': data['preferred_styles'] ?? <dynamic>[],
      };
      return UserProfile.fromJson(profileJson);
    }

    return null;
  }

  Future<void> pushProfile(UserProfile profile) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final resolvedUserId = await resolveUserId(fallback: profile.userId);
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return;
    }

    final payload = {
      'user_id': resolvedUserId,
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'gender': profile.gender,
      'age': profile.age,
      'birth_date': profile.birthDate?.toIso8601String().split('T').first,
      'morphology': profile.morphology,
      'preferred_styles': profile.preferredStyles,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from('profiles').upsert(payload, onConflict: 'user_id');
  }

  Future<String?> uploadAvatarBytes({
    required Uint8List bytes,
    required String userId,
    String fileExtension = 'jpg',
  }) async {
    final client = _client;
    if (client == null) {
      return null;
    }

    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage
        .from(avatarBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    return client.storage.from(avatarBucket).getPublicUrl(path);
  }
}
