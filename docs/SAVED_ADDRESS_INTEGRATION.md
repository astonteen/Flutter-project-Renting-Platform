# Saved Address Integration Guide

This document provides a comprehensive guide for the enhanced saved address functionality in the RentEase application, including database integration, error handling, and best practices.

## Overview

The saved address feature allows users to store and manage multiple delivery addresses with the following capabilities:

- ✅ Create, read, update, and delete saved addresses
- ✅ Set default addresses with automatic constraint enforcement
- ✅ Address validation and duplicate prevention
- ✅ Search and filter addresses
- ✅ Bulk operations for multiple addresses
- ✅ Row-level security (RLS) for data protection
- ✅ Comprehensive error handling with user-friendly messages
- ✅ Database triggers for data consistency

## Architecture

### Database Layer

#### Table Structure
```sql
CREATE TABLE saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label VARCHAR(100) NOT NULL,
  address_line_1 VARCHAR(255) NOT NULL,
  address_line_2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Key Features
- **Unique Default Constraint**: Only one default address per user
- **Data Validation**: Check constraints for required fields and length limits
- **Indexes**: Optimized for common query patterns
- **Full-Text Search**: GIN index for address search functionality
- **Row-Level Security**: Users can only access their own addresses
- **Triggers**: Automatic default address management

### Application Layer

#### Repository Pattern
```dart
class SavedAddressRepository {
  // Core CRUD operations
  Future<List<SavedAddressModel>> getUserSavedAddresses();
  Future<SavedAddressModel> createSavedAddress(SavedAddressModel address);
  Future<SavedAddressModel> updateSavedAddress(SavedAddressModel address);
  Future<bool> deleteSavedAddress(String addressId);
  
  // Advanced operations
  Future<List<SavedAddressModel>> searchAddresses(String query);
  Future<int> bulkDeleteAddresses(List<String> addressIds);
  Future<int> getAddressCount();
  
  // Default address management
  Future<SavedAddressModel?> getDefaultAddress();
  Future<bool> setAsDefault(String addressId);
}
```

#### BLoC State Management
```dart
// Events
abstract class SavedAddressEvent {
  LoadSavedAddresses()
  CreateSavedAddress(SavedAddressModel address)
  UpdateSavedAddress(SavedAddressModel address)
  DeleteSavedAddress(String addressId)
  SetDefaultAddress(String addressId)
}

// States
abstract class SavedAddressState {
  SavedAddressInitial()
  SavedAddressLoading()
  SavedAddressLoaded(List<SavedAddressModel> addresses)
  SavedAddressOperationSuccess(String message)
  SavedAddressError(String message)
}
```

## Error Handling

### Custom Exception Types

```dart
// Base exception
class SavedAddressException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

// Specific exceptions
class SavedAddressNotFoundException extends SavedAddressException
class SavedAddressValidationException extends SavedAddressException
class SavedAddressNetworkException extends SavedAddressException
```

### Error Codes and User Messages

| Error Code | User-Friendly Message |
|------------|----------------------|
| `AUTH_ERROR` | "Please sign in to manage your addresses" |
| `NOT_FOUND` | "Address not found or has been removed" |
| `DUPLICATE_ADDRESS` | "This address already exists in your saved addresses" |
| `VALIDATION_ERROR` | Specific validation message |
| `NETWORK_ERROR` | "Network error. Please check your connection and try again" |
| `INVALID_USER` | "Invalid user session. Please sign in again" |

## Usage Examples

### Creating a New Address

```dart
// In your UI component
final address = SavedAddressModel(
  label: 'Home',
  addressLine1: '123 Main Street',
  city: 'New York',
  state: 'NY',
  postalCode: '10001',
  country: 'United States',
  isDefault: true,
);

// Dispatch event to BLoC
context.read<SavedAddressBloc>().add(
  CreateSavedAddress(address),
);
```

### Handling BLoC States

```dart
BlocListener<SavedAddressBloc, SavedAddressState>(
  listener: (context, state) {
    if (state is SavedAddressOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is SavedAddressError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: YourWidget(),
)
```

### Searching Addresses

```dart
// Search by label, address line, or city
final searchResults = await repository.searchAddresses('home');

// The search uses full-text search with the following query:
// label.ilike.%query% OR address_line_1.ilike.%query% OR city.ilike.%query%
```

## Database Migrations

### Initial Table Creation
```bash
# Apply the initial migration
supabase db push
```

### Enhancement Migration
The enhancement migration (`20250101_enhance_saved_addresses_table.sql`) includes:

- Performance indexes
- Data validation constraints
- Default address management triggers
- Row-level security policies
- Full-text search capabilities

## Security Features

### Row-Level Security (RLS)

All saved address operations are protected by RLS policies:

```sql
-- Users can only access their own addresses
CREATE POLICY "Users can view own addresses" ON saved_addresses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own addresses" ON saved_addresses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own addresses" ON saved_addresses
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own addresses" ON saved_addresses
  FOR DELETE USING (auth.uid() = user_id);
```

### Input Validation

- All address fields are validated before database operations
- Duplicate address detection prevents redundant entries
- Address ownership verification for all operations
- SQL injection protection through parameterized queries

## Performance Optimizations

### Database Indexes

```sql
-- User-specific queries
CREATE INDEX idx_saved_addresses_user_id ON saved_addresses(user_id);

-- Default address queries
CREATE INDEX idx_saved_addresses_user_default ON saved_addresses(user_id, is_default) 
WHERE is_default = true;

-- Chronological ordering
CREATE INDEX idx_saved_addresses_created_at ON saved_addresses(created_at DESC);

-- Full-text search
CREATE INDEX idx_saved_addresses_search ON saved_addresses 
USING gin(to_tsvector('english', label || ' ' || address_line_1 || ' ' || city));
```

### Query Optimization

- Efficient pagination support
- Minimal data transfer with selective field queries
- Batch operations for bulk updates/deletes
- Connection pooling through Supabase

## Testing

### Unit Tests

Comprehensive test coverage includes:

- Repository method testing with mocked dependencies
- Error handling verification
- Edge case validation
- BLoC state management testing

### Integration Tests

```dart
// Example integration test
testWidgets('should create and display new address', (tester) async {
  // Setup test environment
  await tester.pumpWidget(MyApp());
  
  // Navigate to add address screen
  await tester.tap(find.byKey(Key('add_address_button')));
  await tester.pumpAndSettle();
  
  // Fill address form
  await tester.enterText(find.byKey(Key('label_field')), 'Test Address');
  await tester.enterText(find.byKey(Key('street_field')), '123 Test St');
  // ... fill other fields
  
  // Submit form
  await tester.tap(find.byKey(Key('save_button')));
  await tester.pumpAndSettle();
  
  // Verify address was created
  expect(find.text('Test Address'), findsOneWidget);
});
```

## Monitoring and Analytics

### Address Statistics View

```sql
CREATE VIEW saved_addresses_stats AS
SELECT 
  user_id,
  COUNT(*) as total_addresses,
  COUNT(*) FILTER (WHERE is_default = true) as default_addresses,
  MIN(created_at) as first_address_created,
  MAX(created_at) as last_address_created,
  COUNT(DISTINCT country) as countries_count,
  COUNT(DISTINCT state) as states_count,
  COUNT(DISTINCT city) as cities_count
FROM saved_addresses
GROUP BY user_id;
```

### Logging and Debugging

- Comprehensive error logging with context
- Performance monitoring for database queries
- User action tracking for analytics
- Debug mode with detailed operation logs

## Best Practices

### Development

1. **Always validate addresses** before database operations
2. **Use dependency injection** for repository instances
3. **Handle all exception types** with appropriate user messages
4. **Test edge cases** including network failures and invalid data
5. **Follow the repository pattern** for data access abstraction

### Database

1. **Use transactions** for operations affecting multiple records
2. **Leverage database constraints** for data integrity
3. **Monitor query performance** and optimize as needed
4. **Regular backup** of address data
5. **Keep migrations** version controlled and documented

### Security

1. **Never expose internal error details** to users
2. **Validate user permissions** for all operations
3. **Use RLS policies** for data access control
4. **Sanitize all inputs** to prevent injection attacks
5. **Audit sensitive operations** for compliance

## Troubleshooting

### Common Issues

#### "User not authenticated" Error
- **Cause**: User session expired or not logged in
- **Solution**: Redirect to login screen and refresh session

#### "Address not found" Error
- **Cause**: Address was deleted or user lacks permission
- **Solution**: Refresh address list and verify user permissions

#### "Duplicate address" Error
- **Cause**: Similar address already exists
- **Solution**: Show existing address and offer to update instead

#### Database Connection Issues
- **Cause**: Network problems or Supabase service issues
- **Solution**: Implement retry logic and offline support

### Debug Mode

```dart
// Enable debug logging
const bool kDebugMode = true;

if (kDebugMode) {
  debugPrint('SavedAddressRepository: Creating address with data: $addressData');
}
```

## Future Enhancements

### Planned Features

1. **Address Validation Service**: Integration with postal service APIs
2. **Geolocation Support**: Automatic address detection from coordinates
3. **Address Sharing**: Allow users to share addresses with family/friends
4. **Import/Export**: Bulk address management capabilities
5. **Address History**: Track address changes over time
6. **Smart Suggestions**: ML-powered address completion

### Performance Improvements

1. **Caching Layer**: Redis cache for frequently accessed addresses
2. **Offline Support**: Local storage with sync capabilities
3. **Lazy Loading**: Pagination for large address lists
4. **Background Sync**: Automatic data synchronization

## Conclusion

The enhanced saved address functionality provides a robust, secure, and user-friendly way to manage delivery addresses in the RentEase application. With comprehensive error handling, performance optimizations, and security features, it's ready for production use and can scale with the application's growth.

For additional support or questions, please refer to the codebase documentation or contact the development team.