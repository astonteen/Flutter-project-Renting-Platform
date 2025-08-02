import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/data/models/driver_profile_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_batch_model.dart';
import 'package:rent_ease/features/delivery/data/repositories/delivery_repository.dart';

// Events
abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class ShowJobRouteEvent extends DeliveryEvent {
  final DeliveryJobModel job;

  const ShowJobRouteEvent(this.job);

  @override
  List<Object?> get props => [job];
}

class LoadAvailableJobs extends DeliveryEvent {}

class LoadDriverJobs extends DeliveryEvent {
  final String driverId;

  const LoadDriverJobs(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class LoadUserDeliveries extends DeliveryEvent {
  final String userId;

  const LoadUserDeliveries(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadDeliveryById extends DeliveryEvent {
  final String deliveryId;

  const LoadDeliveryById(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class AcceptDeliveryJob extends DeliveryEvent {
  final String jobId;
  final String driverId;

  const AcceptDeliveryJob(this.jobId, this.driverId);

  @override
  List<Object?> get props => [jobId, driverId];
}

class UpdateJobStatus extends DeliveryEvent {
  final String jobId;
  final DeliveryStatus status;

  const UpdateJobStatus(this.jobId, this.status);

  @override
  List<Object?> get props => [jobId, status];
}

class UpdateJobWithProof extends DeliveryEvent {
  final String jobId;
  final String proofImageUrl;
  final DeliveryStatus status;

  const UpdateJobWithProof(this.jobId, this.proofImageUrl, this.status);

  @override
  List<Object?> get props => [jobId, proofImageUrl, status];
}

class LoadDriverProfile extends DeliveryEvent {
  final String userId;

  const LoadDriverProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateDriverProfile extends DeliveryEvent {
  final String userId;
  final Map<String, dynamic> profileData;

  const CreateDriverProfile(this.userId, this.profileData);

  @override
  List<Object?> get props => [userId, profileData];
}

class UpdateDriverProfile extends DeliveryEvent {
  final String userId;
  final Map<String, dynamic> profileData;

  const UpdateDriverProfile(this.userId, this.profileData);

  @override
  List<Object?> get props => [userId, profileData];
}

class UpdateDriverAvailability extends DeliveryEvent {
  final String userId;
  final bool isAvailable;

  const UpdateDriverAvailability(this.userId, this.isAvailable);

  @override
  List<Object?> get props => [userId, isAvailable];
}

class RefreshDeliveryData extends DeliveryEvent {}

class LoadDriverMetrics extends DeliveryEvent {
  final String driverId;

  const LoadDriverMetrics(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class SubmitDeliveryRating extends DeliveryEvent {
  final String deliveryId;
  final int driverRating;
  final int serviceRating;
  final String? comment;

  const SubmitDeliveryRating({
    required this.deliveryId,
    required this.driverRating,
    required this.serviceRating,
    this.comment,
  });

  @override
  List<Object?> get props => [deliveryId, driverRating, serviceRating, comment];
}

// Phase 1 Enhanced Events
class LoadAvailableJobsEnhanced extends DeliveryEvent {
  final String driverId;

  const LoadAvailableJobsEnhanced(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class CreateDeliveryBatch extends DeliveryEvent {
  final String driverId;
  final List<String> jobIds;

  const CreateDeliveryBatch(this.driverId, this.jobIds);

  @override
  List<Object?> get props => [driverId, jobIds];
}

class LoadDriverCurrentBatch extends DeliveryEvent {
  final String driverId;

  const LoadDriverCurrentBatch(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class ToggleDriverAvailabilityEnhanced extends DeliveryEvent {
  final String userId;
  final bool isAvailable;

  const ToggleDriverAvailabilityEnhanced(this.userId, this.isAvailable);

  @override
  List<Object?> get props => [userId, isAvailable];
}

class LoadJobsForBatching extends DeliveryEvent {
  final String driverId;
  final double radiusKm;

  const LoadJobsForBatching(this.driverId, {this.radiusKm = 5.0});

  @override
  List<Object?> get props => [driverId, radiusKm];
}

class CashOut extends DeliveryEvent {
  final String driverId;
  final double amount;

  const CashOut(this.driverId, this.amount);

  @override
  List<Object?> get props => [driverId, amount];
}

class UpdateJobStatusInBatch extends DeliveryEvent {
  final String jobId;
  final DeliveryStatus status;
  final String? batchId;

  const UpdateJobStatusInBatch(this.jobId, this.status, {this.batchId});

  @override
  List<Object?> get props => [jobId, status, batchId];
}

class ApproveDeliveryRequest extends DeliveryEvent {
  final String deliveryId;

  const ApproveDeliveryRequest(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class DeclineDeliveryRequest extends DeliveryEvent {
  final String deliveryId;

  const DeclineDeliveryRequest(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class RequestReturnDelivery extends DeliveryEvent {
  final String originalDeliveryId;
  final String returnAddress;
  final String contactNumber;
  final DateTime scheduledTime;
  final String specialInstructions;

  const RequestReturnDelivery({
    required this.originalDeliveryId,
    required this.returnAddress,
    required this.contactNumber,
    required this.scheduledTime,
    required this.specialInstructions,
  });

  @override
  List<Object?> get props => [
        originalDeliveryId,
        returnAddress,
        contactNumber,
        scheduledTime,
        specialInstructions,
      ];
}

// States
abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryActionLoading extends DeliveryState {
  final String actionType;

  const DeliveryActionLoading(this.actionType);

  @override
  List<Object?> get props => [actionType];
}

class AvailableJobsLoaded extends DeliveryState {
  final List<DeliveryJobModel> jobs;

  const AvailableJobsLoaded(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

class DriverJobsLoaded extends DeliveryState {
  final List<DeliveryJobModel> jobs;
  final DriverProfileModel? driverProfile;

  const DriverJobsLoaded(this.jobs, this.driverProfile);

  @override
  List<Object?> get props => [jobs, driverProfile];
}

class UserDeliveriesLoaded extends DeliveryState {
  final List<DeliveryJobModel> deliveries;

  const UserDeliveriesLoaded(this.deliveries);

  @override
  List<Object?> get props => [deliveries];
}

class DeliveryJobUpdated extends DeliveryState {
  final DeliveryJobModel job;
  final String message;

  const DeliveryJobUpdated(this.job, this.message);

  @override
  List<Object?> get props => [job, message];
}

class DriverProfileLoaded extends DeliveryState {
  final DriverProfileModel profile;

  const DriverProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DriverProfileCreated extends DeliveryState {
  final DriverProfileModel profile;

  const DriverProfileCreated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DriverProfileUpdated extends DeliveryState {
  final DriverProfileModel profile;

  const DriverProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DriverAvailabilityUpdated extends DeliveryState {
  final bool isAvailable;

  const DriverAvailabilityUpdated(this.isAvailable);

  @override
  List<Object?> get props => [isAvailable];
}

class DriverMetricsLoaded extends DeliveryState {
  final Map<String, dynamic> metrics;

  const DriverMetricsLoaded(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

class DeliveryError extends DeliveryState {
  final String message;
  final String? errorType;

  const DeliveryError(this.message, {this.errorType});

  @override
  List<Object?> get props => [message, errorType];
}

class DeliverySuccess extends DeliveryState {
  final String message;

  const DeliverySuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CashOutSuccess extends DeliveryState {
  final String message;

  const CashOutSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Phase 1 Enhanced States
class AvailableJobsEnhancedLoaded extends DeliveryState {
  final List<DeliveryJobModel> jobs;
  final int driverPriorityScore;

  const AvailableJobsEnhancedLoaded(this.jobs, this.driverPriorityScore);

  @override
  List<Object?> get props => [jobs, driverPriorityScore];
}

class DeliveryBatchCreated extends DeliveryState {
  final DeliveryBatchModel batch;

  const DeliveryBatchCreated(this.batch);

  @override
  List<Object?> get props => [batch];
}

class DriverCurrentBatchLoaded extends DeliveryState {
  final DeliveryBatchModel? batch;

  const DriverCurrentBatchLoaded(this.batch);

  @override
  List<Object?> get props => [batch];
}

class JobsForBatchingLoaded extends DeliveryState {
  final List<DeliveryJobModel> jobs;

  const JobsForBatchingLoaded(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

class DriverAvailabilityEnhancedUpdated extends DeliveryState {
  final bool isAvailable;
  final String? message;

  const DriverAvailabilityEnhancedUpdated(this.isAvailable, {this.message});

  @override
  List<Object?> get props => [isAvailable, message];
}

class JobStatusInBatchUpdated extends DeliveryState {
  final DeliveryJobModel job;
  final DeliveryBatchModel? updatedBatch;
  final String message;

  const JobStatusInBatchUpdated(this.job, this.updatedBatch, this.message);

  @override
  List<Object?> get props => [job, updatedBatch, message];
}

// Add new combined state
class DeliveryLoaded extends DeliveryState {
  final List<DeliveryJobModel> availableJobs;
  final List<DeliveryJobModel> driverJobs;
  final DriverProfileModel? driverProfile;

  const DeliveryLoaded({
    required this.availableJobs,
    required this.driverJobs,
    this.driverProfile,
  });

  @override
  List<Object?> get props => [availableJobs, driverJobs, driverProfile];
}

// BLoC
class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository _repository;

  DeliveryBloc(this._repository) : super(DeliveryInitial()) {
    debugPrint('DeliveryBloc created with repository: ${_repository.hashCode}');
    debugPrint('DeliveryBloc instance: $hashCode');

    try {
      debugPrint('Registering event handlers...');
      on<LoadAvailableJobs>(_onLoadAvailableJobs);
      on<LoadDriverJobs>(_onLoadDriverJobs);
      on<LoadUserDeliveries>(_onLoadUserDeliveries);
      on<AcceptDeliveryJob>(_onAcceptDeliveryJob);
      on<UpdateJobStatus>(_onUpdateJobStatus);
      on<UpdateJobWithProof>(_onUpdateJobWithProof);
      on<LoadDriverProfile>(_onLoadDriverProfile);
      on<CreateDriverProfile>(_onCreateDriverProfile);
      on<UpdateDriverProfile>(_onUpdateDriverProfile);
      on<UpdateDriverAvailability>(_onUpdateDriverAvailability);
      on<RefreshDeliveryData>(_onRefreshDeliveryData);
      on<LoadDriverMetrics>(_onLoadDriverMetrics);
      on<SubmitDeliveryRating>(_onSubmitDeliveryRating);
      on<LoadDeliveryById>(_onLoadDeliveryById);
      on<ShowJobRouteEvent>(_onShowJobRoute);

      // Phase 1 Enhanced Event Handlers
      on<LoadAvailableJobsEnhanced>(_onLoadAvailableJobsEnhanced);
      on<CreateDeliveryBatch>(_onCreateDeliveryBatch);
      on<LoadDriverCurrentBatch>(_onLoadDriverCurrentBatch);
      on<ToggleDriverAvailabilityEnhanced>(_onToggleDriverAvailabilityEnhanced);
      on<LoadJobsForBatching>(_onLoadJobsForBatching);

      // Register CashOut event handler
      debugPrint('Registering CashOut event handler...');
      on<CashOut>(_onCashOut);
      debugPrint('CashOut handler registered in DeliveryBloc: $hashCode');

      on<UpdateJobStatusInBatch>(_onUpdateJobStatusInBatch);

      // Approval Event Handlers
      on<ApproveDeliveryRequest>(_onApproveDeliveryRequest);
      on<DeclineDeliveryRequest>(_onDeclineDeliveryRequest);
      on<RequestReturnDelivery>(_onRequestReturnDelivery);

      debugPrint('All event handlers registered successfully');
    } catch (e) {
      debugPrint('Error registering event handlers: $e');
    }
  }

  Future<void> _onLoadAvailableJobs(
    LoadAvailableJobs event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final jobs = await _repository.getAvailableJobs();
      final previousState = state;
      emit(DeliveryLoaded(
        availableJobs: jobs,
        driverJobs:
            previousState is DeliveryLoaded ? previousState.driverJobs : [],
        driverProfile: previousState is DeliveryLoaded
            ? previousState.driverProfile
            : null,
      ));
    } catch (e) {
      debugPrint('Error loading available jobs: $e');
      emit(const DeliveryError(
          'Failed to load available jobs. Please try again.',
          errorType: 'load_jobs'));
    }
  }

  Future<void> _onLoadDriverJobs(
    LoadDriverJobs event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final driverJobs = await _repository.getDriverJobs(event.driverId);
      final availableJobs = await _repository.getAvailableJobs();
      final driverProfile = await _repository.getDriverProfile(event.driverId);
      emit(DeliveryLoaded(
        availableJobs: availableJobs,
        driverJobs: driverJobs,
        driverProfile: driverProfile,
      ));
    } catch (e) {
      debugPrint('Error loading driver jobs: $e');
      emit(const DeliveryError('Failed to load your jobs. Please try again.',
          errorType: 'load_driver_jobs'));
    }
  }

  Future<void> _onLoadUserDeliveries(
    LoadUserDeliveries event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final deliveries = await _repository.getUserDeliveries(event.userId);
      emit(UserDeliveriesLoaded(deliveries));
    } catch (e) {
      debugPrint('Error loading user deliveries: $e');
      emit(const DeliveryError(
          'Failed to load your deliveries. Please try again.',
          errorType: 'load_user_deliveries'));
    }
  }

  Future<void> _onLoadDeliveryById(
    LoadDeliveryById event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final delivery = await _repository.getDeliveryById(event.deliveryId);
      if (delivery != null) {
        emit(DeliveryJobUpdated(delivery, 'Delivery loaded successfully.'));
      } else {
        emit(DeliveryError('Delivery not found with ID: ${event.deliveryId}',
            errorType: 'delivery_not_found'));
      }
    } catch (e) {
      debugPrint('Error loading delivery by ID: $e');
      emit(const DeliveryError('Failed to load delivery. Please try again.',
          errorType: 'load_delivery_by_id'));
    }
  }

  Future<void> _onAcceptDeliveryJob(
    AcceptDeliveryJob event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('accepting_job'));

    try {
      final updatedJob =
          await _repository.acceptJob(event.jobId, event.driverId);
      emit(DeliveryJobUpdated(
          updatedJob, 'Job accepted successfully! Head to pickup location.'));
    } catch (e) {
      debugPrint('Error accepting job: $e');
      if (e.toString().contains('violates row-level security')) {
        emit(const DeliveryError('This job is no longer available.',
            errorType: 'job_unavailable'));
      } else {
        emit(const DeliveryError('Failed to accept job. Please try again.',
            errorType: 'accept_job'));
      }
    }
  }

  Future<void> _onUpdateJobStatus(
    UpdateJobStatus event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('updating_status'));

    try {
      final updatedJob =
          await _repository.updateJobStatus(event.jobId, event.status);
      final message = _getStatusUpdateMessage(event.status);
      emit(DeliveryJobUpdated(updatedJob, message));

      // If job is delivered, refresh driver profile to update earnings
      if (updatedJob.status == DeliveryStatus.itemDelivered &&
          updatedJob.driverId != null) {
        add(LoadDriverProfile(updatedJob.driverId!));
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
      emit(const DeliveryError('Failed to update job status. Please try again.',
          errorType: 'update_status'));
    }
  }

  Future<void> _onUpdateJobWithProof(
    UpdateJobWithProof event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('uploading_proof'));

    try {
      // Get job details to access driverId for profile refresh
      final job = await _repository.getDeliveryById(event.jobId);

      await _repository.updateJobWithProof(
          event.jobId, event.proofImageUrl, event.status);
      final message = _getStatusUpdateMessage(event.status);
      emit(DeliverySuccess('$message Proof uploaded successfully.'));

      // If job is delivered, refresh driver profile to update earnings
      if (job != null &&
          event.status == DeliveryStatus.itemDelivered &&
          job.driverId != null) {
        add(LoadDriverProfile(job.driverId!));
      }
    } catch (e) {
      debugPrint('Error updating job with proof: $e');
      emit(const DeliveryError('Failed to upload proof. Please try again.',
          errorType: 'upload_proof'));
    }
  }

  Future<void> _onLoadDriverProfile(
    LoadDriverProfile event,
    Emitter<DeliveryState> emit,
  ) async {
    debugPrint('📥 Processing LoadDriverProfile event for: ${event.userId}');
    emit(DeliveryLoading());

    try {
      final profile = await _repository.getDriverProfile(event.userId);
      if (profile != null) {
        debugPrint(
            '✅ Driver profile loaded successfully: ${profile.userName}, earnings: ${profile.totalEarnings}');
        emit(DriverProfileLoaded(profile));
      } else {
        debugPrint('❌ Driver profile not found for user: ${event.userId}');
        emit(const DeliveryError(
            'Driver profile not found. Please create one first.',
            errorType: 'profile_not_found'));
      }
    } catch (e) {
      debugPrint('❌ Error loading driver profile: $e');
      emit(const DeliveryError(
          'Failed to load driver profile. Please try again.',
          errorType: 'load_profile'));
    }
  }

  Future<void> _onCreateDriverProfile(
    CreateDriverProfile event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('creating_profile'));

    try {
      // Create a DriverProfileModel from the provided data
      final profile = DriverProfileModel(
        id: '', // Will be generated by the database
        userId: event.userId,
        vehicleType: VehicleType.values.firstWhere(
          (e) => e.name == event.profileData['vehicle_type'],
          orElse: () => VehicleType.car,
        ),
        vehicleModel: event.profileData['vehicle_model'],
        licensePlate: event.profileData['license_plate'],
        isActive: event.profileData['is_active'] ?? true,
        isAvailable: event.profileData['is_available'] ?? true,
        currentLocation: event.profileData['current_location'],
        totalDeliveries: 0,
        averageRating: 0.0,
        totalEarnings: 0.0,
        bankAccountNumber: event.profileData['bank_account_number'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdProfile = await _repository.createDriverProfile(profile);
      emit(DriverProfileCreated(createdProfile));
    } catch (e) {
      debugPrint('Error creating driver profile: $e');
      emit(const DeliveryError(
          'Failed to create driver profile. Please try again.',
          errorType: 'create_profile'));
    }
  }

  Future<void> _onUpdateDriverProfile(
    UpdateDriverProfile event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('updating_profile'));

    try {
      // Get the existing profile first
      final existingProfile = await _repository.getDriverProfile(event.userId);
      if (existingProfile == null) {
        emit(const DeliveryError('Driver profile not found.',
            errorType: 'profile_not_found'));
        return;
      }

      // Update the profile with new data
      final updatedProfile = existingProfile.copyWith(
        vehicleType: event.profileData['vehicle_type'] != null
            ? VehicleType.values.firstWhere(
                (e) => e.name == event.profileData['vehicle_type'],
                orElse: () => existingProfile.vehicleType,
              )
            : null,
        vehicleModel: event.profileData['vehicle_model'],
        licensePlate: event.profileData['license_plate'],
        isActive: event.profileData['is_active'],
        isAvailable: event.profileData['is_available'],
        currentLocation: event.profileData['current_location'],
        bankAccountNumber: event.profileData['bank_account_number'],
        updatedAt: DateTime.now(),
      );

      final profile = await _repository.updateDriverProfile(updatedProfile);
      emit(DriverProfileUpdated(profile));
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      emit(const DeliveryError(
          'Failed to update driver profile. Please try again.',
          errorType: 'update_profile'));
    }
  }

  Future<void> _onUpdateDriverAvailability(
    UpdateDriverAvailability event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('updating_availability'));

    try {
      await _repository.updateDriverAvailability(
          event.userId, event.isAvailable);
      emit(DriverAvailabilityUpdated(event.isAvailable));
    } catch (e) {
      debugPrint('Error updating driver availability: $e');
      emit(const DeliveryError(
          'Failed to update availability. Please try again.',
          errorType: 'update_availability'));
    }
  }

  Future<void> _onRefreshDeliveryData(
    RefreshDeliveryData event,
    Emitter<DeliveryState> emit,
  ) async {
    // This will refresh whatever data was last loaded
    // In a real implementation, you might want to track the last loaded data type
    emit(DeliveryLoading());
    add(LoadAvailableJobs());
  }

  Future<void> _onLoadDriverMetrics(
    LoadDriverMetrics event,
    Emitter<DeliveryState> emit,
  ) async {
    debugPrint('📊 Processing LoadDriverMetrics event for: ${event.driverId}');
    emit(DeliveryLoading());

    try {
      final metrics = await _repository.getDriverMetrics(event.driverId);
      debugPrint('✅ Driver metrics loaded successfully: $metrics');
      emit(DriverMetricsLoaded(metrics));
    } catch (e) {
      debugPrint('❌ Error loading driver metrics: $e');
      emit(const DeliveryError(
          'Failed to load driver metrics. Please try again.',
          errorType: 'load_metrics'));
    }
  }

  Future<void> _onSubmitDeliveryRating(
    SubmitDeliveryRating event,
    Emitter<DeliveryState> emit,
  ) async {
    debugPrint(
        '⭐ Processing SubmitDeliveryRating event for delivery: ${event.deliveryId}');
    emit(const DeliveryActionLoading('submitting_rating'));

    try {
      await _repository.submitDeliveryRating(
        deliveryId: event.deliveryId,
        driverRating: event.driverRating,
        serviceRating: event.serviceRating,
        comment: event.comment,
      );

      debugPrint('✅ Delivery rating submitted successfully');
      emit(const DeliverySuccess('Rating submitted successfully'));
    } catch (e) {
      debugPrint('❌ Error submitting delivery rating: $e');
      emit(const DeliveryError('Failed to submit rating. Please try again.',
          errorType: 'submit_rating'));
    }
  }

  // Phase 1 Enhanced Event Handlers
  Future<void> _onLoadAvailableJobsEnhanced(
    LoadAvailableJobsEnhanced event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final jobs = await _repository.getAvailableJobsEnhanced(event.driverId);

      // If enhanced method returns empty, try fallback to regular method
      if (jobs.isEmpty) {
        debugPrint('🔄 Enhanced method returned empty, trying fallback...');
        final fallbackJobs = await _repository.getAvailableJobs();
        debugPrint('📦 Fallback method returned ${fallbackJobs.length} jobs');

        // Default coordinates for priority calculation (would be driver's current location in production)
        final priorityScore = await _repository.calculateDriverPriorityScore(
            event.driverId, 0.0, 0.0);
        emit(AvailableJobsEnhancedLoaded(fallbackJobs, priorityScore));
        return;
      }

      // Default coordinates for priority calculation (would be driver's current location in production)
      final priorityScore = await _repository.calculateDriverPriorityScore(
          event.driverId, 0.0, 0.0);
      emit(AvailableJobsEnhancedLoaded(jobs, priorityScore));
    } catch (e) {
      debugPrint('❌ Error loading enhanced available jobs: $e');

      // Try fallback method as last resort
      try {
        debugPrint('🔄 Attempting fallback to regular available jobs...');
        final fallbackJobs = await _repository.getAvailableJobs();
        final priorityScore = await _repository.calculateDriverPriorityScore(
            event.driverId, 0.0, 0.0);
        emit(AvailableJobsEnhancedLoaded(fallbackJobs, priorityScore));
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        emit(const DeliveryError(
            'Failed to load available jobs. Please try again.',
            errorType: 'load_jobs_enhanced'));
      }
    }
  }

  Future<void> _onCreateDeliveryBatch(
    CreateDeliveryBatch event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('creating_batch'));

    try {
      final batchId =
          await _repository.createDeliveryBatch(event.driverId, event.jobIds);
      if (batchId != null) {
        // Get the created batch details
        final batch = await _repository.getDriverCurrentBatch(event.driverId);
        if (batch != null) {
          emit(DeliveryBatchCreated(batch));
        } else {
          emit(const DeliverySuccess('Delivery batch created successfully!'));
        }
      } else {
        emit(const DeliveryError('Failed to create delivery batch.',
            errorType: 'create_batch'));
      }
    } catch (e) {
      debugPrint('Error creating delivery batch: $e');
      if (e.toString().contains('already has active deliveries')) {
        emit(const DeliveryError(
            'Cannot create batch: You already have active deliveries. Complete them first.',
            errorType: 'batch_conflict'));
      } else {
        emit(const DeliveryError(
            'Failed to create delivery batch. Please try again.',
            errorType: 'create_batch'));
      }
    }
  }

  Future<void> _onLoadDriverCurrentBatch(
    LoadDriverCurrentBatch event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final batch = await _repository.getDriverCurrentBatch(event.driverId);
      emit(DriverCurrentBatchLoaded(batch));
    } catch (e) {
      debugPrint('Error loading driver current batch: $e');
      emit(const DeliveryError(
          'Failed to load current batch. Please try again.',
          errorType: 'load_current_batch'));
    }
  }

  Future<void> _onToggleDriverAvailabilityEnhanced(
    ToggleDriverAvailabilityEnhanced event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('updating_availability'));

    try {
      final result =
          await _repository.toggleDriverAvailabilityEnhanced(event.userId);

      if (result['success'] == true) {
        emit(DriverAvailabilityEnhancedUpdated(
          result['isAvailable'] ?? event.isAvailable,
          message: result['message'],
        ));
      } else {
        emit(DeliveryError(
          result['message'] ?? 'Failed to update availability',
          errorType: 'availability_update_failed',
        ));
      }
    } catch (e) {
      debugPrint('Error updating driver availability: $e');
      emit(const DeliveryError(
          'Failed to update availability. Please try again.',
          errorType: 'update_availability_enhanced'));
    }
  }

  Future<void> _onLoadJobsForBatching(
    LoadJobsForBatching event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryLoading());

    try {
      final jobs = await _repository.getAvailableJobsForBatching(event.driverId,
          radiusKm: event.radiusKm);
      emit(JobsForBatchingLoaded(jobs));
    } catch (e) {
      debugPrint('Error loading jobs for batching: $e');
      emit(const DeliveryError('Failed to load nearby jobs. Please try again.',
          errorType: 'load_batching_jobs'));
    }
  }

  Future<void> _onUpdateJobStatusInBatch(
    UpdateJobStatusInBatch event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('updating_batch_status'));

    try {
      final updatedJob =
          await _repository.updateJobStatus(event.jobId, event.status);

      // If this is part of a batch, get the updated batch
      DeliveryBatchModel? updatedBatch;
      if (event.batchId != null || updatedJob.batchGroupId != null) {
        final driverId = updatedJob.driverId;
        if (driverId != null) {
          updatedBatch = await _repository.getDriverCurrentBatch(driverId);
        }
      }

      final message = _getStatusUpdateMessage(event.status);
      emit(JobStatusInBatchUpdated(updatedJob, updatedBatch, message));
    } catch (e) {
      debugPrint('Error updating job status in batch: $e');
      emit(const DeliveryError('Failed to update job status. Please try again.',
          errorType: 'update_batch_status'));
    }
  }

  Future<void> _onCashOut(CashOut event, Emitter<DeliveryState> emit) async {
    debugPrint(
        '💰 Processing CashOut event for driver: ${event.driverId}, amount: ${event.amount}');
    try {
      emit(const DeliveryActionLoading('processing_cashout'));

      // Process the withdrawal using the new system
      final withdrawal =
          await _repository.processWithdrawal(event.driverId, event.amount);

      debugPrint(
          '✅ Cash out successful: \$${withdrawal.amount.toStringAsFixed(2)}');
      emit(CashOutSuccess(
          'Cash out successful! \$${withdrawal.amount.toStringAsFixed(2)} has been withdrawn.'));
    } catch (e) {
      debugPrint('❌ Cash out failed: $e');
      emit(DeliveryError('Cash out failed: ${e.toString()}',
          errorType: 'cashout_failed'));
    }
  }

  String _getStatusUpdateMessage(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Delivery request pending approval.';
      case DeliveryStatus.approved:
        return 'Delivery approved by owner.';
      case DeliveryStatus.driverAssigned:
        return 'Job accepted!';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Heading to pickup location.';
      case DeliveryStatus.itemCollected:
        return 'Item picked up successfully!';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Heading to delivery location.';
      case DeliveryStatus.itemDelivered:
        return 'Item delivered successfully!';
      case DeliveryStatus.returnRequested:
        return 'Return requested by customer.';
      case DeliveryStatus.returnScheduled:
        return 'Return pickup scheduled.';
      case DeliveryStatus.returnCollected:
        return 'Return item collected successfully!';
      case DeliveryStatus.returnDelivered:
        return 'Item returned successfully!';
      case DeliveryStatus.completed:
        return 'Delivery completed successfully!';
      case DeliveryStatus.cancelled:
        return 'Delivery cancelled.';
    }
  }

  // Convenience methods for common operations
  void loadJobsForDriver(String driverId) {
    add(LoadDriverJobs(driverId));
  }

  void loadDeliveriesForUser(String userId) {
    add(LoadUserDeliveries(userId));
  }

  void loadDeliveryById(String deliveryId) {
    add(LoadDeliveryById(deliveryId));
  }

  void acceptJob(String jobId, String driverId) {
    add(AcceptDeliveryJob(jobId, driverId));
  }

  void startHeadingToPickup(String jobId) {
    add(UpdateJobStatus(jobId, DeliveryStatus.driverHeadingToPickup));
  }

  void markAsPickedUp(String jobId) {
    add(UpdateJobStatus(jobId, DeliveryStatus.itemCollected));
  }

  void startHeadingToDelivery(String jobId) {
    add(UpdateJobStatus(jobId, DeliveryStatus.driverHeadingToDelivery));
  }

  void markAsDelivered(String jobId) {
    add(UpdateJobStatus(jobId, DeliveryStatus.itemDelivered));
  }

  void markAsDeliveredWithProof(String jobId, String proofImageUrl) {
    add(UpdateJobWithProof(jobId, proofImageUrl, DeliveryStatus.itemDelivered));
  }

  void cancelJob(String jobId) {
    add(UpdateJobStatus(jobId, DeliveryStatus.cancelled));
  }

  void toggleDriverAvailability(String userId, bool isAvailable) {
    add(UpdateDriverAvailability(userId, isAvailable));
  }

  void refreshData() {
    add(RefreshDeliveryData());
  }

  void loadDriverMetrics(String driverId) {
    add(LoadDriverMetrics(driverId));
  }

  Future<void> _onApproveDeliveryRequest(
    ApproveDeliveryRequest event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('approving_delivery'));

    try {
      // Update delivery status to approved
      await _repository.updateJobStatus(
          event.deliveryId, DeliveryStatus.approved);

      emit(const DeliverySuccess('Delivery request approved successfully!'));
    } catch (e) {
      debugPrint('Error approving delivery request: $e');
      emit(const DeliveryError(
          'Failed to approve delivery request. Please try again.',
          errorType: 'approve_delivery'));
    }
  }

  Future<void> _onDeclineDeliveryRequest(
    DeclineDeliveryRequest event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('declining_delivery'));

    try {
      // Update delivery status to cancelled
      await _repository.updateJobStatus(
          event.deliveryId, DeliveryStatus.cancelled);

      emit(const DeliverySuccess('Delivery request declined.'));
    } catch (e) {
      debugPrint('Error declining delivery request: $e');
      emit(const DeliveryError(
          'Failed to decline delivery request. Please try again.',
          errorType: 'decline_delivery'));
    }
  }

  Future<void> _onRequestReturnDelivery(
    RequestReturnDelivery event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryActionLoading('requesting_return'));

    try {
      // Create return delivery job in database
      await _repository.createReturnDelivery(
        originalDeliveryId: event.originalDeliveryId,
        returnAddress: event.returnAddress,
        contactNumber: event.contactNumber,
        scheduledTime: event.scheduledTime,
        specialInstructions: event.specialInstructions,
      );

      emit(const DeliverySuccess(
          'Return pickup request submitted! The owner will be notified for approval.'));
    } catch (e) {
      debugPrint('Error requesting return delivery: $e');
      emit(const DeliveryError(
          'Failed to request return pickup. Please try again.',
          errorType: 'request_return'));
    }
  }

  Future<void> _onShowJobRoute(
    ShowJobRouteEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      debugPrint('📍 Route display requested for job: ${event.job.id}');
      // Note: We don't emit any state here to avoid interfering with the LoadDriverJobs state
      // The dashboard will handle route display directly via the arguments passed through navigation
      debugPrint('✅ Route display event processed for ${event.job.itemName}');
    } catch (e) {
      debugPrint('Error handling show route event: $e');
      // Don't emit error for route display issues
    }
  }
}
