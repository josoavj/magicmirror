import 'package:supabase_flutter/supabase_flutter.dart';

class OutfitFavoritesSyncService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<Set<String>?> fetchFavorites(String userId) async {
    final client = _client;
    if (client == null) return null;

    final row = await client
        .from('profiles')
        .select('favorite_outfit_ids')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;

    final rawIds = row['favorite_outfit_ids'];
    if (rawIds is! List) return <String>{};
    return rawIds
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> saveFavorites(String userId, Set<String> favoriteIds) async {
    final client = _client;
    if (client == null) return;

    await client.from('profiles').upsert({
      'user_id': userId,
      'favorite_outfit_ids': favoriteIds.toList()..sort(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
