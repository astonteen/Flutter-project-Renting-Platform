# Calendar Refactoring Guide

## Overview

The `enhanced_lender_calendar_screen.dart` has been completely refactored to address multiple architectural and performance issues. This guide explains the changes and how to integrate the new implementation.

## Major Changes

### 1. Architecture Separation

**Before**: Monolithic widget with ~1,300 LOC containing UI, business logic, caching, and API calls.

**After**: Clean separation of concerns:
- `CalendarAvailabilityBloc`: Handles all business logic and state management
- `RefactoredLenderCalendarScreen`: Pure UI orchestration
- Extracted components: `CalendarHeaderWidget`, `CalendarGridWidget`
- Utility classes: `DateUtils`, `CalendarConstants`

### 2. Fixed Caching Issues

**Problem**: `AsyncMemoizer` reused for different cache keys caused data corruption.

**Solution**: Proper per-key caching in the BLoC with cache invalidation strategies.

### 3. Enhanced Type Safety

**Before**: Dynamic data with runtime errors and type casting issues.

**After**: Strongly typed models:
- `ItemAvailability` with Equatable
- `AvailabilityBlock` with proper validation
- Type-safe state management

### 4. Performance Optimizations

**Before**: Frequent full widget rebuilds and setState calls.

**After**: 
- Granular rebuilds through BLoC selectors
- Efficient calendar grid rendering
- Optimized date calculations with `DateUtils`

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── calendar_constants.dart          # UI constants and themes
│   └── utils/
│       └── date_utils.dart                  # Date manipulation utilities
├── features/
│   └── listing/
│       └── presentation/
│           ├── bloc/
│           │   └── calendar_availability_bloc.dart  # State management
│           ├── screens/
│           │   ├── enhanced_lender_calendar_screen.dart     # Original (deprecated)
│           │   └── refactored_lender_calendar_screen.dart   # New implementation
│           └── widgets/
│               ├── calendar_header_widget.dart     # Header component
│               └── calendar_grid_widget.dart       # Calendar grid component
```

## Integration Steps

### Step 1: Add Dependencies

Ensure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  equatable: ^2.0.5
  flutter_bloc: ^8.1.3
  intl: ^0.18.1
```

### Step 2: Register the BLoC

Add the new BLoC to your app's BLoC providers:

```dart
// In your main.dart or app setup
MultiBlocProvider(
  providers: [
    // ... existing providers
    BlocProvider<CalendarAvailabilityBloc>(
      create: (context) => CalendarAvailabilityBloc(),
    ),
  ],
  child: YourApp(),
)
```

### Step 3: Update Navigation

Replace references to the old calendar screen:

```dart
// Before
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EnhancedLenderCalendarScreen(),
  ),
);

// After
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RefactoredLenderCalendarScreen(),
  ),
);
```

### Step 4: Update Service Locator (if used)

If using dependency injection, register the new BLoC:

```dart
// In service_locator.dart
void setupLocator() {
  // ... existing registrations
  locator.registerFactory<CalendarAvailabilityBloc>(
    () => CalendarAvailabilityBloc(),
  );
}
```

## API Compatibility

The refactored implementation maintains compatibility with existing `AvailabilityService` methods:

- `getItemAvailabilityRange()`
- `createManualBlock()`
- `removeManualBlock()`

No backend changes are required.

## Migration Notes

### Date Handling Fix

**Issue**: The original code used `DateTime.now().copyWith(...)` which requires a custom extension.

**Fix**: Replaced with `DateUtils.normalizeDate()` and standard DateTime constructors.

```dart
// Before (problematic)
final today = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

// After (reliable)
final today = DateUtils.today;
```

### Error Handling Improvements

**Before**: Silent failures with console logging.
```dart
} catch (e) {
  print('Error: $e'); // Lost in logs
}
```

**After**: User-visible error states.
```dart
// Errors bubble up through BLoC states
emit(CalendarAvailabilityError(message: 'Failed to load availability: $e'));
```

### State Management

**Before**: Manual state synchronization with setState.
```dart
setState(() {
  _availabilityMap = newData;
  _allBookings = bookings;
});
```

**After**: Reactive state updates through BLoC.
```dart
context.read<CalendarAvailabilityBloc>().add(
  LoadCalendarAvailability(listingId: id, month: month),
);
```

## Testing Strategy

### Unit Tests for BLoC

```dart
group('CalendarAvailabilityBloc', () {
  blocTest<CalendarAvailabilityBloc, CalendarAvailabilityState>(
    'emits loaded state when LoadCalendarAvailability succeeds',
    build: () => CalendarAvailabilityBloc(),
    act: (bloc) => bloc.add(
      LoadCalendarAvailability(listingId: 'test', month: DateTime.now()),
    ),
    expect: () => [
      CalendarAvailabilityLoading(),
      isA<CalendarAvailabilityLoaded>(),
    ],
  );
});
```

### Widget Tests for Components

```dart
testWidgets('CalendarGridWidget displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarGridWidget(
        focusedDate: DateTime.now(),
        selectedDate: DateTime.now(),
        availabilityMap: {},
        onDateSelected: (_) {},
        onDateLongPressed: (_) {},
        onPreviousMonth: () {},
        onNextMonth: () {},
      ),
    ),
  );
  
  expect(find.byType(CalendarGridWidget), findsOneWidget);
});
```

## Performance Improvements

### Before Refactoring
- Full widget rebuilds on every interaction
- Expensive availability calculations in UI thread
- Memory leaks from unclosed animation controllers
- Blocking main thread during month navigation

### After Refactoring
- Granular rebuilds only for affected components
- Background availability loading with caching
- Proper resource management
- Smooth animations with optimized calendar grid

## Accessibility Enhancements

The new implementation includes:
- Semantic labels for calendar days
- Improved focus management
- Better screen reader support
- High contrast support through theme constants

## Configuration

### Calendar Constants

Customize the calendar appearance through `CalendarConstants`:

```dart
class CalendarConstants {
  // Modify these to match your design system
  static const Color primaryColor = ColorConstants.primaryColor;
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const double calendarDayHeight = 48.0;
  // ... other constants
}
```

### Date Utilities

Extend `DateUtils` for app-specific date operations:

```dart
extension AppDateUtils on DateUtils {
  static String formatForDisplay(DateTime date) {
    // Your custom formatting logic
  }
}
```

## Rollback Plan

If issues arise, you can quickly rollback:

1. Revert navigation changes to use `EnhancedLenderCalendarScreen`
2. Remove the new BLoC provider registration
3. Keep the new utility classes as they're beneficial

The original file remains available during the transition period.

## Future Enhancements

The new architecture enables:

1. **Multi-property calendar view**: Easy to extend the BLoC for multiple listings
2. **Real-time updates**: WebSocket integration through the BLoC
3. **Offline support**: Cache persistence with the existing cache structure
4. **Advanced filtering**: Filter bookings by status, customer, etc.
5. **Calendar export**: Generate iCal files from the structured data

## Troubleshooting

### Common Issues

**Issue**: BLoC not found error
```
Error: Could not find the correct Provider<CalendarAvailabilityBloc>
```
**Solution**: Ensure the BLoC is registered in the widget tree above the calendar screen.

**Issue**: Date normalization problems
```
Error: DateTime comparison issues
```
**Solution**: Always use `DateUtils.normalizeDate()` for date keys in maps.

**Issue**: Cache not updating
```
Error: Stale data displayed after changes
```
**Solution**: Check that cache invalidation is called after mutations.

## Support

For issues related to the refactored calendar:
1. Check this guide first
2. Review the BLoC state transitions
3. Verify proper BLoC registration
4. Test with the provided unit tests

The refactored implementation is production-ready and provides a solid foundation for future calendar-related features. 