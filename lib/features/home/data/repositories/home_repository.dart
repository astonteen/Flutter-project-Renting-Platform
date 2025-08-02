import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/services/location_service.dart';
import 'package:rent_ease/features/home/data/models/category_model.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:geolocator/geolocator.dart';

class HomeRepository {
  // Fetch all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await SupabaseService.client
          .from('categories')
          .select('*')
          .order('name');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      throw Exception('Failed to fetch categories');
    }
  }

  // Fetch featured items
  Future<List<RentalItemModel>> getFeaturedItems({int limit = 10}) async {
    try {
      // First try to get items marked as featured
      var response = await SupabaseService.client
          .from('items')
          .select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),
            reviews(rating)
          ''')
          .eq('featured', true)
          .eq('available', true)
          .order('created_at', ascending: false)
          .limit(limit);

      // If no featured items found, fallback to recent available items
      if (response.isEmpty) {
        response = await SupabaseService.client
            .from('items')
            .select('''
              *,
              profiles!owner_id(full_name, avatar_url),
              categories(name),
              reviews(rating)
            ''')
            .eq('available', true)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      return (response as List).map((json) {
        // Process joined data
        final processedJson = _processItemJson(json);
        return RentalItemModel.fromJson(processedJson);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching featured items: $e');
      throw Exception('Failed to fetch featured items');
    }
  }

  // Fetch nearby items using user's location
  Future<List<RentalItemModel>> getNearbyItems({
    int limit = 10,
    String? location,
    double radiusKm = 25.0, // 25km default radius
  }) async {
    try {
      // Try to get user's current location
      final locationService = LocationService();
      Position? userPosition;

      try {
        userPosition = await locationService.getCurrentLocation();
      } catch (e) {
        debugPrint('Could not get user location: $e');
      }

      var query = SupabaseService.client.from('items').select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),
            reviews(rating)
          ''').eq('available', true);

      // If we have user location, filter by proximity
      if (userPosition != null) {
        // Use Supabase to calculate distance using Haversine formula
        // Only include items that have latitude and longitude
        query = query.not('latitude', 'is', null).not('longitude', 'is', null);

        final response = await query;

        // Calculate distances and filter by radius
        final itemsWithDistance = (response as List)
            .map((json) {
              final processedJson = _processItemJson(json);
              final item = RentalItemModel.fromJson(processedJson);

              // Calculate distance if item has coordinates
              if (item.latitude != null && item.longitude != null) {
                final distance = Geolocator.distanceBetween(
                      userPosition!.latitude,
                      userPosition.longitude,
                      item.latitude!,
                      item.longitude!,
                    ) /
                    1000; // Convert to kilometers

                return {
                  'item': item,
                  'distance': distance,
                };
              }
              return null;
            })
            .where((item) => item != null)
            .toList();

        // Filter by radius and sort by distance
        final nearbyItems = itemsWithDistance
            .where((item) =>
                item != null && (item['distance'] as double) <= radiusKm)
            .toList();

        nearbyItems.sort((a, b) =>
            (a!['distance'] as double).compareTo(b!['distance'] as double));

        return nearbyItems
            .take(limit)
            .map((item) => item!['item'] as RentalItemModel)
            .toList();
      } else {
        // Fallback: if no location, return recent items
        debugPrint('Using fallback: showing recent items instead of nearby');
        final response =
            await query.order('created_at', ascending: false).limit(limit);

        return (response as List).map((json) {
          final processedJson = _processItemJson(json);
          return RentalItemModel.fromJson(processedJson);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching nearby items: $e');
      throw Exception('Failed to fetch nearby items');
    }
  }

  // Search items by query
  Future<List<RentalItemModel>> searchItems({
    required String query,
    String? categoryId,
    int limit = 20,
  }) async {
    try {
      var supabaseQuery = SupabaseService.client.from('items').select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),
            reviews(rating)
          ''').eq('available', true);

      // Add text search
      // Use prefix search for the name field (starts with query)
      // and contains search for description field
      supabaseQuery =
          supabaseQuery.or('name.ilike.$query%,description.ilike.%$query%');

      // Add category filter if provided
      if (categoryId != null) {
        supabaseQuery = supabaseQuery.eq('category_id', categoryId);
      }

      final response = await supabaseQuery
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final processedJson = _processItemJson(json);
        return RentalItemModel.fromJson(processedJson);
      }).toList();
    } catch (e) {
      debugPrint('Error searching items: $e');
      throw Exception('Failed to search items');
    }
  }

  // Get items by category
  Future<List<RentalItemModel>> getItemsByCategory({
    required String categoryId,
    int limit = 20,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),

            reviews(rating)
          ''')
          .eq('category_id', categoryId)
          .eq('available', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        final processedJson = _processItemJson(json);
        return RentalItemModel.fromJson(processedJson);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching items by category: $e');
      throw Exception('Failed to fetch items by category');
    }
  }

  // Process item JSON to flatten joined data
  Map<String, dynamic> _processItemJson(Map<String, dynamic> json) {
    final processed = Map<String, dynamic>.from(json);

    // Process owner data
    if (json['profiles'] != null) {
      processed['owner_name'] = json['profiles']['full_name'];
      processed['owner_avatar_url'] = json['profiles']['avatar_url'];
    }

    // Process category data
    if (json['categories'] != null) {
      processed['category_name'] = json['categories']['name'];
    }

    // Process images data from items table fields
    List<String> imageUrls = [];
    String primaryImageUrl = '';

    if (json['image_urls'] != null) {
      imageUrls = List<String>.from(json['image_urls'] as List);
    }

    if (json['primary_image_url'] != null) {
      primaryImageUrl = json['primary_image_url'] as String;
    }

    // If no primary image but we have image_urls, use the first one
    if (primaryImageUrl.isEmpty && imageUrls.isNotEmpty) {
      primaryImageUrl = imageUrls.first;
    }

    processed['image_urls'] = imageUrls;
    processed['primary_image_url'] = primaryImageUrl;

    // Process reviews to calculate average rating
    if (json['reviews'] != null) {
      final reviews = json['reviews'] as List;
      if (reviews.isNotEmpty) {
        final totalRating = reviews
            .map((review) => review['rating'] as int)
            .reduce((a, b) => a + b);
        processed['avg_rating'] = totalRating / reviews.length;
        processed['review_count'] = reviews.length;
      }
    }

    return processed;
  }

  // Get single item details
  Future<RentalItemModel?> getItemDetails(String itemId) async {
    try {
      final response = await SupabaseService.client.from('items').select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),
            reviews(rating, comment, created_at)
          ''').eq('id', itemId).single();

      if (response.isEmpty) {
        return null;
      }

      final processedJson = _processItemJson(response);
      return RentalItemModel.fromJson(processedJson);
    } catch (e) {
      debugPrint('Error fetching item details: $e');
      throw Exception('Failed to fetch item details: ${e.toString()}');
    }
  }

  // Get multiple items by IDs
  Future<List<RentalItemModel>> getItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await SupabaseService.client.from('items').select('''
            *,
            profiles!owner_id(full_name, avatar_url),
            categories(name),
            reviews(rating)
          ''').inFilter('id', ids).eq('available', true);

      return (response as List).map((json) {
        final processedJson = _processItemJson(json);
        return RentalItemModel.fromJson(processedJson);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching items by IDs: $e');
      throw Exception('Failed to fetch items by IDs');
    }
  }

  // Insert sample data (for development)
  Future<void> insertSampleData() async {
    try {
      // Insert categories if they don't exist
      final existingCategories =
          await SupabaseService.client.from('categories').select('id').limit(1);

      if (existingCategories.isEmpty) {
        await SupabaseService.client.from('categories').insert([
          {
            'name': 'Electronics',
            'description': 'Cameras, laptops, smartphones and more',
            'icon': 'devices',
          },
          {
            'name': 'Tools',
            'description': 'Power tools, hand tools, and equipment',
            'icon': 'handyman',
          },
          {
            'name': 'Sports',
            'description': 'Sports equipment and gear',
            'icon': 'sports_basketball',
          },
          {
            'name': 'Clothing',
            'description': 'Fashion and accessories',
            'icon': 'checkroom',
          },
          {
            'name': 'Furniture',
            'description': 'Home and office furniture',
            'icon': 'chair',
          },
          {
            'name': 'Vehicles',
            'description': 'Cars, bikes, and other vehicles',
            'icon': 'directions_car',
          },
        ]);
        debugPrint('Sample categories inserted');
      }
    } catch (e) {
      debugPrint('Error inserting sample data: $e');
    }
  }
}
