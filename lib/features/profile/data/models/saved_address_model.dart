import 'package:equatable/equatable.dart';

/// Custom exception for address validation errors
class AddressValidationException implements Exception {
  final String message;
  final List<String> errors;

  const AddressValidationException(this.message, this.errors);

  @override
  String toString() => 'AddressValidationException: $message';
}

/// Model representing a saved address with validation and error handling
class SavedAddressModel extends Equatable {
  final String id;
  final String userId;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedAddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    try {
      return SavedAddressModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        addressLine1: json['address_line_1']?.toString() ?? '',
        addressLine2: json['address_line_2']?.toString(),
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        postalCode: json['postal_code']?.toString() ?? '',
        country: json['country']?.toString() ?? 'US',
        isDefault: json['is_default'] == true,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Failed to parse SavedAddressModel from JSON: $e');
    }
  }

  /// Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SavedAddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedAddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        isDefault,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'SavedAddressModel(id: $id, label: $label, address: $fullAddress)';
  }

  // Validation methods

  /// Validates the address and returns true if all required fields are valid
  bool get isValid {
    try {
      validateAddress();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns a list of validation errors for the address
  List<String> get validationErrors {
    final errors = <String>[];

    if (label.trim().isEmpty) {
      errors.add('Address label is required');
    }

    if (addressLine1.trim().isEmpty) {
      errors.add('Street address is required');
    }

    if (city.trim().isEmpty) {
      errors.add('City is required');
    }

    if (state.trim().isEmpty) {
      errors.add('State is required');
    }

    if (postalCode.trim().isEmpty) {
      errors.add('Postal code is required');
    }

    if (country.trim().isEmpty) {
      errors.add('Country is required');
    }

    // Validate postal code format (basic validation)
    if (postalCode.isNotEmpty && !_isValidPostalCode(postalCode, country)) {
      errors.add('Invalid postal code format');
    }

    return errors;
  }

  /// Validates the address and throws an exception if invalid
  void validateAddress() {
    final errors = validationErrors;
    if (errors.isNotEmpty) {
      throw AddressValidationException(
        'Address validation failed',
        errors,
      );
    }
  }

  /// Basic postal code validation
  bool _isValidPostalCode(String postalCode, String country) {
    final cleanCode = postalCode.replaceAll(RegExp(r'\s+'), '');

    switch (country.toUpperCase()) {
      case 'US':
        return RegExp(r'^\d{5}(-\d{4})?$').hasMatch(cleanCode);
      case 'CA':
        return RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$')
            .hasMatch(cleanCode.toUpperCase());
      case 'GB':
      case 'UK':
        return RegExp(r'^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$')
            .hasMatch(cleanCode.toUpperCase());
      default:
        return cleanCode.isNotEmpty && cleanCode.length >= 3;
    }
  }

  // Helper getters
  String get fullAddress {
    final parts = <String>[
      addressLine1.trim(),
      if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
        addressLine2!.trim(),
      city.trim(),
      state.trim(),
      postalCode.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String get shortAddress {
    final parts = [addressLine1.trim(), city.trim(), state.trim()]
        .where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String get displayLabel {
    return label.trim().isNotEmpty ? label.trim() : 'Address';
  }

  /// Returns a formatted address suitable for display
  String get formattedAddress {
    final buffer = StringBuffer();

    if (addressLine1.trim().isNotEmpty) {
      buffer.writeln(addressLine1.trim());
    }

    if (addressLine2 != null && addressLine2!.trim().isNotEmpty) {
      buffer.writeln(addressLine2!.trim());
    }

    final cityStateZip = [city.trim(), state.trim(), postalCode.trim()]
        .where((part) => part.isNotEmpty)
        .join(', ');

    if (cityStateZip.isNotEmpty) {
      buffer.writeln(cityStateZip);
    }

    if (country.trim().isNotEmpty && country.trim().toUpperCase() != 'US') {
      buffer.writeln(country.trim());
    }

    return buffer.toString().trim();
  }

  // For creating new address (without ID)
  Map<String, dynamic> toCreateJson() {
    // Validate before creating
    validateAddress();

    return {
      'user_id': userId.trim(),
      'label': label.trim(),
      'address_line_1': addressLine1.trim(),
      'address_line_2': addressLine2?.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'postal_code': postalCode.trim(),
      'country': country.trim(),
      'is_default': isDefault,
    };
  }

  // For updating existing address
  Map<String, dynamic> toUpdateJson() {
    // Validate before updating
    validateAddress();

    return {
      'label': label.trim(),
      'address_line_1': addressLine1.trim(),
      'address_line_2': addressLine2?.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'postal_code': postalCode.trim(),
      'country': country.trim(),
      'is_default': isDefault,
    };
  }

  /// Creates a copy of this address with validation
  SavedAddressModel copyWithValidation({
    String? id,
    String? userId,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newAddress = copyWith(
      id: id,
      userId: userId,
      label: label,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    // Validate the new address
    newAddress.validateAddress();

    return newAddress;
  }

  /// Checks if this address is similar to another address
  bool isSimilarTo(SavedAddressModel other) {
    return addressLine1.trim().toLowerCase() ==
            other.addressLine1.trim().toLowerCase() &&
        city.trim().toLowerCase() == other.city.trim().toLowerCase() &&
        state.trim().toLowerCase() == other.state.trim().toLowerCase() &&
        postalCode.trim() == other.postalCode.trim();
  }
}
