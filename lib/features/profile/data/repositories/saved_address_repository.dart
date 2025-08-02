import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';

/// Custom exceptions for saved address operations
class SavedAddressException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const SavedAddressException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'SavedAddressException: $message';
}

class SavedAddressNotFoundException extends SavedAddressException {
  const SavedAddressNotFoundException(String message)
      : super(message, code: 'NOT_FOUND');
}

class SavedAddressValidationException extends SavedAddressException {
  const SavedAddressValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR');
}

class SavedAddressNetworkException extends SavedAddressException {
  const SavedAddressNetworkException(String message, {dynamic originalError})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError);
}

class SavedAddressRepository {
  /// Validates user authentication
  String _validateUserAuth() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw const SavedAddressException('User not authenticated',
          code: 'AUTH_ERROR');
    }
    return userId;
  }

  /// Handle and convert errors to appropriate exceptions
  Never _handleError(dynamic error, String operation) {
    if (kDebugMode) {
      debugPrint('SavedAddressRepository error in $operation: $error');
    }

    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique constraint violation
          throw const SavedAddressException(
              'An address with this information already exists',
              code: 'DUPLICATE_ADDRESS');
        case '23503': // Foreign key constraint violation
          throw const SavedAddressException('Invalid user reference',
              code: 'INVALID_USER');
        case 'PGRST116': // No rows returned
          throw const SavedAddressNotFoundException('Address not found');
        case 'PGRST301': // Row level security violation
          throw const SavedAddressException(
              'You do not have permission to access this address',
              code: 'PERMISSION_DENIED');
        default:
          throw SavedAddressException('Database error: ${error.message}',
              code: error.code, originalError: error);
      }
    }

    if (error is AuthException) {
      throw SavedAddressException('Please sign in to manage your addresses',
          code: 'AUTH_ERROR', originalError: error);
    }

    // Network or other errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('connection')) {
      throw SavedAddressNetworkException(
          'Unable to connect to the server. Please check your internet connection and try again.',
          originalError: error);
    }

    // Fallback for unknown errors
    throw SavedAddressNetworkException(
        'An unexpected error occurred while trying to $operation. Please try again.',
        originalError: error);
  }

  // Get all saved addresses for current user
  Future<List<SavedAddressModel>> getUserSavedAddresses() async {
    try {
      final userId = _validateUserAuth();

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) =>
              SavedAddressModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'fetch saved addresses');
    }
  }

  // Get default address for current user
  Future<SavedAddressModel?> getDefaultAddress() async {
    try {
      final userId = _validateUserAuth();

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('*')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return SavedAddressModel.fromJson(response);
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'fetch default address');
    }
  }

  // Create new saved address
  Future<SavedAddressModel> createSavedAddress(
      SavedAddressModel address) async {
    try {
      final userId = _validateUserAuth();

      // Validate address before creating
      address.validateAddress();

      // Check for duplicate addresses
      await _checkForDuplicateAddress(address, userId);

      final addressData = address.toCreateJson();
      addressData['user_id'] = userId;

      final response = await SupabaseService.client
          .from('saved_addresses')
          .insert(addressData)
          .select()
          .single();

      return SavedAddressModel.fromJson(response);
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'create saved address');
    }
  }

  /// Check for duplicate addresses to prevent redundant entries
  Future<void> _checkForDuplicateAddress(
      SavedAddressModel address, String userId) async {
    try {
      final existingAddresses = await SupabaseService.client
          .from('saved_addresses')
          .select('id, address_line_1, city, state, postal_code')
          .eq('user_id', userId)
          .eq('address_line_1', address.addressLine1.trim())
          .eq('city', address.city.trim())
          .eq('state', address.state.trim())
          .eq('postal_code', address.postalCode.trim());

      if ((existingAddresses as List).isNotEmpty) {
        throw const SavedAddressException(
            'An address with the same details already exists',
            code: 'DUPLICATE_ADDRESS');
      }
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      // If we can't check for duplicates, log but don't fail the operation
      if (kDebugMode) {
        debugPrint('Warning: Could not check for duplicate addresses: $e');
      }
    }
  }

  // Update existing saved address
  Future<SavedAddressModel> updateSavedAddress(
      SavedAddressModel address) async {
    try {
      final userId = _validateUserAuth();

      // Validate address before updating
      address.validateAddress();

      // Verify the address belongs to the current user
      await _verifyAddressOwnership(address.id, userId);

      final response = await SupabaseService.client
          .from('saved_addresses')
          .update(address.toUpdateJson())
          .eq('id', address.id)
          .eq('user_id', userId) // Additional security check
          .select()
          .single();

      return SavedAddressModel.fromJson(response);
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'update saved address');
    }
  }

  /// Verify that the address belongs to the current user
  Future<void> _verifyAddressOwnership(String addressId, String userId) async {
    try {
      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('id')
          .eq('id', addressId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw const SavedAddressNotFoundException(
            'Address not found or you do not have permission to modify it');
      }
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'verify address ownership');
    }
  }

  // Delete saved address
  Future<bool> deleteSavedAddress(String addressId) async {
    try {
      final userId = _validateUserAuth();

      // Verify the address belongs to the current user
      await _verifyAddressOwnership(addressId, userId);

      final response = await SupabaseService.client
          .from('saved_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId) // Additional security check
          .select('id');

      // Check if any rows were actually deleted
      if ((response as List).isEmpty) {
        throw const SavedAddressNotFoundException(
            'Address not found or already deleted');
      }

      return true;
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'delete saved address');
    }
  }

  // Set address as default
  Future<bool> setAsDefault(String addressId) async {
    try {
      final userId = _validateUserAuth();

      // Verify the address belongs to the current user
      await _verifyAddressOwnership(addressId, userId);

      // Use a transaction-like approach to ensure consistency
      // First, unset all other addresses as default
      await SupabaseService.client.from('saved_addresses').update({
        'is_default': false,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('user_id', userId);

      // Then set the selected address as default
      final response = await SupabaseService.client
          .from('saved_addresses')
          .update({
            'is_default': true,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', addressId)
          .eq('user_id', userId)
          .select('id');

      // Verify the update was successful
      if ((response as List).isEmpty) {
        throw const SavedAddressNotFoundException(
            'Address not found or could not be set as default');
      }

      return true;
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'set default address');
    }
  }

  // Get address by ID
  Future<SavedAddressModel?> getAddressById(String addressId) async {
    try {
      final userId = _validateUserAuth();

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('*')
          .eq('id', addressId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return SavedAddressModel.fromJson(response);
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'fetch address by ID');
    }
  }

  // Check if user has any saved addresses
  Future<bool> hasAnyAddresses() async {
    try {
      final userId = _validateUserAuth();

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'check for saved addresses');
    }
  }

  /// Get addresses count for the current user
  Future<int> getAddressCount() async {
    try {
      final userId = _validateUserAuth();

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'get address count');
    }
  }

  /// Search addresses by query (address line, city, or label)
  Future<List<SavedAddressModel>> searchAddresses(String query) async {
    try {
      final userId = _validateUserAuth();

      if (query.trim().isEmpty) {
        return getUserSavedAddresses();
      }

      final searchQuery = '%${query.trim().toLowerCase()}%';

      final response = await SupabaseService.client
          .from('saved_addresses')
          .select('*')
          .eq('user_id', userId)
          .or('label.ilike.$searchQuery,address_line_1.ilike.$searchQuery,city.ilike.$searchQuery')
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) =>
              SavedAddressModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'search addresses');
    }
  }

  /// Bulk delete multiple addresses
  Future<int> bulkDeleteAddresses(List<String> addressIds) async {
    try {
      final userId = _validateUserAuth();

      if (addressIds.isEmpty) return 0;

      // Verify all addresses belong to the current user
      for (final addressId in addressIds) {
        await _verifyAddressOwnership(addressId, userId);
      }

      final response = await SupabaseService.client
          .from('saved_addresses')
          .delete()
          .inFilter('id', addressIds)
          .eq('user_id', userId)
          .select('id');

      return (response as List).length;
    } catch (e) {
      if (e is SavedAddressException) rethrow;
      _handleError(e, 'bulk delete addresses');
    }
  }
}
