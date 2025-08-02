import 'package:flutter/foundation.dart';
import 'package:rent_ease/core/config/environment_config.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Try to create user profile, but don't fail if RLS blocks it
        // The trigger function should handle this automatically
        try {
          await SupabaseService.client.from('profiles').insert({
            'id': response.user!.id,
            'full_name': fullName,
            'email': email,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          });
          debugPrint('Profile created successfully');
        } catch (profileError) {
          debugPrint(
              'Profile creation handled by trigger or RLS: $profileError');
          // Don't throw error here - the user is still created successfully
          // The profile will be created by the database trigger
        }
      }

      return response;
    } catch (e) {
      debugPrint('Error in signUp: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error in signIn: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      debugPrint('Error in signOut: $e');
      rethrow;
    }
  }

  Future<void> updateUserRoles({
    required List<String> roles,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'roles': roles}).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error in updateUserRoles: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String location,
    required String bio,
    required String primaryRole,
    required bool enableNotifications,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client.from('profiles').update({
          'location': location,
          'bio': bio.isNotEmpty ? bio : null,
          'primary_role': primaryRole,
          'enable_notifications': enableNotifications,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error in updateProfile: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: EnvironmentConfig.authPasswordResetRedirect,
      );
    } catch (e) {
      debugPrint('Error in resetPassword: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint('Error in changePassword: $e');
      rethrow;
    }
  }

  User? get currentUser => SupabaseService.currentUser;

  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;
}
