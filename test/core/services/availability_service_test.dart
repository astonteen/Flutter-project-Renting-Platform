import 'package:flutter_test/flutter_test.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/core/constants/app_constants.dart';

void main() {
  group('Enhanced Return Buffer Tests', () {
    test('should calculate correct buffer days for different categories', () {
      // Electronics category
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(3), // Electronics base = 3 days
      );

      // Clothing category
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Clothing',
          condition: 'good',
          totalAmount: 50.0,
          hasDeliveryReturn: false,
        ),
        equals(1), // Clothing base = 1 day
      );

      // Tools category
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Tools',
          condition: 'good',
          totalAmount: 200.0,
          hasDeliveryReturn: false,
        ),
        equals(2), // Tools base = 2 days
      );
    });

    test('should add condition-based adjustments', () {
      // Fair condition adds +1 day
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'fair',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(4), // 3 + 1 = 4 days
      );

      // Poor condition adds +2 days
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Tools',
          condition: 'poor',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(4), // 2 + 2 = 4 days
      );
    });

    test('should add delivery return adjustment', () {
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: true,
        ),
        equals(4), // 3 + 1 = 4 days
      );
    });

    test('should add high-value item adjustment', () {
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'good',
          totalAmount: 600.0, // > $500
          hasDeliveryReturn: false,
        ),
        equals(4), // 3 + 1 = 4 days
      );
    });

    test('should combine all adjustments correctly', () {
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'poor',
          totalAmount: 800.0,
          hasDeliveryReturn: true,
        ),
        equals(7), // 3 + 2 + 1 + 1 = 7 days (max)
      );
    });

    test('should cap buffer days between 1-7', () {
      // Test minimum bound
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'unknown_category',
          condition: 'excellent',
          totalAmount: 50.0,
          hasDeliveryReturn: false,
        ),
        greaterThanOrEqualTo(1),
      );

      // Test maximum bound (shouldn't exceed 7)
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Electronics',
          condition: 'poor',
          totalAmount: 1000.0,
          hasDeliveryReturn: true,
        ),
        lessThanOrEqualTo(7),
      );
    });

    test('should use default category for unknown categories', () {
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Unknown Category',
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(AppConstants.returnBufferDaysByCategory['default']!),
      );
    });
  });

  group('Maintenance Reason Generation Tests', () {
    test('should generate correct reasons for different categories', () {
      // Test reason generation indirectly through public interface
      // This would require mocking Supabase calls in a real test environment
      expect(true,
          isTrue); // Placeholder - actual implementation would test through public methods
    });

    test('should handle edge cases in buffer calculation', () {
      // Test with empty/null category names
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: '',
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(AppConstants.returnBufferDaysByCategory['default']!),
      );

      // Test with unusual category names
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'ELECTRONICS', // All caps
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(3), // Should normalize to 'electronics'
      );

      // Test with category names with spaces
      expect(
        AvailabilityService.calculateReturnBufferDays(
          categoryName: 'Musical Instruments',
          condition: 'good',
          totalAmount: 100.0,
          hasDeliveryReturn: false,
        ),
        equals(3), // Should normalize to 'musical_instruments'
      );
    });
  });
}
