class AddressUtils {
  /// Format a complete address from saved_addresses table data
  static String formatSavedAddress(Map<String, dynamic> addressData) {
    final List<String> addressParts = [];

    // Add address line 1
    if (addressData['address_line_1'] != null &&
        (addressData['address_line_1'] as String).isNotEmpty) {
      addressParts.add(addressData['address_line_1']);
    }

    // Add address line 2 if present
    if (addressData['address_line_2'] != null &&
        (addressData['address_line_2'] as String).isNotEmpty) {
      addressParts.add(addressData['address_line_2']);
    }

    // Combine city, state, and postal code
    final cityStatePostal = [
      addressData['city'],
      addressData['state'],
      addressData['postal_code']
    ].where((part) => part != null && part.toString().isNotEmpty).join(', ');

    if (cityStatePostal.isNotEmpty) {
      addressParts.add(cityStatePostal);
    }

    // Add country
    if (addressData['country'] != null &&
        (addressData['country'] as String).isNotEmpty) {
      addressParts.add(addressData['country']);
    }

    return addressParts.join('\n');
  }

  /// Format address for single line display
  static String formatSavedAddressSingleLine(Map<String, dynamic> addressData) {
    final List<String> addressParts = [];

    // Add address line 1
    if (addressData['address_line_1'] != null &&
        (addressData['address_line_1'] as String).isNotEmpty) {
      addressParts.add(addressData['address_line_1']);
    }

    // Add address line 2 if present
    if (addressData['address_line_2'] != null &&
        (addressData['address_line_2'] as String).isNotEmpty) {
      addressParts.add(addressData['address_line_2']);
    }

    // Add city
    if (addressData['city'] != null &&
        (addressData['city'] as String).isNotEmpty) {
      addressParts.add(addressData['city']);
    }

    // Add state and postal code
    final statePostal = [addressData['state'], addressData['postal_code']]
        .where((part) => part != null && part.toString().isNotEmpty)
        .join(' ');

    if (statePostal.isNotEmpty) {
      addressParts.add(statePostal);
    }

    // Add country
    if (addressData['country'] != null &&
        (addressData['country'] as String).isNotEmpty) {
      addressParts.add(addressData['country']);
    }

    return addressParts.join(', ');
  }

  /// Check if address data is complete
  static bool isAddressComplete(Map<String, dynamic> addressData) {
    final requiredFields = ['address_line_1', 'city', 'state', 'country'];
    return requiredFields.every((field) =>
        addressData.containsKey(field) &&
        addressData[field] != null &&
        (addressData[field] as String).isNotEmpty);
  }
}
