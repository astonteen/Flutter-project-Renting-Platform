import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/profile/data/repositories/profile_repository.dart';

@singleton
class RoleSwitchingService extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  static const String _activeRoleKey = 'active_role';

  String _activeRole = 'renter'; // Default role
  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _loadingRole;

  RoleSwitchingService(this._profileRepository) {
    _loadActiveRole();
    _loadCurrentProfile();
  }

  /// Refresh profile data (called after login)
  Future<void> refreshProfile() async {
    debugPrint('Refreshing profile data after login');
    await _loadCurrentProfile();
  }

  String get activeRole => _activeRole;
  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get loadingRole => _loadingRole;

  Future<void> _loadCurrentProfile() async {
    try {
      _currentProfile = await _profileRepository.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current profile: $e');
    }
  }

  List<String> get availableRoles {
    if (_currentProfile == null) return ['renter'];
    // Use the user's actual roles, fallback to just their primary role or default roles
    final userRoles = _currentProfile!.roles;
    if (userRoles != null && userRoles.isNotEmpty) {
      // Map database roles to display roles
      return userRoles.map((role) {
        if (role == 'owner') return 'lender';
        return role;
      }).toList();
    }
    // If no roles set, return primary role or default
    if (_currentProfile!.primaryRole != null) {
      return [_currentProfile!.primaryRole!];
    }
    return ['renter'];
  }

  /// Add a new role to the user's profile
  Future<bool> addRole(String role) async {
    try {
      if (_currentProfile == null) {
        await _loadCurrentProfile();
        if (_currentProfile == null) return false;
      }

      // Map display role to database role
      String dbRole = role == 'lender' ? 'owner' : role;

      List<String> currentRoles =
          List.from(_currentProfile!.roles ?? ['renter']);

      if (!currentRoles.contains(dbRole)) {
        currentRoles.add(dbRole);

        final updatedProfile = _currentProfile!.copyWith(roles: currentRoles);
        final result = await _profileRepository.updateProfile(updatedProfile);

        _currentProfile = result;
        notifyListeners();
        return true;
      }
      return false; // Role already exists
    } catch (e) {
      debugPrint('Error adding role: $e');
      return false;
    }
  }

  /// Check if user has a specific role
  bool hasRole(String role) {
    if (_currentProfile?.roles == null) return false;

    // Map display role to database role for checking
    String dbRole = role == 'lender' ? 'owner' : role;
    return _currentProfile!.roles!.contains(dbRole);
  }

  bool get canSwitchRoles => availableRoles.length > 1;

  Future<void> _loadActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_activeRoleKey);
      if (savedRole != null && savedRole.isNotEmpty) {
        _activeRole = savedRole;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active role: $e');
    }
  }

  Future<void> switchRole(String newRole) async {
    if (_isLoading || newRole == _activeRole) return;

    _isLoading = true;
    _loadingRole = newRole;
    notifyListeners();

    try {
      // Simulate loading time for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      _activeRole = newRole;
      await _saveActiveRole();

      _isLoading = false;
      _loadingRole = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _loadingRole = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeRoleKey, _activeRole);
    } catch (e) {
      debugPrint('Error saving active role: $e');
    }
  }

  void updateProfile(ProfileModel? profile) {
    _currentProfile = profile;

    // If the current active role is not available in the new profile,
    // switch to the primary role or first available role
    if (profile != null) {
      final available = availableRoles;
      if (!available.contains(_activeRole)) {
        final newRole = profile.primaryRole ?? available.first;
        switchRole(newRole);
      }
    } else {
      // No profile, default to renter
      if (_activeRole != 'renter') {
        switchRole('renter');
      }
    }

    notifyListeners();
  }

  String getRoleDisplayName(String role) {
    switch (role) {
      case 'renter':
        return 'Renter';
      case 'lender':
        return 'Lender';
      case 'driver':
        return 'Driver';
      default:
        return 'User';
    }
  }

  bool isRoleActive(String role) => _activeRole == role;

  bool get isRenter => _activeRole == 'renter';
  bool get isLender => _activeRole == 'lender';
  bool get isDriver => _activeRole == 'driver';

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
}
