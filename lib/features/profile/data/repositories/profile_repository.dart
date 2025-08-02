import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/profile/data/models/profile_model.dart';
import 'package:rent_ease/features/profile/data/models/user_statistics_model.dart';

class ProfileRepository {
  // Get current user profile
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return null;

      final response = await SupabaseService.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(
      String userId, Uint8List imageBytes, String fileName) async {
    try {
      final path = 'profiles/$userId/$fileName';
      await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(path, imageBytes);

      final url =
          SupabaseService.client.storage.from('avatars').getPublicUrl(path);

      // Update profile with new avatar URL
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': url}).eq('id', userId);

      return url;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Get user statistics
  Future<UserStatisticsModel> getUserStatistics(String userId) async {
    try {
      // Get all stats in parallel
      final futures = await Future.wait([
        _getRentalsCount(userId),
        _getListingsCount(userId),
        _getDeliveriesCount(userId),
        _getTotalEarnings(userId),
        _getAverageRating(userId),
      ]);

      return UserStatisticsModel(
        rentalsCount: futures[0] as int,
        listingsCount: futures[1] as int,
        deliveriesCount: futures[2] as int,
        totalEarnings: futures[3] as double,
        averageRating: futures[4] as double,
        memberSince: await _getMemberSince(userId),
      );
    } catch (e) {
      debugPrint('Error fetching user statistics: $e');
      return const UserStatisticsModel(
        rentalsCount: 0,
        listingsCount: 0,
        deliveriesCount: 0,
        totalEarnings: 0.0,
        averageRating: 0.0,
        memberSince: null,
      );
    }
  }

  // Watch profile changes for real-time updates
  Stream<ProfileModel?> watchProfile(String userId) {
    return SupabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return ProfileModel.fromJson(data.first);
        });
  }

  // Watch statistics changes for real-time updates
  Stream<UserStatisticsModel> watchUserStatistics(String userId) {
    // Use a more stable approach with periodic updates
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getUserStatistics(userId))
        .distinct(); // Only emit when statistics actually change
  }

  // Private helper methods
  Future<int> _getRentalsCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('rentals')
          .select('id')
          .eq('renter_id', userId);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting rentals count: $e');
      return 0;
    }
  }

  Future<int> _getListingsCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('id')
          .eq('owner_id', userId);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting listings count: $e');
      return 0;
    }
  }

  Future<int> _getDeliveriesCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('id')
          .eq('driver_id', userId);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting deliveries count: $e');
      return 0;
    }
  }

  Future<double> _getTotalEarnings(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('driver_earnings')
          .eq('driver_id', userId)
          .not('driver_earnings', 'is', null);

      double total = 0.0;
      for (final delivery in response) {
        total += (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      debugPrint('Error getting total earnings: $e');
      return 0.0;
    }
  }

  Future<double> _getAverageRating(String userId) async {
    try {
      // Try to get ratings from rentals where user was owner
      final response = await SupabaseService.client
          .from('rentals')
          .select('customer_rating')
          .eq('owner_id', userId)
          .not('customer_rating', 'is', null);

      if (response.isEmpty) return 0.0;

      double total = 0.0;
      int count = 0;
      for (final rental in response) {
        final rating = (rental['customer_rating'] as num?)?.toDouble();
        if (rating != null) {
          total += rating;
          count++;
        }
      }

      return count > 0 ? total / count : 0.0;
    } catch (e) {
      debugPrint('Error getting average rating: $e');
      // If customer_rating column doesn't exist or any other error, return 0.0
      return 0.0;
    }
  }

  Future<DateTime?> _getMemberSince(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('created_at')
          .eq('id', userId)
          .single();

      final createdAt = response['created_at'] as String?;
      return createdAt != null ? DateTime.parse(createdAt) : null;
    } catch (e) {
      debugPrint('Error getting member since date: $e');
      return null;
    }
  }
}
