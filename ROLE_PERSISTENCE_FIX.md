# Role Persistence Fix

## Problem
The profile role switching functionality was not properly connected to the Supabase database logout process. When users logged out, their selected roles were lost because the role switching service's SharedPreferences data was not being cleared, causing inconsistencies between the local cached role and the actual user's roles in the database.

## Root Cause
The issue occurred because:
1. The `RoleSwitchingService` stores the active role in SharedPreferences using the key `'active_role'`
2. When users log out, only the Supabase session was cleared, but the local role data remained
3. Upon re-login, the app would load the cached role from SharedPreferences, but the user's profile data would be reloaded from the database
4. This created a mismatch where the UI showed the old cached role, but the actual user data was fresh from the database

## Solution
Implemented a comprehensive logout cleanup process:

### 1. Added `clearRoleData()` method to `RoleSwitchingService`
```dart
/// Clear all role switching data (for logout)
Future<void> clearRoleData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRoleKey);
    
    // Reset to default state
    _activeRole = 'renter';
    _currentProfile = null;
    _isLoading = false;
    _loadingRole = null;
    
    notifyListeners();
    debugPrint('Role switching data cleared');
  } catch (e) {
    debugPrint('Error clearing role data: $e');
  }
}
```

### 2. Updated `AuthGuardService.clearStoredData()` to include role data cleanup
```dart
// Clear role switching data
try {
  final roleSwitchingService = getIt<RoleSwitchingService>();
  await roleSwitchingService.clearRoleData();
} catch (e) {
  debugPrint('Error clearing role switching data: $e');
}
```

### 3. Modified `AuthBloc._onSignOutRequested()` to call the cleanup
```dart
try {
  await _authRepository.signOut();
  
  // Clear stored data including role switching data
  await AuthGuardService.clearStoredData();
  
  emit(Unauthenticated());
} catch (e) {
  emit(AuthError(e.toString()));
}
```

## Files Modified
1. `/lib/core/services/role_switching_service.dart` - Added `clearRoleData()` method
2. `/lib/core/services/auth_guard_service.dart` - Updated imports and `clearStoredData()` method
3. `/lib/features/auth/presentation/bloc/auth_bloc.dart` - Updated imports and sign out logic

## Testing
To verify the fix:
1. Log in to the app
2. Switch to a different role (e.g., from 'renter' to 'lender')
3. Log out
4. Log back in
5. Verify that the role has been reset to the user's primary role from the database, not the previously cached role

## Benefits
- ✅ Role switching data is now properly synchronized with authentication state
- ✅ No more stale role data after logout/login cycles
- ✅ Consistent user experience across sessions
- ✅ Proper cleanup of all user-specific data on logout
- ✅ Maintains existing role switching functionality while fixing persistence issues

This fix ensures that the role switching functionality is properly integrated with the Supabase database and authentication lifecycle, providing a seamless and consistent user experience.