import 'package:rent_ease/core/services/supabase_service.dart';

class ViewedItemsRepository {
  Future<void> recordView(String itemId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    await SupabaseService.client.from('viewed_items').upsert({
      'user_id': userId,
      'item_id': itemId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getRecentlyViewedItemIds({int limit = 20}) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await SupabaseService.client
        .from('viewed_items')
        .select('item_id')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(limit);

    return (response as List).map((item) => item['item_id'] as String).toList();
  }
}
