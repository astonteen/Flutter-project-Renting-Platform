import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Event for rating prompts
class RatingPromptEvent {
  final String rentalId;
  final String itemName;
  final String counterPartyName;
  final String counterPartyId;
  final bool isRenterRating; // true if current user is renter rating owner

  const RatingPromptEvent({
    required this.rentalId,
    required this.itemName,
    required this.counterPartyName,
    required this.counterPartyId,
    required this.isRenterRating,
  });
}

/// Service to handle rating prompts when rentals are completed
class AppRatingService {
  static AppRatingService? _instance;
  static AppRatingService get instance =>
      _instance ??= AppRatingService._internal();
  AppRatingService._internal();

  RealtimeChannel? _channel;
  final StreamController<RatingPromptEvent> _ratingPromptController =
      StreamController<RatingPromptEvent>.broadcast();

  /// Stream of rating prompt events
  Stream<RatingPromptEvent> get ratingPrompts => _ratingPromptController.stream;

  bool _isInitialized = false;

  /// Initialize the rating service
  static Future<void> initialize() async {
    final service = AppRatingService.instance;
    await service._initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️  AppRatingService: No authenticated user');
      return;
    }

    debugPrint('🎯 Initializing AppRatingService for user: $userId');

    // Listen to rental changes where user is either renter or owner
    _channel = SupabaseService.client
        .channel('rating_prompts_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rentals',
          callback: _handleRentalChange,
        )
        .subscribe();

    _isInitialized = true;
    debugPrint('✅ AppRatingService initialized');
  }

  void _handleRentalChange(PostgresChangePayload payload) async {
    try {
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      // Only process if user is involved in this rental
      final renterId = newRecord['renter_id'] as String?;
      final ownerId = newRecord['owner_id'] as String?;

      if (renterId != userId && ownerId != userId) {
        return; // User is not involved in this rental
      }

      // Check if rental just became completed
      final oldStatus = oldRecord['status'] as String?;
      final newStatus = newRecord['status'] as String?;

      if (oldStatus != 'completed' && newStatus == 'completed') {
        debugPrint('🏁 Rental completed: ${newRecord['id']}');
        await _checkForRatingPrompt(newRecord);
      }
    } catch (e) {
      debugPrint('❌ Error handling rental change: $e');
    }
  }

  Future<void> _checkForRatingPrompt(Map<String, dynamic> rental) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final rentalId = rental['id'] as String;
      final renterId = rental['renter_id'] as String;
      final ownerId = rental['owner_id'] as String;
      final customerRatedAt = rental['customer_rated_at'];
      final ownerRatedAt = rental['owner_rated_at'];

      // Determine if current user should be prompted to rate
      bool shouldPrompt = false;
      bool isRenterRating = false;
      String counterPartyId = '';

      if (userId == renterId && customerRatedAt == null) {
        // Current user is renter and hasn't rated yet
        shouldPrompt = true;
        isRenterRating = true;
        counterPartyId = ownerId;
      } else if (userId == ownerId && ownerRatedAt == null) {
        // Current user is owner and hasn't rated yet
        shouldPrompt = true;
        isRenterRating = false;
        counterPartyId = renterId;
      }

      if (!shouldPrompt) {
        debugPrint('📋 No rating prompt needed for rental $rentalId');
        return;
      }

      // Fetch additional details for the prompt
      final details = await _fetchRatingDetails(rentalId, counterPartyId);
      if (details != null) {
        final event = RatingPromptEvent(
          rentalId: rentalId,
          itemName: details['itemName'] as String,
          counterPartyName: details['counterPartyName'] as String,
          counterPartyId: counterPartyId,
          isRenterRating: isRenterRating,
        );

        debugPrint('🌟 Emitting rating prompt for rental: $rentalId');
        _ratingPromptController.add(event);
      }
    } catch (e) {
      debugPrint('❌ Error checking rating prompt: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchRatingDetails(
      String rentalId, String counterPartyId) async {
    try {
      final response = await SupabaseService.client.from('rentals').select('''
            id,
            items!rentals_item_id_fkey(name),
            profiles!rentals_renter_id_fkey(full_name),
            owner_profile:profiles!rentals_owner_id_fkey(full_name)
          ''').eq('id', rentalId).single();

      final item = response['items'] as Map<String, dynamic>?;
      final renterProfile = response['profiles'] as Map<String, dynamic>?;
      final ownerProfile = response['owner_profile'] as Map<String, dynamic>?;

      final itemName = item?['name'] as String? ?? 'Unknown Item';
      final renterId = response['renter_id'] as String?;

      String counterPartyName = 'Unknown User';
      if (counterPartyId == renterId) {
        counterPartyName =
            renterProfile?['full_name'] as String? ?? 'Unknown User';
      } else {
        counterPartyName =
            ownerProfile?['full_name'] as String? ?? 'Unknown User';
      }

      return {
        'itemName': itemName,
        'counterPartyName': counterPartyName,
      };
    } catch (e) {
      debugPrint('❌ Error fetching rating details: $e');
      return null;
    }
  }

  /// Manually check for pending ratings (useful for testing)
  static Future<void> checkPendingRatings() async {
    final service = AppRatingService.instance;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      // Find completed rentals where user hasn't rated yet
      final response = await SupabaseService.client
          .from('rentals')
          .select('*')
          .eq('status', 'completed')
          .or('renter_id.eq.$userId,owner_id.eq.$userId');

      for (final rental in response) {
        await service._checkForRatingPrompt(rental);
      }
    } catch (e) {
      debugPrint('❌ Error checking pending ratings: $e');
    }
  }

  /// Dispose of the service
  static void dispose() {
    final service = AppRatingService.instance;
    service._channel?.unsubscribe();
    service._ratingPromptController.close();
    service._isInitialized = false;
    _instance = null;
    debugPrint('🧹 AppRatingService disposed');
  }
}
