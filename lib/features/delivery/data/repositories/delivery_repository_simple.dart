import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

// Simple repository implementation that avoids complex SQL queries
class SimpleDeliveryRepository {
  static Future<List<DeliveryJobModel>> getAvailableJobs() async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('''
            *,
            rentals!inner(
              id, renter_id, owner_id,
              items!inner(id, name),
              renter_profile:profiles!renter_id(id, full_name, phone_number),
              owner_profile:profiles!owner_id(id, full_name, phone_number)
            )
          ''')
          .eq('status', 'approved')
          .isFilter('driver_id', null)
          .order('created_at', ascending: false);

      // Map using the helper method similar to main repository
      final jobs = response.map((json) {
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
      }).toList();

      return jobs;
    } catch (e) {
      debugPrint('Error fetching available jobs: $e');
      rethrow;
    }
  }

  static Future<List<DeliveryJobModel>> getUserDeliveries(String userId) async {
    try {
      // Simple approach: get all deliveries and filter client-side
      final response = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .order('created_at', ascending: false);

      // Filter for user's deliveries client-side to avoid complex SQL
      final userDeliveries = response.where((delivery) {
        // This would need to be enhanced with proper rental lookup
        // For now, we'll use a simplified approach
        return true; // Return all for testing
      }).toList();

      return userDeliveries
          .map((json) => DeliveryJobModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user deliveries: $e');
      rethrow;
    }
  }

  static Future<List<DeliveryJobModel>> getDriverJobs(String driverId) async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('*')
          .eq('driver_id', driverId)
          .neq('status', 'delivered')
          .neq('status', 'returned')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      return response.map((json) => DeliveryJobModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching driver jobs: $e');
      rethrow;
    }
  }

  static Future<DeliveryJobModel> acceptJob(
      String jobId, String driverId) async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .update({
            'driver_id': driverId,
            'status': 'driver_assigned', // Changed from 'accepted'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .eq('status', 'approved') // Changed from 'available'
          .select('*')
          .single();

      return DeliveryJobModel.fromJson(response);
    } catch (e) {
      debugPrint('Error accepting job: $e');
      rethrow;
    }
  }

  static Future<DeliveryJobModel> updateJobStatus(
      String jobId, DeliveryStatus status) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': _deliveryStatusToString(status),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('deliveries')
          .update(updateData)
          .eq('id', jobId)
          .select('*')
          .single();

      return DeliveryJobModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating job status: $e');
      rethrow;
    }
  }

  static String _deliveryStatusToString(DeliveryStatus status) {
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
}
