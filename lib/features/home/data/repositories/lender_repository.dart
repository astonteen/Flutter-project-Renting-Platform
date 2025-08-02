import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';

class LenderRepository {
  // Get all bookings for lender's listings by date range
  Future<List<BookingModel>> getBookingsForDate(DateTime date) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''')
          .eq('owner_id', userId)
          .gte('start_date', startOfDay.toIso8601String())
          .lte('start_date', endOfDay.toIso8601String())
          .order('start_date', ascending: true);

      final bookings = <BookingModel>[];
      for (final json in response) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final item = json['items'] as Map<String, dynamic>?;
        final images = item?['item_images'] as List<dynamic>? ?? [];
        final primaryImage = images.isNotEmpty
            ? images.firstWhere(
                (img) => img['is_primary'] == true,
                orElse: () => images.first,
              )
            : null;

        final renterRating =
            await _getRenterRating(json['renter_id'] as String);
        final renterReviewCount =
            await _getRenterReviewCount(json['renter_id'] as String);

        bookings.add(BookingModel(
          id: json['id'] as String,
          listingId: json['item_id'] as String,
          listingName: item?['name'] as String? ?? 'Unknown Item',
          listingImageUrl: primaryImage?['image_url'] as String? ?? '',
          renterId: json['renter_id'] as String,
          renterName: profile?['full_name'] as String? ?? 'Unknown Renter',
          renterEmail: profile?['email'] as String? ?? '',
          renterPhone: profile?['phone_number'] as String?,
          renterAvatarUrl: profile?['avatar_url'] as String?,
          renterRating: renterRating,
          renterReviewCount: renterReviewCount,
          startDate: DateTime.parse(json['start_date'] as String),
          endDate: DateTime.parse(json['end_date'] as String),
          totalAmount: double.parse(json['total_price'].toString()),
          securityDeposit: json['security_deposit'] != null
              ? double.parse(json['security_deposit'].toString())
              : 0.0,
          status: _mapStatus(json['status'] as String),
          specialRequests: '', // TODO: Add to database schema if needed
          notes: '', // TODO: Add to database schema if needed
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          isDeliveryRequired: json['delivery_required'] as bool? ?? false,
          isDepositPaid: json['payment_status'] == 'paid',
          isItemReady: json['is_item_ready'] as bool? ?? false,
          conversationId: null, // TODO: Link to messages table
          hasReturnDelivery: null, // No delivery tracking data available here
          returnDeliveryStatus: null,
          isReturnCompleted: null,
        ));
      }
      return bookings;
    } catch (e) {
      throw Exception('Failed to load bookings for date: $e');
    }
  }

  // Get lender dashboard statistics
  Future<Map<String, dynamic>> getLenderDashboardStats() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get total listings count
      final listingsResponse = await SupabaseService.client
          .from('items')
          .select('id')
          .eq('owner_id', userId)
          .eq('available', true);
      final totalListings = (listingsResponse as List).length;

      // Get active bookings (confirmed and in_progress)
      final activeBookingsResponse = await SupabaseService.client
          .from('rentals')
          .select('id, items!inner(owner_id)')
          .eq('owner_id', userId)
          .inFilter('status', ['confirmed', 'in_progress']);
      final activeBookings = (activeBookingsResponse as List).length;

      // Get pending bookings
      final pendingBookingsResponse = await SupabaseService.client
          .from('rentals')
          .select('id, items!inner(owner_id)')
          .eq('owner_id', userId)
          .eq('status', 'pending');
      final pendingBookings = (pendingBookingsResponse as List).length;

      // Get total earnings (completed bookings)
      final earningsResponse = await SupabaseService.client
          .from('rentals')
          .select('total_price, items!inner(owner_id)')
          .eq('owner_id', userId)
          .eq('status', 'completed');

      double totalEarnings = 0.0;
      for (final booking in earningsResponse as List) {
        totalEarnings += double.parse(booking['total_price'].toString());
      }

      // Get this month's earnings
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthlyEarningsResponse = await SupabaseService.client
          .from('rentals')
          .select('total_price, items!inner(owner_id)')
          .eq('owner_id', userId)
          .eq('status', 'completed')
          .gte('end_date', startOfMonth.toIso8601String())
          .lte('end_date', endOfMonth.toIso8601String());

      double monthlyEarnings = 0.0;
      for (final booking in monthlyEarningsResponse as List) {
        monthlyEarnings += double.parse(booking['total_price'].toString());
      }

      return {
        'total_listings': totalListings,
        'active_bookings': activeBookings,
        'pending_bookings': pendingBookings,
        'total_earnings': totalEarnings,
        'monthly_earnings': monthlyEarnings,
      };
    } catch (e) {
      throw Exception('Failed to load lender dashboard stats: $e');
    }
  }

  // Get recent bookings for lender
  Future<List<BookingModel>> getRecentBookings({int limit = 5}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''')
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final bookings = <BookingModel>[];
      for (final json in response) {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final item = json['items'] as Map<String, dynamic>?;
        final images = item?['item_images'] as List<dynamic>? ?? [];
        final primaryImage = images.isNotEmpty
            ? images.firstWhere(
                (img) => img['is_primary'] == true,
                orElse: () => images.first,
              )
            : null;

        final renterRating =
            await _getRenterRating(json['renter_id'] as String);
        final renterReviewCount =
            await _getRenterReviewCount(json['renter_id'] as String);

        bookings.add(BookingModel(
          id: json['id'] as String,
          listingId: json['item_id'] as String,
          listingName: item?['name'] as String? ?? 'Unknown Item',
          listingImageUrl: primaryImage?['image_url'] as String? ?? '',
          renterId: json['renter_id'] as String,
          renterName: profile?['full_name'] as String? ?? 'Unknown Renter',
          renterEmail: profile?['email'] as String? ?? '',
          renterPhone: profile?['phone_number'] as String?,
          renterAvatarUrl: profile?['avatar_url'] as String?,
          renterRating: renterRating,
          renterReviewCount: renterReviewCount,
          startDate: DateTime.parse(json['start_date'] as String),
          endDate: DateTime.parse(json['end_date'] as String),
          totalAmount: double.parse(json['total_price'].toString()),
          securityDeposit: json['security_deposit'] != null
              ? double.parse(json['security_deposit'].toString())
              : 0.0,
          status: _mapStatus(json['status'] as String),
          specialRequests: '', // TODO: Add to database schema if needed
          notes: '', // TODO: Add to database schema if needed
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          isDeliveryRequired: json['delivery_required'] as bool? ?? false,
          isDepositPaid: json['payment_status'] == 'paid',
          isItemReady: json['is_item_ready'] as bool? ?? false,
          conversationId: null, // TODO: Link to messages table
          hasReturnDelivery: null, // No delivery tracking data available here
          returnDeliveryStatus: null,
          isReturnCompleted: null,
        ));
      }
      return bookings;
    } catch (e) {
      throw Exception('Failed to load recent bookings: $e');
    }
  }

  // Get earnings data for charts/analytics
  Future<List<Map<String, dynamic>>> getEarningsData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            total_price,
            end_date,
            items!inner(owner_id, name)
          ''')
          .eq('owner_id', userId)
          .eq('status', 'completed')
          .gte('end_date', startDate.toIso8601String())
          .lte('end_date', endDate.toIso8601String())
          .order('end_date', ascending: true);

      return (response as List)
          .map((booking) => {
                'date': DateTime.parse(booking['end_date'] as String),
                'amount': double.parse(booking['total_price'].toString()),
                'item_name': booking['items']['name'] as String,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to load earnings data: $e');
    }
  }

  // Get active bookings for today (bookings that are currently ongoing)
  Future<List<BookingModel>> getActiveBookingsForToday() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            ),
            deliveries!deliveries_rental_id_fkey(
              id,
              delivery_type,
              status
            )
          ''')
          .eq('owner_id', userId)
          .lte('start_date', endOfDay.toIso8601String())
          .gte('end_date', startOfDay.toIso8601String())
          .inFilter(
              'status', ['confirmed', 'in_progress', 'active', 'completed'])
          .order('start_date', ascending: true);

      // Don't filter out completed returns - we want to show them with "Returned" status
      // But we'll filter them out in UI logic for next day display
      final filteredResponse = response;

      return _buildBookingModels(filteredResponse);
    } catch (e) {
      throw Exception('Failed to load active bookings for today: $e');
    }
  }

  // Get upcoming bookings (bookings that start in the future)
  Future<List<BookingModel>> getUpcomingBookings({int daysAhead = 30}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      final endDate = DateTime(today.year, today.month, today.day + daysAhead);

      debugPrint('🔍 Fetching upcoming bookings for user: $userId');

      // Step 1: Get basic rental data
      final rentalResponse = await SupabaseService.client
          .from('rentals')
          .select('*')
          .eq('owner_id', userId)
          .gte('start_date', tomorrow.toIso8601String())
          .lte('start_date', endDate.toIso8601String())
          .inFilter('status', ['confirmed', 'pending']).order('start_date',
              ascending: true);

      debugPrint('📊 Found ${rentalResponse.length} rental records');

      if (rentalResponse.isEmpty) {
        return [];
      }

      // Step 2: Get item details for each rental
      final itemIds = (rentalResponse as List)
          .map((rental) => rental['item_id'] as String)
          .toSet()
          .toList();

      final itemsResponse = await SupabaseService.client
          .from('items')
          .select('id, name, owner_id')
          .inFilter('id', itemIds);

      debugPrint('📦 Found ${itemsResponse.length} item records');

      // Step 3: Get renter profiles
      final renterIds = (rentalResponse)
          .map((rental) => rental['renter_id'] as String)
          .toSet()
          .toList();

      final profilesResponse = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email, phone_number, avatar_url')
          .inFilter('id', renterIds);

      debugPrint('👥 Found ${profilesResponse.length} profile records');

      // Step 4: Get delivery data
      final rentalIds =
          (rentalResponse).map((rental) => rental['id'] as String).toList();

      final deliveriesResponse = await SupabaseService.client
          .from('deliveries')
          .select('id, rental_id, delivery_type, status')
          .inFilter('rental_id', rentalIds);

      debugPrint('🚚 Found ${deliveriesResponse.length} delivery records');

      // Step 5: Build lookup maps
      final itemsMap = {
        for (var item in itemsResponse as List)
          item['id'] as String: item as Map<String, dynamic>
      };

      final profilesMap = {
        for (var profile in profilesResponse as List)
          profile['id'] as String: profile as Map<String, dynamic>
      };

      final deliveriesMap = <String, List<Map<String, dynamic>>>{};
      for (var delivery in deliveriesResponse as List) {
        final rentalId = delivery['rental_id'] as String;
        deliveriesMap
            .putIfAbsent(rentalId, () => [])
            .add(delivery as Map<String, dynamic>);
      }

      // Step 6: Build BookingModel objects
      final bookings = <BookingModel>[];
      for (final rentalJson in rentalResponse) {
        final itemData = itemsMap[rentalJson['item_id']];
        final profileData = profilesMap[rentalJson['renter_id']];
        final deliveryData = deliveriesMap[rentalJson['id']] ?? [];

        debugPrint('🔨 Building booking for rental ${rentalJson['id']}');
        debugPrint('   Item: ${itemData?['name'] ?? 'NOT_FOUND'}');
        debugPrint('   Renter: ${profileData?['full_name'] ?? 'NOT_FOUND'}');

        // Get renter ratings
        final renterRating =
            await _getRenterRating(rentalJson['renter_id'] as String);
        final renterReviewCount =
            await _getRenterReviewCount(rentalJson['renter_id'] as String);

        // Extract delivery information
        final returnDelivery =
            deliveryData.cast<Map<String, dynamic>>().firstWhere(
                  (delivery) => delivery['delivery_type'] == 'return_pickup',
                  orElse: () => <String, dynamic>{},
                );

        final hasReturnDelivery = returnDelivery.isNotEmpty;
        final returnDeliveryStatus =
            hasReturnDelivery ? (returnDelivery['status'] as String?) : null;
        final isReturnCompleted = hasReturnDelivery &&
            returnDeliveryStatus != null &&
            (returnDeliveryStatus == 'item_delivered' ||
                returnDeliveryStatus == 'return_delivered' ||
                returnDeliveryStatus == 'completed');

        final itemName = itemData?['name'] as String? ?? 'Unknown Item';
        debugPrint('📝 Final item name: "$itemName"');

        bookings.add(BookingModel(
          id: rentalJson['id'] as String,
          listingId: rentalJson['item_id'] as String,
          listingName: itemName,
          listingImageUrl: '', // TODO: Add image support
          renterId: rentalJson['renter_id'] as String,
          renterName: profileData?['full_name'] as String? ?? 'Unknown Renter',
          renterEmail: profileData?['email'] as String? ?? '',
          renterPhone: profileData?['phone_number'] as String?,
          renterAvatarUrl: profileData?['avatar_url'] as String?,
          renterRating: renterRating,
          renterReviewCount: renterReviewCount,
          startDate: DateTime.parse(rentalJson['start_date'] as String),
          endDate: DateTime.parse(rentalJson['end_date'] as String),
          totalAmount: double.parse(rentalJson['total_price'].toString()),
          securityDeposit: rentalJson['security_deposit'] != null
              ? double.parse(rentalJson['security_deposit'].toString())
              : 0.0,
          status: _mapStatus(rentalJson['status'] as String),
          createdAt: DateTime.parse(rentalJson['created_at'] as String),
          updatedAt: DateTime.parse(rentalJson['updated_at'] as String),
          isDeliveryRequired: rentalJson['delivery_required'] as bool? ?? false,
          deliveryAddress: null, // TODO: Add delivery address support
          deliveryFee: null, // TODO: Add delivery fee support
          isDepositPaid: true, // TODO: Calculate based on payment status
          isItemReady: false, // TODO: Add item ready status
          conversationId: null, // TODO: Add conversation support
          hasReturnDelivery: hasReturnDelivery,
          returnDeliveryStatus: returnDeliveryStatus,
          isReturnCompleted: isReturnCompleted,
        ));
      }

      debugPrint('✅ Built ${bookings.length} booking models');
      return bookings;
    } catch (e) {
      debugPrint('❌ Error in getUpcomingBookings: $e');
      throw Exception('Failed to load upcoming bookings: $e');
    }
  }

  // Helper method to build BookingModel objects from database response
  Future<List<BookingModel>> _buildBookingModels(List<dynamic> response) async {
    debugPrint('🔍 _buildBookingModels received ${response.length} records');

    final bookings = <BookingModel>[];
    for (final json in response) {
      debugPrint('📋 Processing booking: ${json['id']}');

      final profile = json['profiles'] as Map<String, dynamic>?;
      final item = json['items'] as Map<String, dynamic>?;

      // Debug logging for item data
      if (item == null) {
        debugPrint('❌ Item data is null for booking ${json['id']}');
        debugPrint('🔍 Expected item_id: ${json['item_id']}');
        debugPrint(
            '⚠️  This usually means the item was deleted or has no images');
        debugPrint('📊 Full JSON: $json');

        // Additional diagnostic: Check if this is due to missing images
        if (json.containsKey('item_id')) {
          debugPrint(
              '💡 Recommendation: Verify item exists and has images, or use left join for item_images');
        }
      } else {
        debugPrint(
            '✅ Item data found: name="${item['name']}", owner_id="${item['owner_id']}"');

        // Debug image data
        final itemImages = item['item_images'] as List<dynamic>? ?? [];
        debugPrint('🖼️  Item has ${itemImages.length} images');
      }

      final images = item?['item_images'] as List<dynamic>? ?? [];
      final primaryImage = images.isNotEmpty
          ? images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            )
          : null;

      final renterRating = await _getRenterRating(json['renter_id'] as String);
      final renterReviewCount =
          await _getRenterReviewCount(json['renter_id'] as String);

      // Extract delivery information
      final deliveries = json['deliveries'] as List<dynamic>? ?? [];
      final returnDelivery = deliveries.cast<Map<String, dynamic>>().firstWhere(
            (delivery) => delivery['delivery_type'] == 'return_pickup',
            orElse: () => <String, dynamic>{},
          );

      final hasReturnDelivery = returnDelivery.isNotEmpty;
      final returnDeliveryStatus =
          hasReturnDelivery ? (returnDelivery['status'] as String?) : null;
      final isReturnCompleted = hasReturnDelivery &&
          returnDeliveryStatus != null &&
          (returnDeliveryStatus == 'item_delivered' ||
              returnDeliveryStatus == 'return_delivered' ||
              returnDeliveryStatus == 'completed');

      // Try to get item name with fallback mechanism
      String itemName = item?['name'] as String? ?? 'Unknown Item';

      // If item data is null, try to fetch the item name separately
      if (item == null && json['item_id'] != null) {
        try {
          final itemResponse = await SupabaseService.client
              .from('items')
              .select('name')
              .eq('id', json['item_id'] as String)
              .single();

          itemName = itemResponse['name'] as String? ?? 'Unknown Item';
          debugPrint('🔄 Fallback fetch successful: Item name is "$itemName"');
        } catch (e) {
          debugPrint('⚠️  Fallback fetch failed: $e');
          debugPrint('💭 Item might be deleted or inaccessible');
        }
      }

      debugPrint('📝 Final item name for booking ${json['id']}: "$itemName"');

      bookings.add(BookingModel(
        id: json['id'] as String,
        listingId: json['item_id'] as String,
        listingName: itemName,
        listingImageUrl: primaryImage?['image_url'] as String? ?? '',
        renterId: json['renter_id'] as String,
        renterName: profile?['full_name'] as String? ?? 'Unknown Renter',
        renterEmail: profile?['email'] as String? ?? '',
        renterPhone: profile?['phone_number'] as String?,
        renterAvatarUrl: profile?['avatar_url'] as String?,
        renterRating: renterRating,
        renterReviewCount: renterReviewCount,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        totalAmount: double.parse(json['total_price'].toString()),
        securityDeposit: json['security_deposit'] != null
            ? double.parse(json['security_deposit'].toString())
            : 0.0,
        status: _mapStatus(json['status'] as String),
        specialRequests: '', // TODO: Add to database schema if needed
        notes: '', // TODO: Add to database schema if needed
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isDeliveryRequired: json['delivery_required'] as bool? ?? false,
        isDepositPaid: json['payment_status'] == 'paid',
        isItemReady: json['is_item_ready'] as bool? ?? false,
        conversationId: null, // TODO: Link to messages table
        hasReturnDelivery: hasReturnDelivery,
        returnDeliveryStatus: returnDeliveryStatus,
        isReturnCompleted: isReturnCompleted,
      ));
    }
    return bookings;
  }

  // Helper method to get renter's average rating
  Future<double> _getRenterRating(String renterId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('rating')
          .eq('reviewee_id', renterId)
          .eq('reviewee_type', 'renter');

      if (response.isEmpty) return 0.0;

      final ratings =
          response.map((r) => (r['rating'] as num).toDouble()).toList();
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method to get renter's review count
  Future<int> _getRenterReviewCount(String renterId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('id')
          .eq('reviewee_id', renterId)
          .eq('reviewee_type', 'renter');

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to map database status to BookingStatus enum
  BookingStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'active':
        return BookingStatus.inProgress;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // Get all bookings for the lender
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.client.from('rentals').select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''').eq('owner_id', userId).order('created_at', ascending: false);

      return _mapResponseToBookings(response);
    } catch (e) {
      throw Exception('Failed to load all bookings: $e');
    }
  }

  // Get booking details by ID
  Future<BookingModel> getBookingDetails(String bookingId) async {
    try {
      final response = await SupabaseService.client.from('rentals').select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''').eq('id', bookingId).single();

      final bookings = _mapResponseToBookings([response]);
      if (bookings.isEmpty) {
        throw Exception('Booking not found');
      }
      return bookings.first;
    } catch (e) {
      throw Exception('Failed to load booking details: $e');
    }
  }

  // Get upcoming handoffs (bookings starting soon)
  Future<List<BookingModel>> getUpcomingHandoffs(
      DateTime start, DateTime end) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''')
          .eq('owner_id', userId)
          .gte('start_date', start.toIso8601String())
          .lte('start_date', end.toIso8601String())
          .inFilter('status', ['confirmed', 'pending'])
          .order('start_date', ascending: true);

      return _mapResponseToBookings(response);
    } catch (e) {
      throw Exception('Failed to load upcoming handoffs: $e');
    }
  }

  // Get upcoming returns (bookings ending soon)
  Future<List<BookingModel>> getUpcomingReturns(
      DateTime start, DateTime end) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.client
          .from('rentals')
          .select('''
            *,
            profiles!rentals_renter_id_fkey(
              full_name,
              email,
              phone_number,
              avatar_url
            ),
            items!rentals_item_id_fkey(
              name,
              owner_id,
              item_images(
                image_url,
                is_primary
              )
            )
          ''')
          .eq('owner_id', userId)
          .gte('end_date', start.toIso8601String())
          .lte('end_date', end.toIso8601String())
          .eq('status', 'active')
          .order('end_date', ascending: true);

      return _mapResponseToBookings(response);
    } catch (e) {
      throw Exception('Failed to load upcoming returns: $e');
    }
  }

  // Update booking status
  Future<BookingModel> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      final statusString = _mapStatusToString(status);

      await SupabaseService.client
          .from('rentals')
          .update({'status': statusString}).eq('id', bookingId);

      // Auto-block 2 days after booking ends when confirmed
      if (status == BookingStatus.confirmed) {
        try {
          await AvailabilityService.completeRentalWithAutoBuffer(
            rentalId: bookingId,
          );
        } catch (autoBlockError) {
          // Don't fail the booking update if auto-blocking fails
          debugPrint('Warning: Failed to create auto-block: $autoBlockError');
        }
      }

      // Remove auto-block if booking is cancelled
      if (status == BookingStatus.cancelled) {
        try {
          await AvailabilityService.removeAutoBlockForRental(
            rentalId: bookingId,
          );
        } catch (removeBlockError) {
          // Don't fail the booking update if removing auto-block fails
          debugPrint('Warning: Failed to remove auto-block: $removeBlockError');
        }
      }

      // Return updated booking
      return await getBookingDetails(bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Helper method to map response to bookings
  List<BookingModel> _mapResponseToBookings(List<dynamic> response) {
    final bookings = <BookingModel>[];
    for (final json in response) {
      try {
        final profile = json['profiles'] as Map<String, dynamic>?;
        final item = json['items'] as Map<String, dynamic>?;
        final images = item?['item_images'] as List<dynamic>? ?? [];
        final primaryImage = images.isNotEmpty
            ? images.firstWhere(
                (img) => img['is_primary'] == true,
                orElse: () => images.first,
              )
            : null;

        bookings.add(BookingModel(
          id: json['id'] as String,
          listingId: json['item_id'] as String,
          listingName: item?['name'] as String? ?? 'Unknown Item',
          listingImageUrl: primaryImage?['image_url'] as String? ?? '',
          renterId: json['renter_id'] as String,
          renterName: profile?['full_name'] as String? ?? 'Unknown Renter',
          renterEmail: profile?['email'] as String? ?? '',
          renterPhone: profile?['phone_number'] as String?,
          renterAvatarUrl: profile?['avatar_url'] as String?,
          renterRating: 4.5, // TODO: Calculate from reviews
          renterReviewCount: 0, // TODO: Count from reviews
          startDate: DateTime.parse(json['start_date'] as String),
          endDate: DateTime.parse(json['end_date'] as String),
          totalAmount: double.parse(json['total_price'].toString()),
          securityDeposit: json['security_deposit'] != null
              ? double.parse(json['security_deposit'].toString())
              : 0.0,
          status: _mapStatus(json['status'] as String),
          specialRequests: json['special_requests'] as String? ?? '',
          notes: json['notes'] as String? ?? '',
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          isDeliveryRequired: json['delivery_required'] as bool? ?? false,
          deliveryAddress: json['delivery_address'] as String?,
          deliveryFee: json['delivery_fee'] != null
              ? double.parse(json['delivery_fee'].toString())
              : null,
          isDepositPaid: json['payment_status'] == 'paid',
          isItemReady: json['is_item_ready'] as bool? ?? false,
          conversationId: json['conversation_id'] as String?,
          hasReturnDelivery: null, // No delivery tracking data available here
          returnDeliveryStatus: null,
          isReturnCompleted: null,
        ));
      } catch (e) {
        debugPrint('Error parsing booking: $e');
      }
    }
    return bookings;
  }

  // Helper method to map status enum to string
  String _mapStatusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'active';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.overdue:
        return 'overdue';
    }
  }
}
