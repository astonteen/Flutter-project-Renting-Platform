class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final priceRegExp = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!priceRegExp.hasMatch(value)) {
      return 'Please enter a valid price';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Price must be greater than zero';
    }

    return null;
  }

  // Enhanced validators with better UX
  static String? validateEmailWithSuggestions(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      // Check for common typos
      if (value.contains('@') && !value.contains('.')) {
        return 'Did you mean ${value.split('@')[0]}@gmail.com?';
      }
      if (value.contains('gmail') && !value.contains('@gmail.com')) {
        return 'Did you mean ${value.split('@')[0]}@gmail.com?';
      }
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePasswordWithStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    int strength = 0;
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasNumbers = value.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;

    if (strength < 2) {
      return 'Password is too weak. Add uppercase, numbers, or special characters';
    }

    return null;
  }

  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(' ', '');
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Please enter a valid card number';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cardNumber)) {
      return 'Card number should only contain digits';
    }

    // Luhn algorithm check for demo purposes
    if (!_isValidLuhn(cardNumber)) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Please enter date in MM/YY format';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Please enter a valid month (01-12)';
    }

    if (year == null) {
      return 'Please enter a valid year';
    }

    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }

    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'Please enter a valid CVV (3-4 digits)';
    }

    return null;
  }

  static String? validateDescription(String? value, {int minLength = 20}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length < minLength) {
      return 'Description must be at least $minLength characters (${value.length}/$minLength)';
    }

    if (value.length > 1000) {
      return 'Description must be less than 1000 characters';
    }

    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location is required';
    }

    if (value.length < 3) {
      return 'Please enter a valid location';
    }

    return null;
  }

  static String? validateSecurityDeposit(String? value, double itemPrice) {
    if (value == null || value.isEmpty) {
      return 'Security deposit is required';
    }

    final deposit = double.tryParse(value);
    if (deposit == null || deposit < 0) {
      return 'Please enter a valid amount';
    }

    if (deposit > itemPrice * 2) {
      return 'Security deposit seems too high (max 2x item price)';
    }

    return null;
  }

  // Helper method for Luhn algorithm (for demo card validation)
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Real-time validation helpers
  static ValidationResult validateEmailRealTime(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult(isValid: false, message: null);
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (emailRegExp.hasMatch(value)) {
      return ValidationResult(isValid: true, message: 'Valid email address');
    }

    if (value.contains('@')) {
      return ValidationResult(isValid: false, message: 'Almost there...');
    }

    return ValidationResult(isValid: false, message: null);
  }

  static ValidationResult validatePasswordRealTime(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult(isValid: false, message: null);
    }

    int strength = 0;
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasNumbers = value.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;

    if (value.length < 8) {
      return ValidationResult(
        isValid: false,
        message: 'Password must be at least 8 characters',
      );
    }

    switch (strength) {
      case 0:
      case 1:
        return ValidationResult(
          isValid: false,
          message: 'Weak password',
          strength: PasswordStrength.weak,
        );
      case 2:
        return ValidationResult(
          isValid: true,
          message: 'Fair password',
          strength: PasswordStrength.fair,
        );
      case 3:
        return ValidationResult(
          isValid: true,
          message: 'Good password',
          strength: PasswordStrength.good,
        );
      case 4:
        return ValidationResult(
          isValid: true,
          message: 'Strong password',
          strength: PasswordStrength.strong,
        );
      default:
        return ValidationResult(
          isValid: false,
          message: 'Invalid password',
        );
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String? message;
  final PasswordStrength? strength;

  ValidationResult({
    required this.isValid,
    this.message,
    this.strength,
  });
}

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}
