import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/reviews/data/models/review_model.dart';

class ReviewRepository {
  /// Create a new review
  Future<ReviewModel> createReview({
    required String reviewedId,
    required double overallRating,
    double? conditionAccuracyRating,
    double? communicationRating,
    double? deliveryExperienceRating,
    String? comment,
    List<String>? photoUrls,
    String? rentalId,
    String? itemId,
    ReviewType reviewType = ReviewType.item,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify if this is a verified rental
      bool isVerifiedRental = false;
      if (rentalId != null) {
        final rentalCheck = await SupabaseService.client
            .from('rentals')
            .select('id, status')
            .eq('id', rentalId)
            .eq('renter_id', userId)
            .eq('status', 'completed')
            .maybeSingle();

        isVerifiedRental = rentalCheck != null;
      }

      final reviewData = {
        'reviewer_id': userId,
        'reviewed_id': reviewedId,
        'rental_id': rentalId,
        'item_id': itemId,
        'rating': overallRating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
        'is_verified_purchase': isVerifiedRental,
      };

      final response = await SupabaseService.client
          .from('reviews')
          .insert(reviewData)
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating review: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  /// Get reviews for a specific user or item
  Future<List<ReviewModel>> getReviews({
    String? reviewedId,
    String? itemId,
    ReviewType? reviewType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final query = SupabaseService.client.from('reviews').select('*');

      if (reviewedId != null) {
        query.eq('reviewed_id', reviewedId);
      }

      if (itemId != null) {
        query.eq('item_id', itemId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<ReviewModel>((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      throw Exception('Failed to get reviews: $e');
    }
  }

  /// Get review statistics for a user or item
  Future<Map<String, dynamic>> getReviewStatistics({
    String? reviewedId,
    String? itemId,
  }) async {
    try {
      var query = SupabaseService.client.from('reviews').select('rating');

      if (reviewedId != null) {
        query = query.eq('reviewed_id', reviewedId);
      }

      if (itemId != null) {
        query = query.eq('item_id', itemId);
      }

      final response = await query;

      if (response.isEmpty) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'verified_reviews': 0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final totalReviews = response.length;

      // Calculate average ratings
      final ratings =
          response.map((r) => (r['rating'] as num).toDouble()).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      // Rating distribution
      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        final roundedRating = rating.round();
        ratingDistribution[roundedRating] =
            (ratingDistribution[roundedRating] ?? 0) + 1;
      }

      return {
        'total_reviews': totalReviews,
        'average_rating': averageRating,
        'verified_reviews': 0,
        'rating_distribution': ratingDistribution,
      };
    } catch (e) {
      debugPrint('Error getting review statistics: $e');
      throw Exception('Failed to get review statistics: $e');
    }
  }

  /// Calculate trust score for a user
  Future<TrustScore> calculateTrustScore(String userId) async {
    try {
      final stats = await getReviewStatistics(reviewedId: userId);

      return TrustScore.calculate(
        totalReviews: stats['total_reviews'] as int,
        averageRating: stats['average_rating'] as double,
        verifiedRentals: stats['verified_reviews'] as int,
        hasVerifiedIdentity: false,
        responseRate: 85,
      );
    } catch (e) {
      debugPrint('Error calculating trust score: $e');
      // Return default trust score on error
      return TrustScore.calculate(
        totalReviews: 0,
        averageRating: 0.0,
        verifiedRentals: 0,
        hasVerifiedIdentity: false,
        responseRate: 0,
      );
    }
  }

  /// Add owner response to a review
  Future<ReviewModel> addOwnerResponse(String reviewId, String response) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify the user is the owner of the reviewed item/profile
      final review = await SupabaseService.client
          .from('reviews')
          .select('reviewed_id')
          .eq('id', reviewId)
          .single();

      if (review['reviewed_id'] != userId) {
        throw Exception(
            'Unauthorized: You can only respond to reviews about you');
      }

      final updatedData = {
        'owner_response': response,
        'owner_response_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedReview = await SupabaseService.client
          .from('reviews')
          .update(updatedData)
          .eq('id', reviewId)
          .select()
          .single();

      return ReviewModel.fromJson(updatedReview);
    } catch (e) {
      debugPrint('Error adding owner response: $e');
      throw Exception('Failed to add response: $e');
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      // Simple increment for now - in real app would use RPC
      final currentReview = await SupabaseService.client
          .from('reviews')
          .select('helpful_votes')
          .eq('id', reviewId)
          .single();

      final currentVotes = currentReview['helpful_votes'] as int? ?? 0;

      await SupabaseService.client
          .from('reviews')
          .update({'helpful_votes': currentVotes + 1}).eq('id', reviewId);
    } catch (e) {
      debugPrint('Error marking review helpful: $e');
      throw Exception('Failed to mark review helpful: $e');
    }
  }

  /// Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await SupabaseService.client
          .from('reviews')
          .update({'is_reported': true}).eq('id', reviewId);
    } catch (e) {
      debugPrint('Error reporting review: $e');
      throw Exception('Failed to report review: $e');
    }
  }

  /// Check if user can review (completed rental, not already reviewed)
  Future<bool> canUserReview(String itemId, String ownerId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      // Check if user has completed rental for this item
      final completedRental = await SupabaseService.client
          .from('rentals')
          .select('id')
          .eq('item_id', itemId)
          .eq('renter_id', userId)
          .eq('status', 'completed')
          .maybeSingle();

      if (completedRental == null) return false;

      // Check if user has already reviewed this item
      final existingReview = await SupabaseService.client
          .from('reviews')
          .select('id')
          .eq('item_id', itemId)
          .eq('reviewer_id', userId)
          .maybeSingle();

      return existingReview == null;
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      return false;
    }
  }
}
