import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/utils/address_utils.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_batch_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_withdrawal_model.dart';
import 'package:rent_ease/core/services/location_service.dart';

abstract class DeliveryRepository {
  // Delivery Job Operations
  Future<List<DeliveryJobModel>> getAvailableJobs();
  Future<List<DeliveryJobModel>> getDriverJobs(String driverId);
  Future<List<DeliveryJobModel>> getUserDeliveries(String userId);
  Future<DeliveryJobModel?> getDeliveryById(String deliveryId);
  Future<DeliveryJobModel> acceptJob(String jobId, String driverId);
  Future<DeliveryJobModel> updateJobStatus(String jobId, DeliveryStatus status);
  Future<void> updateJobWithProof(
      String jobId, String proofImageUrl, DeliveryStatus status);
  Future<double> calculateEarnings(String jobId);

  // Driver Profile Operations
  Future<DriverProfileModel?> getDriverProfile(String userId);
  Future<DriverProfileModel> createDriverProfile(DriverProfileModel profile);
  Future<DriverProfileModel> updateDriverProfile(DriverProfileModel profile);
  Future<void> updateDriverAvailability(String userId, bool isAvailable);

  // Driver Withdrawal Operations
  Future<double> getDriverAvailableBalance(String driverId);
  Future<DriverWithdrawalModel> processWithdrawal(
      String driverId, double amount);
  Future<List<DriverWithdrawalModel>> getDriverWithdrawals(String driverId);
  Future<DriverWithdrawalModel?> getWithdrawalById(String withdrawalId);

  // Real-time subscriptions
  Stream<List<DeliveryJobModel>> watchAvailableJobs();
  Stream<DeliveryJobModel> watchJobStatus(String jobId);

  // Delivery Creation for Rentals
  Future<void> createDeliveryForRental({
    required String rentalId,
    required String pickupAddress,
    String? dropoffAddress,
    String? specialInstructions,
    double? fee,
  });

  // Return Delivery Management
  Future<String> createReturnDelivery({
    required String originalDeliveryId,
    required String returnAddress,
    required String contactNumber,
    DateTime? scheduledTime,
    String? specialInstructions,
  });

  // Driver Earnings and Metrics
  Future<double> getDriverTodayEarnings(String driverId);
  Future<Map<String, dynamic>> getDriverMetrics(String driverId);

  // Rating System
  Future<void> submitDeliveryRating({
    required String deliveryId,
    required int driverRating,
    required int serviceRating,
    String? comment,
  });

  // Phase 1 Enhanced Methods
  Future<Map<String, dynamic>> toggleDriverAvailabilityEnhanced(
      String driverId);
  Future<List<DeliveryJobModel>> getAvailableJobsForBatching(String driverId,
      {double radiusKm});
  Future<String?> createDeliveryBatch(
      String driverId, List<String> deliveryIds);
  Future<DeliveryBatchModel?> getDriverCurrentBatch(String driverId);
  Future<List<DeliveryJobModel>> getAvailableJobsEnhanced(String driverId);
  Future<int> calculateDriverPriorityScore(
      String driverId, double pickupLat, double pickupLng);

  /// Geocode and update missing coordinates for deliveries
  Future<void> updateMissingCoordinates();
}

class SupabaseDeliveryRepository implements DeliveryRepository {
  @override
  Future<List<DeliveryJobModel>> getAvailableJobs() async {
    try {
      debugPrint('🔍 Fetching available jobs for drivers...');

      // Step 1: Get deliveries with basic info
      final deliveriesResponse = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .eq('status', 'approved')
          .isFilter('driver_id', null)
          .order('created_at', ascending: false);

      debugPrint(
          '📦 Database returned ${deliveriesResponse.length} available deliveries');

      if (deliveriesResponse.isEmpty) {
        debugPrint('No available deliveries found');
        return [];
      }

      // Step 2: Get rental IDs to fetch related data
      final rentalIds =
          deliveriesResponse.map((d) => d['rental_id'] as String).toList();

      // Step 3: Get rentals with item and profile data
      final rentalsResponse =
          await SupabaseService.client.from('rentals').select('''
            id, renter_id, owner_id, item_id,
            items!inner(id, name),
            renter_profile:profiles!renter_id(id, full_name, phone_number),
            owner_profile:profiles!owner_id(id, full_name, phone_number)
          ''').inFilter('id', rentalIds);

      debugPrint('📦 Fetched ${rentalsResponse.length} rental details');

      // Step 4: Map deliveries with rental data
      final jobs = deliveriesResponse.map((deliveryJson) {
        final rentalId = deliveryJson['rental_id'] as String;
        final rental = rentalsResponse.firstWhere(
          (r) => r['id'] == rentalId,
          orElse: () => <String, dynamic>{},
        );

        final item = rental['items'];
        final renterProfile = rental['renter_profile'];
        final ownerProfile = rental['owner_profile'];

        return DeliveryJobModel.fromJson({
          ...deliveryJson,
          'item_name': item?['name'] ?? 'Unknown Item',
          'customer_name': renterProfile?['full_name'],
          'customer_phone': renterProfile?['phone_number'],
          'owner_name': ownerProfile?['full_name'],
          'owner_phone': ownerProfile?['phone_number'],
        });
      }).toList();

      debugPrint(
          '✅ Successfully mapped ${jobs.length} delivery jobs for drivers');
      for (int i = 0; i < jobs.length && i < 3; i++) {
        debugPrint(
            '   Job ${i + 1}: ${jobs[i].id.substring(0, 8)} - ${jobs[i].itemName} (\$${jobs[i].fee})');
      }

      return jobs;
    } catch (e) {
      debugPrint('❌ Error fetching available jobs: $e');
      rethrow;
    }
  }

  @override
  Future<List<DeliveryJobModel>> getDriverJobs(String driverId) async {
    try {
      debugPrint('🔍 Fetching driver jobs for: $driverId');

      // Step 1: Get deliveries with basic info
      final deliveriesResponse = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .eq('driver_id', driverId)
          .neq('status', 'delivered')
          .neq('status', 'returned')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      debugPrint(
          '📦 Database returned ${deliveriesResponse.length} driver jobs');

      if (deliveriesResponse.isEmpty) {
        debugPrint('No driver jobs found');
        return [];
      }

      // Step 2: Get rental IDs to fetch related data
      final rentalIds =
          deliveriesResponse.map((d) => d['rental_id'] as String).toList();

      // Step 3: Get rentals with item and profile data
      final rentalsResponse =
          await SupabaseService.client.from('rentals').select('''
            id, renter_id, owner_id, item_id,
            items!inner(id, name),
            renter_profile:profiles!renter_id(id, full_name, phone_number),
            owner_profile:profiles!owner_id(id, full_name, phone_number)
          ''').inFilter('id', rentalIds);

      debugPrint('📦 Fetched ${rentalsResponse.length} rental details');

      // Step 4: Map deliveries with rental data
      final jobs = deliveriesResponse.map((deliveryJson) {
        final rentalId = deliveryJson['rental_id'] as String;
        final rental = rentalsResponse.firstWhere(
          (r) => r['id'] == rentalId,
          orElse: () => <String, dynamic>{},
        );

        final item = rental['items'];
        final renterProfile = rental['renter_profile'];
        final ownerProfile = rental['owner_profile'];

        return DeliveryJobModel.fromJson({
          ...deliveryJson,
          'item_name': item?['name'] ?? 'Unknown Item',
          'customer_name': renterProfile?['full_name'],
          'customer_phone': renterProfile?['phone_number'],
          'owner_name': ownerProfile?['full_name'],
          'owner_phone': ownerProfile?['phone_number'],
        });
      }).toList();

      debugPrint('✅ Successfully mapped ${jobs.length} driver jobs');
      for (int i = 0; i < jobs.length && i < 3; i++) {
        debugPrint(
            '   Job ${i + 1}: ${jobs[i].id.substring(0, 8)} - ${jobs[i].itemName} - ${jobs[i].statusDisplayText} (${jobs[i].status})');
      }

      return jobs;
    } catch (e) {
      debugPrint('❌ Error fetching driver jobs: $e');
      rethrow;
    }
  }

  @override
  Future<List<DeliveryJobModel>> getUserDeliveries(String userId) async {
    try {
      debugPrint('🔍 Fetching deliveries for user: $userId');

      // Step 1: Get all rentals where user is involved
      final rentals = await SupabaseService.client
          .from('rentals')
          .select('id, item_id, renter_id, owner_id, items!inner(id, name)')
          .or('renter_id.eq.$userId,owner_id.eq.$userId')
          .order('created_at', ascending: false);

      if (rentals.isEmpty) {
        debugPrint('📦 No rentals found for user $userId');
        return [];
      }

      final rentalIds = rentals.map((r) => r['id'] as String).toList();
      debugPrint('📋 Found ${rentalIds.length} rentals for user');

      // Step 2: Get deliveries for these rentals
      final response = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .inFilter('rental_id', rentalIds)
          .order('created_at', ascending: false);

      debugPrint('📦 Database returned ${response.length} user deliveries');

      // Step 3: Create enhanced delivery objects with user context
      final deliveries = response.map((deliveryJson) {
        final rentalId = deliveryJson['rental_id'] as String;
        final rental = rentals.firstWhere((r) => r['id'] == rentalId);
        final item = rental['items'];

        return DeliveryJobModel.fromJson({
          ...deliveryJson,
          'item_name': item['name'] ?? 'Unknown Item',
          'rental_id': rentalId,
          // Add user context for role-based UI
          'user_is_renter': rental['renter_id'] == userId,
          'user_is_owner': rental['owner_id'] == userId,
        });
      }).toList();

      debugPrint('✅ Successfully mapped ${deliveries.length} user deliveries');
      debugPrint(
          '🎯 User roles - Renter count: ${deliveries.where((d) => d.userIsRenter).length}, Owner count: ${deliveries.where((d) => d.userIsOwner).length}');
      return deliveries;
    } catch (e) {
      debugPrint('❌ Error fetching user deliveries: $e');
      // Fallback to simplified query if joins fail
      try {
        debugPrint('🔄 Fallback: Using simplified delivery query...');
        final response = await SupabaseService.client
            .from('deliveries')
            .select('*')
            .order('created_at', ascending: false);

        return response.map((json) => DeliveryJobModel.fromJson(json)).toList();
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        rethrow;
      }
    }
  }

  @override
  Future<DeliveryJobModel?> getDeliveryById(String deliveryId) async {
    try {
      debugPrint('🔍 Fetching delivery by ID: $deliveryId');
      final response = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .eq('id', deliveryId)
          .single();

      if (response.isEmpty) {
        debugPrint('Delivery with ID $deliveryId not found');
        return null;
      }

      return DeliveryJobModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching delivery by ID: $e');
      rethrow;
    }
  }

  @override
  Future<DeliveryJobModel> acceptJob(String jobId, String driverId) async {
    try {
      debugPrint('🤝 Accepting job: $jobId for driver: $driverId');

      final response = await SupabaseService.client
          .from('deliveries')
          .update({
            'driver_id': driverId,
            'status':
                'driver_assigned', // Changed from 'accepted' to 'driver_assigned'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .eq('status',
              'approved') // Ensure job is still approved and available
          .select('*')
          .single();

      final acceptedJob = DeliveryJobModel.fromJson(response);
      debugPrint(
          '✅ Job accepted successfully: ${acceptedJob.id.substring(0, 8)} - Status: ${acceptedJob.statusDisplayText}');

      return acceptedJob;
    } catch (e) {
      debugPrint('❌ Error accepting job: $e');
      rethrow;
    }
  }

  @override
  Future<DeliveryJobModel> updateJobStatus(
      String jobId, DeliveryStatus status) async {
    try {
      debugPrint(
          '🔄 Updating delivery $jobId to status: ${_deliveryStatusToString(status)}');

      final Map<String, dynamic> updateData = {
        'status': _deliveryStatusToString(status),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add timestamps for specific status changes
      switch (status) {
        case DeliveryStatus.pendingApproval:
          // No special handling needed for pending approval
          break;
        case DeliveryStatus.itemCollected:
          updateData['pickup_time'] = DateTime.now().toIso8601String();
          updateData['current_leg'] = 'delivery';
          break;
        case DeliveryStatus.itemDelivered:
          updateData['dropoff_time'] = DateTime.now().toIso8601String();
          break;
        case DeliveryStatus.driverHeadingToPickup:
          updateData['current_leg'] = 'pickup';
          break;
        case DeliveryStatus.driverHeadingToDelivery:
          updateData['current_leg'] = 'delivery';
          break;
        case DeliveryStatus.approved:
          updateData['lender_approved_at'] = DateTime.now().toIso8601String();
          break;
        case DeliveryStatus.driverAssigned:
        case DeliveryStatus.returnRequested:
        case DeliveryStatus.returnScheduled:
        case DeliveryStatus.returnCollected:
        case DeliveryStatus.returnDelivered:
        case DeliveryStatus.completed:
        case DeliveryStatus.cancelled:
          // No special timestamp handling needed for these statuses
          break;
      }

      // First check if the delivery exists
      final existingDelivery = await SupabaseService.client
          .from('deliveries')
          .select('id, status')
          .eq('id', jobId)
          .maybeSingle();

      if (existingDelivery == null) {
        debugPrint('❌ Delivery $jobId not found in database');
        throw Exception('Delivery job $jobId not found');
      }

      debugPrint(
          '✅ Found delivery $jobId with current status: ${existingDelivery['status']}');

      // Now update it
      final response = await SupabaseService.client
          .from('deliveries')
          .update(updateData)
          .eq('id', jobId)
          .select('*')
          .single();

      debugPrint('✅ Successfully updated delivery status');
      final job = DeliveryJobModel.fromJson(response);

      // Calculate and update earnings when delivered
      if (status == DeliveryStatus.itemDelivered ||
          status == DeliveryStatus.returnDelivered) {
        await calculateEarnings(jobId);

        // Update driver's total earnings in their profile
        if (job.driverId != null) {
          await _updateDriverTotalEarnings(job.driverId!);
        }

        // Remove auto-block (return buffer) if this is a return delivery
        if (job.isReturnDelivery == true &&
            status == DeliveryStatus.itemDelivered) {
          try {
            await SupabaseService.client
                .rpc('remove_auto_block_for_rental', params: {
              'p_rental_id': job.rentalId,
            });
            debugPrint(
                '✅ Removed auto-block for rental ${job.rentalId} after return delivery completed');
          } catch (e) {
            debugPrint(
                '⚠️ Failed to remove auto-block for rental ${job.rentalId}: $e');
            // Don't fail the delivery update if auto-block removal fails
          }
        }
      }

      return job;
    } catch (e) {
      debugPrint('❌ Error updating job status: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateJobWithProof(
      String jobId, String proofImageUrl, DeliveryStatus status) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': _deliveryStatusToString(status),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add proof image to appropriate field
      switch (status) {
        case DeliveryStatus.itemCollected:
          updateData['pickup_proof_image'] = proofImageUrl;
          updateData['pickup_time'] = DateTime.now().toIso8601String();
          break;
        case DeliveryStatus.itemDelivered:
          updateData['delivery_proof_image'] = proofImageUrl;
          updateData['dropoff_time'] = DateTime.now().toIso8601String();
          break;
        case DeliveryStatus.returnCollected:
          updateData['return_pickup_proof_image'] = proofImageUrl;
          break;
        case DeliveryStatus.returnDelivered:
          updateData['return_delivery_proof_image'] = proofImageUrl;
          break;
        case DeliveryStatus.pendingApproval:
        case DeliveryStatus.approved:
        case DeliveryStatus.driverAssigned:
        case DeliveryStatus.driverHeadingToPickup:
        case DeliveryStatus.driverHeadingToDelivery:
        case DeliveryStatus.returnRequested:
        case DeliveryStatus.returnScheduled:
        case DeliveryStatus.completed:
        case DeliveryStatus.cancelled:
          // No proof image handling needed for these statuses
          break;
      }

      await SupabaseService.client
          .from('deliveries')
          .update(updateData)
          .eq('id', jobId);
    } catch (e) {
      debugPrint('Error updating job with proof: $e');
      rethrow;
    }
  }

  @override
  Future<double> calculateEarnings(String jobId) async {
    try {
      final result = await SupabaseService.client
          .rpc('calculate_delivery_earnings', params: {'delivery_id': jobId});

      return (result as num).toDouble();
    } catch (e) {
      debugPrint('Error calculating earnings: $e');
      return 0.0;
    }
  }

  /// Update driver's total earnings by summing all completed deliveries
  Future<void> _updateDriverTotalEarnings(String driverId) async {
    try {
      debugPrint('💰 Updating total earnings for driver: $driverId');

      // Get all completed deliveries for this driver (both regular and return deliveries)
      final response = await SupabaseService.client
          .from('deliveries')
          .select('driver_earnings')
          .eq('driver_id', driverId)
          .inFilter('status', ['item_delivered', 'return_delivered']);

      // Calculate total earnings
      double totalEarnings = 0.0;
      int totalDeliveries = response.length;

      for (final delivery in response) {
        totalEarnings +=
            (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint(
          '💰 Calculated total earnings: \$${totalEarnings.toStringAsFixed(2)} from $totalDeliveries deliveries');

      // Update driver profile
      await SupabaseService.client.from('driver_profiles').update({
        'total_earnings': totalEarnings,
        'total_deliveries': totalDeliveries,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', driverId);

      debugPrint('✅ Driver profile updated with new earnings');
    } catch (e) {
      debugPrint('❌ Error updating driver total earnings: $e');
      // Don't rethrow as this shouldn't fail the delivery completion
    }
  }

  @override
  Future<void> createDeliveryForRental({
    required String rentalId,
    required String pickupAddress,
    String? dropoffAddress,
    String? specialInstructions,
    double? fee,
  }) async {
    try {
      String finalDropoffAddress = dropoffAddress ?? '';

      // If no dropoff address provided, get the renter's default saved address
      if (finalDropoffAddress.isEmpty) {
        try {
          // Get the rental to find the renter_id
          final rentalResponse = await SupabaseService.client
              .from('rentals')
              .select('renter_id')
              .eq('id', rentalId)
              .single();

          final renterId = rentalResponse['renter_id'] as String;

          // Get the renter's default saved address
          final addressResponse = await SupabaseService.client
              .from('saved_addresses')
              .select(
                  'address_line_1, address_line_2, city, state, postal_code, country')
              .eq('user_id', renterId)
              .eq('is_default', true)
              .maybeSingle();

          if (addressResponse != null) {
            // Format the complete address using utility function
            finalDropoffAddress =
                AddressUtils.formatSavedAddress(addressResponse);
            debugPrint('✅ Using renter\'s saved address: $finalDropoffAddress');
          } else {
            debugPrint(
                '⚠️ No default saved address found for renter: $renterId');
            finalDropoffAddress = 'Customer delivery address to be provided';
          }
        } catch (e) {
          debugPrint('❌ Error fetching renter\'s saved address: $e');
          finalDropoffAddress = 'Customer delivery address to be provided';
        }
      }

      await SupabaseService.client.from('deliveries').insert({
        'rental_id': rentalId,
        'pickup_address': pickupAddress,
        'dropoff_address': finalDropoffAddress,
        'special_instructions': specialInstructions,
        'fee': fee ?? 10.0,
        'status': 'pending',
        'delivery_type': 'pickup_and_delivery',
        'current_leg': 'pending_assignment',
      });

      debugPrint('✅ Created delivery with address: $finalDropoffAddress');
    } catch (e) {
      debugPrint('Error creating delivery for rental: $e');
      rethrow;
    }
  }

  @override
  Future<DriverProfileModel?> getDriverProfile(String userId) async {
    try {
      final response =
          await SupabaseService.client.from('driver_profiles').select('''
            *,
            profiles!inner(full_name, phone_number, email)
          ''').eq('user_id', userId).maybeSingle();

      if (response == null) return null;

      return _mapToDriverProfile(response);
    } catch (e) {
      debugPrint('Error fetching driver profile: $e');
      return null;
    }
  }

  @override
  Future<DriverProfileModel> createDriverProfile(
      DriverProfileModel profile) async {
    try {
      final response = await SupabaseService.client
          .from('driver_profiles')
          .insert(profile.toJson())
          .select('''
            *,
            profiles!inner(full_name, phone_number, email)
          ''').single();

      return _mapToDriverProfile(response);
    } catch (e) {
      debugPrint('Error creating driver profile: $e');
      rethrow;
    }
  }

  @override
  Future<DriverProfileModel> updateDriverProfile(
      DriverProfileModel profile) async {
    try {
      final response = await SupabaseService.client
          .from('driver_profiles')
          .update(profile.toJson())
          .eq('user_id', profile.userId)
          .select('''
            *,
            profiles!inner(full_name, phone_number, email)
          ''').single();

      return _mapToDriverProfile(response);
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateDriverAvailability(String userId, bool isAvailable) async {
    try {
      await SupabaseService.client.from('driver_profiles').update({
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating driver availability: $e');
      rethrow;
    }
  }

  @override
  Stream<List<DeliveryJobModel>> watchAvailableJobs() {
    // Note: Stream doesn't support complex joins, so we use a simpler approach
    return SupabaseService.client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('status', 'available')
        .map((data) =>
            data.map((json) => DeliveryJobModel.fromJson(json)).toList());
  }

  @override
  Stream<DeliveryJobModel> watchJobStatus(String jobId) {
    return SupabaseService.client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((data) => DeliveryJobModel.fromJson(data.first));
  }

  // Helper methods to map database responses to models
  DeliveryJobModel _mapToDeliveryJob(Map<String, dynamic> json) {
    final rental = json['rentals'];
    final item = rental?['items'];
    final renterProfile = rental?['renter_profile'];
    final ownerProfile = rental?['owner_profile'];

    return DeliveryJobModel.fromJson({
      ...json,
      'item_name': item?['name'] ?? 'Unknown Item',
      'customer_name': renterProfile?['full_name'],
      'customer_phone': renterProfile?['phone_number'],
      'owner_name': ownerProfile?['full_name'],
      'owner_phone': ownerProfile?['phone_number'],
    });
  }

  DriverProfileModel _mapToDriverProfile(Map<String, dynamic> json) {
    final profile = json['profiles'];

    return DriverProfileModel.fromJson({
      ...json,
      'user_name': profile?['full_name'],
      'user_phone': profile?['phone_number'],
      'user_email': profile?['email'],
    });
  }

  String _deliveryStatusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'pending_approval';
      case DeliveryStatus.approved:
        return 'approved';
      case DeliveryStatus.driverAssigned:
        return 'driver_assigned';
      case DeliveryStatus.driverHeadingToPickup:
        return 'driver_heading_to_pickup';
      case DeliveryStatus.itemCollected:
        return 'item_collected';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'driver_heading_to_delivery';
      case DeliveryStatus.itemDelivered:
        return 'item_delivered';
      case DeliveryStatus.returnRequested:
        return 'return_requested';
      case DeliveryStatus.returnScheduled:
        return 'return_scheduled';
      case DeliveryStatus.returnCollected:
        return 'return_collected';
      case DeliveryStatus.returnDelivered:
        return 'return_delivered';
      case DeliveryStatus.completed:
        return 'completed';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  @override
  Future<double> getDriverTodayEarnings(String driverId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await SupabaseService.client
          .from('deliveries')
          .select('driver_earnings')
          .eq('driver_id', driverId)
          .inFilter('status', ['item_delivered', 'return_delivered'])
          .gte('dropoff_time', startOfDay.toIso8601String())
          .lt('dropoff_time', endOfDay.toIso8601String());

      double totalEarnings = 0.0;
      for (final delivery in response) {
        totalEarnings +=
            (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }

      return totalEarnings;
    } catch (e) {
      debugPrint('Error fetching today earnings: $e');
      return 0.0;
    }
  }

  @override
  Future<Map<String, dynamic>> getDriverMetrics(String driverId) async {
    try {
      debugPrint('📊 Getting driver metrics for: $driverId');

      // Get today's earnings
      final todayEarnings = await getDriverTodayEarnings(driverId);
      debugPrint('💰 Today earnings: $todayEarnings');

      // Get available balance
      final availableBalance = await getDriverAvailableBalance(driverId);
      debugPrint('💰 Available balance: $availableBalance');

      // Get total deliveries for today (completed deliveries)
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      final todayDeliveriesResponse = await SupabaseService.client
          .from('deliveries')
          .select('id')
          .eq('driver_id', driverId)
          .inFilter('status', ['item_delivered', 'return_delivered']).gte(
              'dropoff_time', startOfToday.toIso8601String());

      final todayDeliveries = todayDeliveriesResponse.length;
      debugPrint('📦 Today deliveries: $todayDeliveries');

      // Get weekly earnings (last 7 days)
      final weekStart = DateTime.now().subtract(const Duration(days: 7));
      final weeklyEarningsResponse = await SupabaseService.client
          .from('deliveries')
          .select('driver_earnings')
          .eq('driver_id', driverId)
          .inFilter('status', ['item_delivered', 'return_delivered']).gte(
              'dropoff_time', weekStart.toIso8601String());

      double weekEarnings = 0.0;
      for (final delivery in weeklyEarningsResponse) {
        weekEarnings +=
            (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
      }
      debugPrint('💰 Week earnings: $weekEarnings');

      // Create daily breakdown for the week
      final Map<String, dynamic> dailyEarnings = {};
      for (int i = 0; i < 7; i++) {
        final day = DateTime.now().subtract(Duration(days: i));
        final dayKey = 'day_${day.day}';

        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayEarningsResponse = await SupabaseService.client
            .from('deliveries')
            .select('driver_earnings')
            .eq('driver_id', driverId)
            .inFilter('status', ['item_delivered', 'return_delivered'])
            .gte('dropoff_time', dayStart.toIso8601String())
            .lt('dropoff_time', dayEnd.toIso8601String());

        double dayEarnings = 0.0;
        for (final delivery in dayEarningsResponse) {
          dayEarnings +=
              (delivery['driver_earnings'] as num?)?.toDouble() ?? 0.0;
        }
        dailyEarnings[dayKey] = dayEarnings;
      }

      final metrics = {
        'today_earnings': todayEarnings,
        'week_earnings': weekEarnings,
        'today_deliveries': todayDeliveries,
        'available_balance': availableBalance,
        'daily_earnings': dailyEarnings,
      };

      debugPrint('📊 Driver metrics calculated: $metrics');
      return metrics;
    } catch (e) {
      debugPrint('❌ Error getting driver metrics: $e');
      return {
        'today_earnings': 0.0,
        'week_earnings': 0.0,
        'today_deliveries': 0,
        'available_balance': 0.0,
        'daily_earnings': {},
      };
    }
  }

  @override
  Future<void> submitDeliveryRating({
    required String deliveryId,
    required int driverRating,
    required int serviceRating,
    String? comment,
  }) async {
    try {
      // Update the delivery with customer rating
      await SupabaseService.client.from('deliveries').update({
        'customer_rating': driverRating,
        'customer_tip':
            serviceRating, // Using customer_tip field for service rating temporarily
      }).eq('id', deliveryId);

      // Update driver profile average rating
      final delivery = await SupabaseService.client
          .from('deliveries')
          .select('driver_id')
          .eq('id', deliveryId)
          .single();

      final driverId = delivery['driver_id'] as String;
      await _updateDriverAverageRating(driverId);

      debugPrint('✅ Delivery rating submitted for delivery: $deliveryId');
    } catch (e) {
      debugPrint('❌ Error submitting delivery rating: $e');
      rethrow;
    }
  }

  Future<void> _updateDriverAverageRating(String driverId) async {
    try {
      // Calculate new average rating from all deliveries
      final ratingsResponse = await SupabaseService.client
          .from('deliveries')
          .select('customer_rating')
          .eq('driver_id', driverId)
          .not('customer_rating', 'is', null);

      if (ratingsResponse.isNotEmpty) {
        final ratings = ratingsResponse
            .map((r) => (r['customer_rating'] as num).toDouble())
            .toList();

        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

        // Update driver profile
        await SupabaseService.client
            .from('driver_profiles')
            .update({'average_rating': averageRating}).eq('user_id', driverId);

        debugPrint('✅ Updated driver average rating to: $averageRating');
      }
    } catch (e) {
      debugPrint('❌ Error updating driver average rating: $e');
    }
  }

  // ============== PHASE 1: DRIVER EFFICIENCY CORE ==============

  // Enhanced smart availability management
  @override
  Future<Map<String, dynamic>> toggleDriverAvailabilityEnhanced(
      String driverId) async {
    try {
      final isCurrentlyAvailable = await _isDriverAvailable(driverId);

      if (isCurrentlyAvailable) {
        // Driver wants to go offline - use smart offline function
        return await _requestDriverOffline(driverId);
      } else {
        // Driver wants to go online - simple toggle
        await SupabaseService.client.from('driver_profiles').update({
          'is_available': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', driverId);

        return {
          'success': true,
          'message': 'You are now online and available for deliveries',
          'is_available': true,
        };
      }
    } catch (e) {
      debugPrint('Error toggling driver availability: $e');
      return {
        'success': false,
        'message': 'Failed to update availability status',
        'is_available': false,
      };
    }
  }

  // Smart offline request - handles active deliveries
  Future<Map<String, dynamic>> _requestDriverOffline(String driverId) async {
    try {
      final result = await SupabaseService.client
          .rpc('request_driver_offline', params: {'driver_user_id': driverId});

      final canGoOffline = result[0]['can_go_offline'] as bool;
      final activeDeliveries = result[0]['active_deliveries'] as int;

      if (canGoOffline) {
        return {
          'success': true,
          'message': 'You are now offline',
          'is_available': false,
        };
      } else {
        return {
          'success': false,
          'message':
              'Complete your $activeDeliveries active ${activeDeliveries == 1 ? 'delivery' : 'deliveries'} first',
          'is_available': true,
          'requires_completion': true,
          'active_deliveries': activeDeliveries,
        };
      }
    } catch (e) {
      debugPrint('Error requesting driver offline: $e');
      return {
        'success': false,
        'message': 'Failed to update availability status',
        'is_available': true,
      };
    }
  }

  // Check if driver is currently available
  Future<bool> _isDriverAvailable(String driverId) async {
    try {
      final response = await SupabaseService.client
          .from('driver_profiles')
          .select('is_available')
          .eq('user_id', driverId)
          .single();

      return response['is_available'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking driver availability: $e');
      return false;
    }
  }

  // Batch Delivery Management
  @override
  Future<List<DeliveryJobModel>> getAvailableJobsForBatching(String driverId,
      {double radiusKm = 5.0}) async {
    try {
      // Get jobs within radius (simplified - in production use PostGIS)
      final response = await SupabaseService.client
          .from('deliveries')
          .select('''
            *,
            rentals!inner(
              id, renter_id, owner_id, delivery_required,
              items!inner(id, name, location),
              renter_profile:profiles!renter_id(id, full_name, phone_number),
              owner_profile:profiles!owner_id(id, full_name, phone_number)
            )
          ''')
          .eq('status', 'available')
          .filter('driver_id', 'is', null)
          .filter('batch_group_id', 'is', null)
          .limit(10); // Limit for performance

      return response.map((json) => _mapToDeliveryJob(json)).toList();
    } catch (e) {
      debugPrint('Error fetching available jobs for batching: $e');
      return [];
    }
  }

  // Create a delivery batch
  @override
  Future<String?> createDeliveryBatch(
      String driverId, List<String> deliveryIds) async {
    try {
      if (deliveryIds.isEmpty || deliveryIds.length > 3) {
        throw Exception('Batch must contain 1-3 deliveries');
      }

      final result =
          await SupabaseService.client.rpc('create_delivery_batch', params: {
        'driver_user_id': driverId,
        'delivery_ids': deliveryIds,
      });

      return result as String?;
    } catch (e) {
      debugPrint('Error creating delivery batch: $e');
      return null;
    }
  }

  // Get driver's current batch
  @override
  Future<DeliveryBatchModel?> getDriverCurrentBatch(String driverId) async {
    try {
      final response = await SupabaseService.client
          .from('delivery_batches')
          .select('*')
          .eq('driver_id', driverId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) return null;

      // Get deliveries in this batch
      final deliveriesResponse =
          await SupabaseService.client.from('deliveries').select('''
            *,
            rentals!inner(
              id, renter_id, owner_id,
              items!inner(id, name, location),
              renter_profile:profiles!renter_id(id, full_name, phone_number),
              owner_profile:profiles!owner_id(id, full_name, phone_number)
            )
          ''').eq('batch_group_id', response['id']).order('sequence_order');

      final deliveries =
          deliveriesResponse.map((json) => _mapToDeliveryJob(json)).toList();

      return DeliveryBatchModel.fromJson(response)
          .copyWith(deliveries: deliveries);
    } catch (e) {
      debugPrint('Error fetching driver current batch: $e');
      return null;
    }
  }

  // Enhanced available jobs query - filters by driver availability
  @override
  Future<List<DeliveryJobModel>> getAvailableJobsEnhanced(
      String driverId) async {
    try {
      debugPrint('🔍 Checking available jobs for driver: $driverId');

      // First check if driver is available
      final isAvailable = await _isDriverAvailable(driverId);
      debugPrint('📡 Driver availability status: $isAvailable');

      if (!isAvailable) {
        debugPrint('❌ Driver is offline - returning empty job list');
        return []; // Return empty list if driver is offline
      }

      debugPrint('🔎 Fetching available jobs from database...');

      // Get available jobs not assigned to batches
      final response = await SupabaseService.client
          .from('deliveries')
          .select('''
            *,
            rentals!inner(
              id, renter_id, owner_id, delivery_required,
              items!inner(id, name, location),
              renter_profile:profiles!renter_id(id, full_name, phone_number),
              owner_profile:profiles!owner_id(id, full_name, phone_number)
            )
          ''')
          .eq('status', 'available')
          .filter('driver_id', 'is', null)
          .filter('batch_group_id', 'is', null)
          .order('created_at');

      debugPrint('📦 Database returned ${response.length} available jobs');

      final jobs = response.map((json) => _mapToDeliveryJob(json)).toList();

      debugPrint('✅ Successfully mapped ${jobs.length} delivery jobs');
      for (int i = 0; i < jobs.length && i < 3; i++) {
        debugPrint(
            '   Job ${i + 1}: ${jobs[i].id.substring(0, 8)} - ${jobs[i].itemName} (\$${jobs[i].fee})');
      }

      return jobs;
    } catch (e) {
      debugPrint('❌ Error fetching enhanced available jobs: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get driver's active deliveries (includes batch jobs)
  Future<List<DeliveryJobModel>> getDriverActiveDeliveries(
      String driverId) async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('''
            *,
            rentals!inner(
              id, renter_id, owner_id,
              items!inner(id, name, location),
              renter_profile:profiles!renter_id(id, full_name, phone_number),
              owner_profile:profiles!owner_id(id, full_name, phone_number)
            )
          ''')
          .eq('driver_id', driverId)
          .not('status', 'in', '(delivered,cancelled,returned)')
          .order('batch_group_id, sequence_order');

      return response.map((json) => _mapToDeliveryJob(json)).toList();
    } catch (e) {
      debugPrint('Error fetching driver active deliveries: $e');
      return [];
    }
  }

  // Update driver performance score after delivery completion
  Future<void> updateDriverPerformanceScore(
      String driverId, int customerRating) async {
    try {
      // In production, this would use a more sophisticated algorithm
      // For now, we'll update the performance score based on ratings
      await SupabaseService.client.rpc('update_driver_performance', params: {
        'driver_user_id': driverId,
        'new_rating': customerRating,
      });
    } catch (e) {
      debugPrint('Error updating driver performance score: $e');
    }
  }

  // Calculate driver priority for job assignment
  @override
  Future<int> calculateDriverPriorityScore(
      String driverId, double pickupLat, double pickupLng) async {
    try {
      final result = await SupabaseService.client
          .rpc('calculate_driver_priority_score', params: {
        'driver_user_id': driverId,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
      });

      return result as int? ?? 50;
    } catch (e) {
      debugPrint('Error calculating driver priority score: $e');
      return 50; // Default score
    }
  }

  /// Create a return delivery request
  @override
  Future<String> createReturnDelivery({
    required String originalDeliveryId,
    required String returnAddress,
    required String contactNumber,
    DateTime? scheduledTime,
    String? specialInstructions,
  }) async {
    try {
      // Get the original delivery to retrieve item and owner information
      final originalDelivery = await SupabaseService.client
          .from('deliveries')
          .select(
              '*, rentals!inner(item_id, owner_id, renter_id, items!inner(name))')
          .eq('id', originalDeliveryId)
          .single();

      // Create return delivery job
      final response = await SupabaseService.client
          .from('deliveries')
          .insert({
            'rental_id': originalDelivery['rental_id'],
            'pickup_address':
                returnAddress, // Where renter currently has the item
            'dropoff_address': originalDelivery[
                'pickup_address'], // Return to owner's original location
            'fee': 18.00, // Updated return fee (higher than initial delivery)
            'status': 'pending_approval', // Requires owner approval first
            'delivery_type': 'return_pickup',
            'estimated_duration': 30,
            'distance_km': 5.0,
            'driver_earnings': 14.0, // Higher earnings for return jobs
            'special_instructions': specialInstructions ??
                'Return pickup - please verify item condition',
            'lender_approval_required': true,
            'is_return_delivery': true,
            'original_delivery_id': originalDeliveryId,
            'return_scheduled_time': scheduledTime?.toIso8601String(),
          })
          .select()
          .single();

      // Create notification for lender to approve return (temporarily disabled)
      // TODO: Re-enable when delivery_notifications table is created
      // await SupabaseService.client.rpc('create_delivery_notification', params: {
      //   'p_delivery_id': response['id'],
      //   'p_recipient_id': ownerId,
      //   'p_notification_type': 'delivery_requested',
      //   'p_title': 'Return Pickup Approval Required',
      //   'p_message':
      //       'A customer has requested return pickup for "$itemName". Please approve or it will auto-approve in 2 hours.',
      // });

      // Create notification for renter confirming request (temporarily disabled)
      // TODO: Re-enable when delivery_notifications table is created
      // await SupabaseService.client.rpc('create_delivery_notification', params: {
      //   'p_delivery_id': response['id'],
      //   'p_recipient_id': renterId,
      //   'p_notification_type': 'return_scheduled',
      //   'p_title': 'Return Pickup Requested',
      //   'p_message':
      //       'Your return pickup request for "$itemName" has been submitted and is waiting for owner approval.',
      // });

      debugPrint(
          '📤 Return delivery notifications would be sent (currently disabled - table missing)');

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating return delivery: $e');
      throw Exception('Failed to create return delivery request');
    }
  }

  /// Geocode and update missing coordinates for deliveries
  @override
  Future<void> updateMissingCoordinates() async {
    try {
      // Get deliveries with missing coordinates
      final response = await SupabaseService.client
          .from('deliveries')
          .select(
              'id, pickup_address, dropoff_address, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude')
          .or('pickup_latitude.is.null,pickup_longitude.is.null,dropoff_latitude.is.null,dropoff_longitude.is.null');

      if (response.isEmpty) {
        debugPrint('✅ No deliveries with missing coordinates found');
        return;
      }

      debugPrint(
          '🔍 Found ${response.length} deliveries with missing coordinates');

      final LocationService locationService = LocationService();

      for (final delivery in response) {
        final String deliveryId = delivery['id'];
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Check pickup coordinates
        if (delivery['pickup_latitude'] == null ||
            delivery['pickup_longitude'] == null) {
          final String pickupAddress = delivery['pickup_address'] ?? '';
          if (pickupAddress.isNotEmpty) {
            final position =
                await locationService.getCoordinatesFromAddress(pickupAddress);
            if (position != null) {
              updates['pickup_latitude'] = position.latitude.toString();
              updates['pickup_longitude'] = position.longitude.toString();
              needsUpdate = true;
              debugPrint(
                  '📍 Geocoded pickup: $pickupAddress -> ${position.latitude}, ${position.longitude}');
            }
          }
        }

        // Check delivery coordinates
        if (delivery['dropoff_latitude'] == null ||
            delivery['dropoff_longitude'] == null) {
          final String dropoffAddress = delivery['dropoff_address'] ?? '';
          if (dropoffAddress.isNotEmpty) {
            final position =
                await locationService.getCoordinatesFromAddress(dropoffAddress);
            if (position != null) {
              updates['dropoff_latitude'] = position.latitude.toString();
              updates['dropoff_longitude'] = position.longitude.toString();
              needsUpdate = true;
              debugPrint(
                  '📍 Geocoded dropoff: $dropoffAddress -> ${position.latitude}, ${position.longitude}');
            }
          }
        }

        // Update the delivery if we have new coordinates
        if (needsUpdate) {
          updates['updated_at'] = DateTime.now().toIso8601String();

          await SupabaseService.client
              .from('deliveries')
              .update(updates)
              .eq('id', deliveryId);

          debugPrint('✅ Updated coordinates for delivery: $deliveryId');
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('✅ Finished updating missing coordinates');
    } catch (e) {
      debugPrint('❌ Error updating missing coordinates: $e');
    }
  }

  // Driver Withdrawal Operations
  @override
  Future<double> getDriverAvailableBalance(String driverId) async {
    try {
      debugPrint('💰 Getting available balance for driver: $driverId');

      final response = await SupabaseService.client.rpc(
          'get_driver_available_balance',
          params: {'driver_user_id': driverId});

      final balance = (response as num).toDouble();
      debugPrint('💰 Available balance: \$${balance.toStringAsFixed(2)}');

      return balance;
    } catch (e) {
      debugPrint('❌ Error getting driver available balance: $e');
      return 0.0;
    }
  }

  @override
  Future<DriverWithdrawalModel> processWithdrawal(
      String driverId, double amount) async {
    try {
      debugPrint(
          '💳 Processing withdrawal for driver: $driverId, amount: \$${amount.toStringAsFixed(2)}');

      final response = await SupabaseService.client
          .rpc('process_driver_withdrawal', params: {
        'driver_user_id': driverId,
        'withdrawal_amount': amount,
      });

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✅ Withdrawal processed successfully');

        // Get the created withdrawal record
        final withdrawalId = result['withdrawal_id'] as String;
        final withdrawal = await getWithdrawalById(withdrawalId);

        if (withdrawal != null) {
          return withdrawal;
        } else {
          throw Exception('Withdrawal created but could not retrieve details');
        }
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        debugPrint('❌ Withdrawal failed: $error');
        throw Exception('Withdrawal failed: $error');
      }
    } catch (e) {
      debugPrint('❌ Error processing withdrawal: $e');
      throw Exception('Failed to process withdrawal: ${e.toString()}');
    }
  }

  @override
  Future<List<DriverWithdrawalModel>> getDriverWithdrawals(
      String driverId) async {
    try {
      debugPrint('📋 Getting withdrawals for driver: $driverId');

      final response = await SupabaseService.client
          .from('driver_withdrawals')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      final withdrawals =
          response.map((json) => DriverWithdrawalModel.fromJson(json)).toList();
      debugPrint('📋 Found ${withdrawals.length} withdrawals');

      return withdrawals;
    } catch (e) {
      debugPrint('❌ Error getting driver withdrawals: $e');
      return [];
    }
  }

  @override
  Future<DriverWithdrawalModel?> getWithdrawalById(String withdrawalId) async {
    try {
      debugPrint('🔍 Getting withdrawal by ID: $withdrawalId');

      final response = await SupabaseService.client
          .from('driver_withdrawals')
          .select('*')
          .eq('id', withdrawalId)
          .single();

      final withdrawal = DriverWithdrawalModel.fromJson(response);
      debugPrint(
          '🔍 Found withdrawal: \$${withdrawal.amount.toStringAsFixed(2)}');

      return withdrawal;
    } catch (e) {
      debugPrint('❌ Error getting withdrawal by ID: $e');
      return null;
    }
  }
}
