import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/services/delivery_realtime_service.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

class LenderRealtimeService {
  static final LenderRealtimeService _instance =
      LenderRealtimeService._internal();
  static LenderRealtimeService get instance => _instance;
  LenderRealtimeService._internal();

  StreamSubscription<DeliveryJobModel>? _deliverySubscription;
  String? _currentUserId;
  bool _isSubscribed = false;

  final StreamController<List<DeliveryJobModel>> _pendingApprovalsController =
      StreamController<List<DeliveryJobModel>>.broadcast();
  final StreamController<DeliveryJobModel> _newApprovalController =
      StreamController<DeliveryJobModel>.broadcast();

  Stream<List<DeliveryJobModel>> get pendingApprovals =>
      _pendingApprovalsController.stream;
  Stream<DeliveryJobModel> get newApprovalNotifications =>
      _newApprovalController.stream;

  List<DeliveryJobModel> _currentPendingApprovals = [];

  void initialize() {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _setupRealtimeSubscription();
    }
  }

  void _setupRealtimeSubscription() {
    if (_currentUserId == null || _isSubscribed) return;

    DeliveryRealtimeService.instance
        .subscribeToDeliveryUpdates(_currentUserId!);

    _deliverySubscription =
        DeliveryRealtimeService.instance.deliveryUpdates.listen(
      (delivery) {
        debugPrint(
            '🔔 Lender service received delivery update: ${delivery.id}');
        _handleDeliveryUpdate(delivery);
      },
      onError: (error) {
        debugPrint('❌ Error in lender delivery updates stream: $error');
      },
    );

    _isSubscribed = true;
  }

  void _handleDeliveryUpdate(DeliveryJobModel delivery) {
    if (delivery.userIsOwner &&
        delivery.status == DeliveryStatus.pendingApproval) {
      // Add or update pending approval
      final existingIndex =
          _currentPendingApprovals.indexWhere((d) => d.id == delivery.id);
      if (existingIndex != -1) {
        _currentPendingApprovals[existingIndex] = delivery;
      } else {
        _currentPendingApprovals.add(delivery);
        // Emit new approval notification
        _newApprovalController.add(delivery);
      }
    } else {
      // Remove from pending approvals if status changed
      _currentPendingApprovals.removeWhere((d) => d.id == delivery.id);
    }

    // Emit updated list
    _pendingApprovalsController.add(List.from(_currentPendingApprovals));
  }

  void updatePendingApprovals(List<DeliveryJobModel> approvals) {
    _currentPendingApprovals = approvals
        .where(
          (job) =>
              job.status == DeliveryStatus.pendingApproval && job.userIsOwner,
        )
        .toList();
    _pendingApprovalsController.add(List.from(_currentPendingApprovals));
  }

  void dispose() {
    _deliverySubscription?.cancel();
    if (_isSubscribed) {
      DeliveryRealtimeService.instance.unsubscribeFromDeliveryUpdates();
      _isSubscribed = false;
    }
    _pendingApprovalsController.close();
    _newApprovalController.close();
  }

  void refresh() {
    if (_currentUserId != null) {
      _setupRealtimeSubscription();
    }
  }
}
