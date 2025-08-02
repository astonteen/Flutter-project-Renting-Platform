import 'package:rent_ease/core/services/supabase_service.dart';

class WishlistRepository {
  Future<bool> isInWishlist(String itemId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await SupabaseService.client
        .from('wishlists')
        .select('id')
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<void> addToWishlist(String itemId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await SupabaseService.client.from('wishlists').insert({
      'user_id': userId,
      'item_id': itemId,
    });
  }

  Future<void> removeFromWishlist(String itemId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await SupabaseService.client
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('item_id', itemId);
  }

  Future<List<String>> getWishlistItemIds() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await SupabaseService.client
        .from('wishlists')
        .select('item_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((item) => item['item_id'] as String).toList();
  }
}
