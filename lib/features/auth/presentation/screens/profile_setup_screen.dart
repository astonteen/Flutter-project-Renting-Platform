import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/widgets/custom_text_field.dart';
import 'package:rent_ease/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String selectedRole;

  const ProfileSetupScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  bool _enableNotifications = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _completeProfileSetup() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            CompleteProfileSetupEvent(
              location: _locationController.text.trim(),
              bio: _bioController.text.trim(),
              selectedRole: widget.selectedRole,
              enableNotifications: _enableNotifications,
            ),
          );
    }
  }

  void _navigateToHome() async {
    try {
      // Mark profile setup as completed
      await AuthGuardService.setProfileSetupCompleted();
      debugPrint('Profile setup marked as completed');

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else if (state is Authenticated) {
            setState(() => _isLoading = false);
            _navigateToHome();
          } else if (state is AuthError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Welcome to RentEase!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s set up your profile as a ${_getRoleDisplayName(widget.selectedRole)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ColorConstants.grey,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Profile photo section (placeholder for now)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstants.primaryColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                              color: ColorConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement photo upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Photo upload coming soon!'),
                              ),
                            );
                          },
                          child: const Text('Add Profile Photo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Location field
                  CustomTextField(
                    controller: _locationController,
                    labelText: 'Location',
                    hintText: 'Enter your city or area',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bio field
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Bio (Optional)',
                      hintText: 'Tell others about yourself...',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: ColorConstants.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: ColorConstants.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role-specific setup
                  _buildRoleSpecificSetup(),
                  const SizedBox(height: 24),

                  // Notification preferences
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferences',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _enableNotifications,
                          onChanged: (value) {
                            setState(() => _enableNotifications = value);
                          },
                          title: const Text('Enable Notifications'),
                          subtitle: const Text(
                              'Get updates about your rentals and deliveries'),
                          contentPadding: EdgeInsets.zero,
                          activeColor: ColorConstants.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Complete setup button
                  CustomButton(
                    text: 'Complete Setup',
                    onPressed: _completeProfileSetup,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Skip for now option
                  Center(
                    child: TextButton(
                      onPressed: _navigateToHome,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: ColorConstants.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSetup() {
    switch (widget.selectedRole) {
      case 'renter':
        return Container(); // Empty container for renters (no special setup needed)
      case 'owner':
        return _buildOwnerSetup();
      case 'driver':
        return _buildDriverSetup();
      default:
        return Container(); // Empty container for unknown roles
    }
  }

  Widget _buildOwnerSetup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ColorConstants.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Owner Setup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'As an owner, you can list your items for rent and earn money. You\'ll be able to add your first item after completing setup!',
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSetup() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ColorConstants.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.delivery_dining_outlined,
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Partner Setup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'As a delivery partner, you can earn money by delivering items between renters and owners. Additional verification may be required.',
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'driver':
        return 'Delivery Partner';
      default:
        return 'User';
    }
  }
}
