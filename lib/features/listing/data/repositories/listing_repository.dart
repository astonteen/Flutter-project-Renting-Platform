import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';

class ListingRepository {
  // Create a new listing
  Future<ListingModel> createListing(ListingModel listing) async {
    try {
      final data = {
        'name': listing.name,
        'description': listing.description,
        'category_id': listing.categoryId,
        'price_per_day': listing.pricePerDay,
        'price_per_week': listing.pricePerWeek,
        'price_per_month': listing.pricePerMonth,
        'security_deposit': listing.securityDeposit,
        'image_urls': listing.imageUrls,
        'primary_image_url': listing.primaryImageUrl,
        'condition': listing.condition,
        'available': listing.isAvailable,
        'location': listing.location,
        'latitude': listing.latitude,
        'longitude': listing.longitude,
        'features': listing.features,
        'specifications': listing.specifications,
        'requires_delivery': listing.requiresDelivery,
        'delivery_fee': listing.deliveryFee,
        'delivery_instructions': listing.deliveryInstructions,
        'quantity': listing.quantity,
        'blocking_days': listing.blockingDays,
        'blocking_reason': listing.blockingReason,
        'owner_id': SupabaseService.currentUser?.id,
      };

      final response = await SupabaseService.client
          .from('items')
          .insert(data)
          .select()
          .single();

      return ListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  // Get listings for current user
  Future<List<ListingModel>> getMyListings() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.client
          .from('items')
          .select('*, categories(name)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return response
          .map<ListingModel>((json) => ListingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load listings: $e');
    }
  }

  // Get all available listings (for browsing)
  Future<List<ListingModel>> getAvailableListings({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final baseQuery = SupabaseService.client
          .from('items')
          .select(
              '*, categories(name), profiles!items_owner_id_fkey(full_name, avatar_url)')
          .eq('available', true);

      if (categoryId != null) {
        baseQuery.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        baseQuery
            .or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      baseQuery.order('created_at', ascending: false);

      if (limit != null) {
        baseQuery.limit(limit);
      }

      if (offset != null) {
        baseQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await baseQuery;

      return response
          .map<ListingModel>((json) => ListingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load available listings: $e');
    }
  }

  // Get listing by ID
  Future<ListingModel> getListingById(String id) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select(
              '*, categories(name), profiles!items_owner_id_fkey(full_name, avatar_url, phone)')
          .eq('id', id)
          .single();

      return ListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load listing: $e');
    }
  }

  // Update listing
  Future<ListingModel> updateListing(
      String id, Map<String, dynamic> updates) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure user owns the listing
      final existing = await SupabaseService.client
          .from('items')
          .select('owner_id')
          .eq('id', id)
          .single();

      if (existing['owner_id'] != userId) {
        throw Exception('Unauthorized: You can only update your own listings');
      }

      final response = await SupabaseService.client
          .from('items')
          .update(updates)
          .eq('id', id)
          .select('*, categories(name)')
          .single();

      return ListingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  // Delete listing
  Future<void> deleteListing(String id) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure user owns the listing
      final existing = await SupabaseService.client
          .from('items')
          .select('owner_id')
          .eq('id', id)
          .single();

      if (existing['owner_id'] != userId) {
        throw Exception('Unauthorized: You can only delete your own listings');
      }

      await SupabaseService.client.from('items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Toggle listing availability
  Future<ListingModel> toggleAvailability(String id, bool isAvailable) async {
    try {
      final response = await updateListing(id, {'available': isAvailable});
      return response;
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Increment view count - Disabled since view_count column doesn't exist
  Future<void> incrementViewCount(String id) async {
    // TODO: Implement view count tracking when database schema is updated
    // View count tracking disabled - column does not exist
  }

  // Get featured listings
  Future<List<ListingModel>> getFeaturedListings({int limit = 10}) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select(
              '*, categories(name), profiles!items_owner_id_fkey(full_name, avatar_url)')
          .eq('available', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map<ListingModel>((json) => ListingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load featured listings: $e');
    }
  }

  // Get nearby listings (requires location)
  Future<List<ListingModel>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    try {
      // Using PostGIS functions for location-based queries
      final response = await SupabaseService.client
          .from('items')
          .select(
              '*, categories(name), profiles!items_owner_id_fkey(full_name, avatar_url)')
          .eq('available', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .limit(limit);

      // For now, return all items. In production, you'd use PostGIS distance functions
      return response
          .map<ListingModel>((json) => ListingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load nearby listings: $e');
    }
  }

  // Get portfolio statistics for current user's listings
  Future<Map<String, dynamic>> getPortfolioStatistics() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get total earnings and active bookings across all user's listings
      final bookingsResponse =
          await SupabaseService.client.from('rentals').select('''
            status,
            total_price,
            start_date,
            end_date,
            items!inner(owner_id)
          ''').eq('items.owner_id', userId);

      final bookings = bookingsResponse as List<dynamic>;
      final now = DateTime.now();

      // Calculate total earnings from completed and confirmed bookings
      final totalEarnings = bookings
          .where(
              (b) => b['status'] == 'confirmed' || b['status'] == 'completed')
          .fold(
              0.0, (sum, b) => sum + double.parse(b['total_price'].toString()));

      // Count active bookings (confirmed bookings that haven't ended yet)
      final activeBookings = bookings
          .where((b) =>
              b['status'] == 'confirmed' &&
              DateTime.parse(b['end_date']).isAfter(now))
          .length;

      // Get average rating across all listings
      final ratingsResponse = await SupabaseService.client
          .from('items')
          .select('rating, review_count')
          .eq('owner_id', userId)
          .not('rating', 'is', null);

      double avgRating = 0.0;
      int totalReviews = 0;
      double totalRatingPoints = 0.0;

      for (final item in ratingsResponse) {
        final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = item['review_count'] as int? ?? 0;
        if (rating > 0 && reviewCount > 0) {
          totalRatingPoints += rating * reviewCount;
          totalReviews += reviewCount;
        }
      }

      if (totalReviews > 0) {
        avgRating = totalRatingPoints / totalReviews;
      }

      return {
        'totalEarnings': totalEarnings,
        'activeBookings': activeBookings,
        'avgRating': avgRating,
      };
    } catch (e) {
      throw Exception('Failed to load portfolio statistics: $e');
    }
  }

  // Get earnings and booking stats for individual listings
  Future<Map<String, Map<String, dynamic>>> getListingStatistics(
      List<String> listingIds) async {
    try {
      if (listingIds.isEmpty) return {};

      final response = await SupabaseService.client
          .from('rentals')
          .select('item_id, status, total_price, start_date, end_date')
          .inFilter('item_id', listingIds);

      final bookings = response as List<dynamic>;
      final stats = <String, Map<String, dynamic>>{};
      final now = DateTime.now();

      // Initialize stats for each listing
      for (final listingId in listingIds) {
        stats[listingId] = {
          'totalEarnings': 0.0,
          'activeBookings': 0,
          'totalBookings': 0,
        };
      }

      // Calculate stats from bookings
      for (final booking in bookings) {
        final listingId = booking['item_id'] as String;
        final status = booking['status'] as String;
        final totalPrice = double.parse(booking['total_price'].toString());
        final endDate = DateTime.parse(booking['end_date']);

        // Count total bookings
        stats[listingId]!['totalBookings'] =
            stats[listingId]!['totalBookings'] + 1;

        // Add to earnings if completed or confirmed
        if (status == 'confirmed' || status == 'completed') {
          stats[listingId]!['totalEarnings'] =
              stats[listingId]!['totalEarnings'] + totalPrice;
        }

        // Count as active booking if confirmed and hasn't ended
        if (status == 'confirmed' && endDate.isAfter(now)) {
          stats[listingId]!['activeBookings'] =
              stats[listingId]!['activeBookings'] + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to load listing statistics: $e');
    }
  }
}
