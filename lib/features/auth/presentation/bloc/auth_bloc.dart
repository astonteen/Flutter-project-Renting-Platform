import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/auth/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, fullName, phoneNumber];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class UpdateUserRolesRequested extends AuthEvent {
  final List<String> roles;

  const UpdateUserRolesRequested({required this.roles});

  @override
  List<Object?> get props => [roles];
}

class CompleteProfileSetupEvent extends AuthEvent {
  final String location;
  final String bio;
  final String selectedRole;
  final bool enableNotifications;

  const CompleteProfileSetupEvent({
    required this.location,
    required this.bio,
    required this.selectedRole,
    required this.enableNotifications,
  });

  @override
  List<Object?> get props => [location, bio, selectedRole, enableNotifications];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordSubmitted extends AuthEvent {
  final String newPassword;

  const ResetPasswordSubmitted({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String newPassword;

  const ChangePasswordRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordResetError extends AuthState {
  final String message;

  const PasswordResetError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordRecoveryInProgress extends AuthState {}

class PasswordUpdateSuccess extends AuthState {}

class PasswordUpdateError extends AuthState {
  final String message;

  const PasswordUpdateError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordChangeInProgress extends AuthState {}

class PasswordChangeSuccess extends AuthState {}

class PasswordChangeError extends AuthState {
  final String message;

  const PasswordChangeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateUserRolesRequested>(_onUpdateUserRolesRequested);
    on<CompleteProfileSetupEvent>(_onCompleteProfileSetup);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<ChangePasswordRequested>(_onChangePasswordRequested);

    // Only set up subscription if Supabase is initialized
    if (SupabaseService.isInitialized) {
      _setupAuthSubscription();
    } else {
      debugPrint('Skipping auth subscription setup - Supabase not initialized');
    }
  }

  void _setupAuthSubscription() {
    try {
      // Listen to auth state changes
      _authSubscription = _authRepository.authStateChanges.listen((authState) {
        if (authState.event == AuthChangeEvent.signedIn &&
            authState.session != null) {
          add(AuthCheckRequested());
        } else if (authState.event == AuthChangeEvent.signedOut) {
          add(AuthCheckRequested());
        } else if (authState.event == AuthChangeEvent.passwordRecovery) {
          debugPrint(
              'Password recovery detected - emitting PasswordRecoveryInProgress');
          emit(PasswordRecoveryInProgress());
        }
      }, onError: (error) {
        debugPrint('Auth subscription error: $error');
        add(AuthCheckRequested());
      });
    } catch (e) {
      debugPrint('Error setting up auth subscription: $e');
      add(AuthCheckRequested());
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      debugPrint('Auth check requested but Supabase not initialized');
      emit(Unauthenticated());
      return;
    }

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        // Refresh role switching service profile data when user is authenticated
        try {
          final roleSwitchingService = getIt<RoleSwitchingService>();
          await roleSwitchingService.refreshProfile();
        } catch (e) {
          debugPrint('Error refreshing role switching profile: $e');
        }
        emit(Authenticated(currentUser));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      final errorMsg = SupabaseService.initializationError ??
          'Authentication service unavailable';
      debugPrint('Sign up failed - Supabase not initialized: $errorMsg');
      emit(AuthError(
          'Authentication service unavailable. Please check your internet connection and try again. Error: $errorMsg'));
      return;
    }

    try {
      final response = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
      );

      if (response.user != null) {
        // Refresh role switching service profile data after successful signup
        try {
          final roleSwitchingService = getIt<RoleSwitchingService>();
          await roleSwitchingService.refreshProfile();
        } catch (e) {
          debugPrint(
              'Error refreshing role switching profile after signup: $e');
        }
        emit(Authenticated(response.user!));
      } else {
        emit(const AuthError('Failed to sign up'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      emit(const AuthError(
          'Unable to connect to authentication service. Please check your internet connection and try again.'));
      return;
    }

    try {
      final response = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        // Refresh role switching service profile data after successful login
        try {
          final roleSwitchingService = getIt<RoleSwitchingService>();
          await roleSwitchingService.refreshProfile();
        } catch (e) {
          // Log error but don't fail login
          if (kDebugMode) {
            debugPrint(
                'Error refreshing role switching profile after login: $e');
          }
        }
        emit(Authenticated(response.user!));
      } else {
        emit(const AuthError('Login failed. Please check your credentials.'));
      }
    } catch (e) {
      String errorMessage = _parseAuthError(e);
      emit(AuthError(errorMessage));
    }
  }

  /// Parse authentication errors and return user-friendly messages
  String _parseAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_grant')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (errorString.contains('email not confirmed') ||
        errorString.contains('email_not_confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    } else if (errorString.contains('too many requests') ||
        errorString.contains('rate_limit')) {
      return 'Too many login attempts. Please wait a few minutes and try again.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Connection error. Please check your internet connection and try again.';
    } else if (errorString.contains('user not found') ||
        errorString.contains('invalid_user')) {
      return 'No account found with this email address. Please check your email or create a new account.';
    } else if (errorString.contains('account_disabled') ||
        errorString.contains('user_disabled')) {
      return 'Your account has been disabled. Please contact support for assistance.';
    }

    // Fallback for unknown errors
    return 'Login failed. Please try again or contact support if the problem persists.';
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      emit(Unauthenticated());
      return;
    }

    try {
      await _authRepository.signOut();

      // Clear stored data including role switching data
      await AuthGuardService.clearStoredData();

      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateUserRolesRequested(
    UpdateUserRolesRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      emit(const AuthError('Authentication service unavailable'));
      return;
    }

    try {
      await _authRepository.updateUserRoles(roles: event.roles);

      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCompleteProfileSetup(
    CompleteProfileSetupEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      emit(const AuthError('Authentication service unavailable'));
      return;
    }

    try {
      // Update profile with additional information
      await _authRepository.updateProfile(
        location: event.location,
        bio: event.bio,
        primaryRole: event.selectedRole,
        enableNotifications: event.enableNotifications,
      );

      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      } else {
        emit(const AuthError('Failed to complete profile setup'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      final errorMsg = SupabaseService.initializationError ??
          'Authentication service unavailable';
      debugPrint('Password reset failed - Supabase not initialized: $errorMsg');
      emit(const PasswordResetError(
          'Authentication service unavailable. Please check your internet connection and try again.'));
      return;
    }

    try {
      await _authRepository.resetPassword(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      debugPrint('Error during password reset: $e');
      String errorMessage =
          'Failed to send password reset email. Please try again.';

      if (e.toString().contains('Invalid email')) {
        errorMessage = 'Invalid email address. Please check and try again.';
      } else if (e.toString().contains('Rate limit exceeded')) {
        errorMessage =
            'Too many requests. Please wait a few minutes before trying again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Connection error. Please check your internet connection.';
      }

      emit(PasswordResetError(errorMessage));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      final errorMsg = SupabaseService.initializationError ??
          'Authentication service unavailable';
      debugPrint(
          'Password update failed - Supabase not initialized: $errorMsg');
      emit(const PasswordUpdateError(
          'Authentication service unavailable. Please check your internet connection and try again.'));
      return;
    }

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: event.newPassword),
      );
      emit(PasswordUpdateSuccess());
    } catch (e) {
      debugPrint('Error during password update: $e');
      String errorMessage = 'Failed to update password. Please try again.';

      if (e.toString().contains('AuthSessionMissingException') ||
          e.toString().contains('Auth session missing')) {
        errorMessage =
            'Password reset session has expired or is invalid. Please request a new password reset email and use the link from your email.';
      } else if (e.toString().contains('Invalid')) {
        errorMessage = 'Invalid password. Please check and try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Connection error. Please check your internet connection.';
      }

      emit(PasswordUpdateError(errorMessage));
    }
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(PasswordChangeInProgress());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      final errorMsg = SupabaseService.initializationError ??
          'Authentication service unavailable';
      debugPrint(
          'Password change failed - Supabase not initialized: $errorMsg');
      emit(const PasswordChangeError(
          'Authentication service unavailable. Please check your internet connection and try again.'));
      return;
    }

    try {
      await _authRepository.changePassword(event.newPassword);
      emit(PasswordChangeSuccess());
    } catch (e) {
      debugPrint('Error during password change: $e');
      String errorMessage = 'Failed to change password. Please try again.';

      if (e.toString().contains('Invalid')) {
        errorMessage = 'Invalid password. Please check and try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Connection error. Please check your internet connection.';
      } else if (e.toString().contains('weak') ||
          e.toString().contains('too short')) {
        errorMessage =
            'Password is too weak. Please choose a stronger password.';
      }

      emit(PasswordChangeError(errorMessage));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
