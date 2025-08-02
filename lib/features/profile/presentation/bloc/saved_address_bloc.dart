import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';

// Events
abstract class SavedAddressEvent extends Equatable {
  const SavedAddressEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavedAddresses extends SavedAddressEvent {}

class CreateSavedAddress extends SavedAddressEvent {
  final SavedAddressModel address;

  const CreateSavedAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateSavedAddress extends SavedAddressEvent {
  final SavedAddressModel address;

  const UpdateSavedAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class DeleteSavedAddress extends SavedAddressEvent {
  final String addressId;

  const DeleteSavedAddress(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

class SetDefaultAddress extends SavedAddressEvent {
  final String addressId;

  const SetDefaultAddress(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

// States
abstract class SavedAddressState extends Equatable {
  const SavedAddressState();

  @override
  List<Object?> get props => [];
}

class SavedAddressInitial extends SavedAddressState {}

class SavedAddressLoading extends SavedAddressState {}

class SavedAddressLoaded extends SavedAddressState {
  final List<SavedAddressModel> addresses;
  final SavedAddressModel? defaultAddress;

  const SavedAddressLoaded({
    required this.addresses,
    this.defaultAddress,
  });

  @override
  List<Object?> get props => [addresses, defaultAddress];
}

class SavedAddressError extends SavedAddressState {
  final String message;

  const SavedAddressError(this.message);

  @override
  List<Object?> get props => [message];
}

class SavedAddressOperationSuccess extends SavedAddressState {
  final String message;
  final List<SavedAddressModel> addresses;
  final SavedAddressModel? defaultAddress;

  const SavedAddressOperationSuccess({
    required this.message,
    required this.addresses,
    this.defaultAddress,
  });

  @override
  List<Object?> get props => [message, addresses, defaultAddress];
}

// BLoC
class SavedAddressBloc extends Bloc<SavedAddressEvent, SavedAddressState> {
  final SavedAddressRepository _repository;

  SavedAddressBloc(this._repository) : super(SavedAddressInitial()) {
    on<LoadSavedAddresses>(_onLoadSavedAddresses);
    on<CreateSavedAddress>(_onCreateSavedAddress);
    on<UpdateSavedAddress>(_onUpdateSavedAddress);
    on<DeleteSavedAddress>(_onDeleteSavedAddress);
    on<SetDefaultAddress>(_onSetDefaultAddress);
  }

  Future<void> _onLoadSavedAddresses(
    LoadSavedAddresses event,
    Emitter<SavedAddressState> emit,
  ) async {
    emit(SavedAddressLoading());
    try {
      final addresses = await _repository.getUserSavedAddresses();
      final defaultAddress =
          addresses.where((addr) => addr.isDefault).firstOrNull;

      emit(SavedAddressLoaded(
        addresses: addresses,
        defaultAddress: defaultAddress,
      ));
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
      final errorMessage = _getErrorMessage(e);
      emit(SavedAddressError(errorMessage));
    }
  }

  Future<void> _onCreateSavedAddress(
    CreateSavedAddress event,
    Emitter<SavedAddressState> emit,
  ) async {
    emit(SavedAddressLoading());
    try {
      await _repository.createSavedAddress(event.address);

      // Reload addresses to get updated list
      final addresses = await _repository.getUserSavedAddresses();
      final defaultAddress =
          addresses.where((addr) => addr.isDefault).firstOrNull;

      emit(SavedAddressOperationSuccess(
        message: 'Address saved successfully',
        addresses: addresses,
        defaultAddress: defaultAddress,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating saved address: $e');
      }
      final errorMessage = _getErrorMessage(e);
      emit(SavedAddressError(errorMessage));
    }
  }

  Future<void> _onUpdateSavedAddress(
    UpdateSavedAddress event,
    Emitter<SavedAddressState> emit,
  ) async {
    emit(SavedAddressLoading());
    try {
      await _repository.updateSavedAddress(event.address);

      // Reload addresses to get updated list
      final addresses = await _repository.getUserSavedAddresses();
      final defaultAddress =
          addresses.where((addr) => addr.isDefault).firstOrNull;

      emit(SavedAddressOperationSuccess(
        message: 'Address updated successfully',
        addresses: addresses,
        defaultAddress: defaultAddress,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating saved address: $e');
      }
      final errorMessage = _getErrorMessage(e);
      emit(SavedAddressError(errorMessage));
    }
  }

  Future<void> _onDeleteSavedAddress(
    DeleteSavedAddress event,
    Emitter<SavedAddressState> emit,
  ) async {
    emit(SavedAddressLoading());
    try {
      final success = await _repository.deleteSavedAddress(event.addressId);

      if (success) {
        // Reload addresses to get updated list
        final addresses = await _repository.getUserSavedAddresses();
        final defaultAddress =
            addresses.where((addr) => addr.isDefault).firstOrNull;

        emit(SavedAddressOperationSuccess(
          message: 'Address deleted successfully',
          addresses: addresses,
          defaultAddress: defaultAddress,
        ));
      } else {
        emit(const SavedAddressError('Failed to delete address'));
      }
    } catch (e) {
      debugPrint('Error deleting saved address: $e');
      final errorMessage = _getErrorMessage(e);
      emit(SavedAddressError(errorMessage));
    }
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddress event,
    Emitter<SavedAddressState> emit,
  ) async {
    emit(SavedAddressLoading());
    try {
      final success = await _repository.setAsDefault(event.addressId);

      if (success) {
        // Reload addresses to get updated list
        final addresses = await _repository.getUserSavedAddresses();
        final defaultAddress =
            addresses.where((addr) => addr.isDefault).firstOrNull;

        emit(SavedAddressOperationSuccess(
          message: 'Default address updated',
          addresses: addresses,
          defaultAddress: defaultAddress,
        ));
      } else {
        emit(const SavedAddressError('Failed to set default address'));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting default address: $e');
      }
      final errorMessage = _getErrorMessage(e);
      emit(SavedAddressError(errorMessage));
    }
  }

  /// Convert exceptions to user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is SavedAddressException) {
      switch (error.code) {
        case 'AUTH_ERROR':
          return 'Please sign in to manage your addresses';
        case 'NOT_FOUND':
          return 'Address not found or has been removed';
        case 'DUPLICATE_ADDRESS':
          return 'This address already exists in your saved addresses';
        case 'VALIDATION_ERROR':
          return error.message;
        case 'NETWORK_ERROR':
          return 'Network error. Please check your connection and try again';
        case 'INVALID_USER':
          return 'Invalid user session. Please sign in again';
      }
    }

    if (error is AddressValidationException) {
      return error.message;
    }

    // Fallback for unknown errors
    return 'An unexpected error occurred. Please try again';
  }
}

// Extension for null safety
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
