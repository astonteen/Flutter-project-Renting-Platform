import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/profile/data/repositories/profile_repository.dart';
import 'package:rent_ease/features/profile/data/models/profile_model.dart';
import 'package:rent_ease/features/profile/data/models/user_statistics_model.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadUserStatistics extends ProfileEvent {
  final String userId;

  const LoadUserStatistics(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final ProfileModel profile;

  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UploadProfilePicture extends ProfileEvent {
  final String userId;
  final Uint8List imageBytes;
  final String fileName;

  const UploadProfilePicture({
    required this.userId,
    required this.imageBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [userId, imageBytes, fileName];
}

class StartRealtimeUpdates extends ProfileEvent {
  final String userId;

  const StartRealtimeUpdates(this.userId);

  @override
  List<Object?> get props => [userId];
}

class StopRealtimeUpdates extends ProfileEvent {}

class RefreshProfile extends ProfileEvent {
  final String userId;

  const RefreshProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  final UserStatisticsModel statistics;

  const ProfileLoaded({
    required this.profile,
    required this.statistics,
  });

  @override
  List<Object?> get props => [profile, statistics];
}

class ProfileActionLoading extends ProfileState {
  final String action;

  const ProfileActionLoading(this.action);

  @override
  List<Object?> get props => [action];
}

class ProfileUpdated extends ProfileState {
  final ProfileModel profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfilePictureUploaded extends ProfileState {
  final String avatarUrl;

  const ProfilePictureUploaded(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

class ProfileError extends ProfileState {
  final String message;
  final String? errorType;

  const ProfileError(this.message, {this.errorType});

  @override
  List<Object?> get props => [message, errorType];
}

class ProfileStatisticsUpdated extends ProfileState {
  final UserStatisticsModel statistics;

  const ProfileStatisticsUpdated(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;
  StreamSubscription<ProfileModel?>? _profileSubscription;
  StreamSubscription<UserStatisticsModel>? _statisticsSubscription;

  ProfileModel? _currentProfile;
  UserStatisticsModel? _currentStatistics;

  ProfileBloc({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository(),
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LoadUserStatistics>(_onLoadUserStatistics);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadProfilePicture>(_onUploadProfilePicture);
    on<StartRealtimeUpdates>(_onStartRealtimeUpdates);
    on<StopRealtimeUpdates>(_onStopRealtimeUpdates);
    on<RefreshProfile>(_onRefreshProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      // Load profile and statistics in parallel
      final futures = await Future.wait([
        _repository.getCurrentUserProfile(),
        _repository.getUserStatistics(event.userId),
      ]);

      final profile = futures[0] as ProfileModel?;
      final statistics = futures[1] as UserStatisticsModel;

      if (profile == null) {
        emit(const ProfileError('Profile not found'));
        return;
      }

      _currentProfile = profile;
      _currentStatistics = statistics;

      emit(ProfileLoaded(
        profile: profile,
        statistics: statistics,
      ));
    } catch (e) {
      debugPrint('Error loading profile: $e');
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserStatistics(
    LoadUserStatistics event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final statistics = await _repository.getUserStatistics(event.userId);
      _currentStatistics = statistics;
      emit(ProfileStatisticsUpdated(statistics));
    } catch (e) {
      debugPrint('Error loading user statistics: $e');
      emit(ProfileError('Failed to load statistics: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileActionLoading('updating_profile'));

    try {
      final updatedProfile = await _repository.updateProfile(event.profile);
      _currentProfile = updatedProfile;

      emit(ProfileUpdated(updatedProfile));

      // If we have current statistics, emit the full loaded state
      if (_currentStatistics != null) {
        emit(ProfileLoaded(
          profile: updatedProfile,
          statistics: _currentStatistics!,
        ));
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onUploadProfilePicture(
    UploadProfilePicture event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileActionLoading('uploading_picture'));

    try {
      final avatarUrl = await _repository.uploadProfilePicture(
        event.userId,
        event.imageBytes,
        event.fileName,
      );

      emit(ProfilePictureUploaded(avatarUrl));

      // Update current profile with new avatar URL
      if (_currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(avatarUrl: avatarUrl);

        if (_currentStatistics != null) {
          emit(ProfileLoaded(
            profile: _currentProfile!,
            statistics: _currentStatistics!,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      emit(ProfileError('Failed to upload picture: ${e.toString()}'));
    }
  }

  Future<void> _onStartRealtimeUpdates(
    StartRealtimeUpdates event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Cancel existing subscriptions first
      await _profileSubscription?.cancel();
      await _statisticsSubscription?.cancel();

      // Subscribe to profile changes with proper error handling
      _profileSubscription = _repository.watchProfile(event.userId).listen(
        (profile) {
          if (profile != null && !emit.isDone) {
            _currentProfile = profile;
            if (_currentStatistics != null && !emit.isDone) {
              emit(ProfileLoaded(
                profile: profile,
                statistics: _currentStatistics!,
              ));
            }
          }
        },
        onError: (error) {
          if (!emit.isDone) {
            debugPrint('Profile stream error: $error');
          }
        },
      );

      // Subscribe to statistics changes with proper error handling
      _statisticsSubscription =
          _repository.watchUserStatistics(event.userId).listen(
        (statistics) {
          if (!emit.isDone) {
            _currentStatistics = statistics;
            if (_currentProfile != null && !emit.isDone) {
              emit(ProfileLoaded(
                profile: _currentProfile!,
                statistics: statistics,
              ));
            } else if (!emit.isDone) {
              emit(ProfileStatisticsUpdated(statistics));
            }
          }
        },
        onError: (error) {
          if (!emit.isDone) {
            debugPrint('Statistics stream error: $error');
          }
        },
      );
    } catch (e) {
      if (!emit.isDone) {
        debugPrint('Error starting realtime updates: $e');
        emit(ProfileError('Failed to start realtime updates: ${e.toString()}'));
      }
    }
  }

  Future<void> _onStopRealtimeUpdates(
    StopRealtimeUpdates event,
    Emitter<ProfileState> emit,
  ) async {
    await _profileSubscription?.cancel();
    await _statisticsSubscription?.cancel();
    _profileSubscription = null;
    _statisticsSubscription = null;
  }

  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (_currentProfile == null) {
      // If no current profile, do a full load
      add(LoadProfile(event.userId));
      return;
    }

    try {
      // Refresh both profile and statistics
      final futures = await Future.wait([
        _repository.getCurrentUserProfile(),
        _repository.getUserStatistics(event.userId),
      ]);

      final profile = futures[0] as ProfileModel?;
      final statistics = futures[1] as UserStatisticsModel;

      if (profile != null) {
        _currentProfile = profile;
        _currentStatistics = statistics;

        emit(ProfileLoaded(
          profile: profile,
          statistics: statistics,
        ));
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
      emit(ProfileError('Failed to refresh profile: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    _statisticsSubscription?.cancel();
    return super.close();
  }

  // Helper getters
  ProfileModel? get currentProfile => _currentProfile;
  UserStatisticsModel? get currentStatistics => _currentStatistics;
}
