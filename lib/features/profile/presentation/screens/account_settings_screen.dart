import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';
import 'package:rent_ease/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:rent_ease/features/profile/data/models/profile_model.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rent_ease/shared/widgets/location_picker_widget.dart';
import 'package:rent_ease/features/auth/presentation/bloc/auth_bloc.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _twoFactorEnabled = false;
  bool _profileVisibility = true;
  bool _showEmail = true;
  bool _showPhone = false;
  String _accountVisibility = 'Public';
  ProfileModel? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadAccountSettings();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
        _profileVisibility = prefs.getBool('profile_visibility') ?? true;
        _showEmail = prefs.getBool('show_email') ?? true;
        _showPhone = prefs.getBool('show_phone') ?? false;
        _accountVisibility = prefs.getString('account_visibility') ?? 'Public';
      });
    } catch (e) {
      debugPrint('Error loading account settings: $e');
    }
  }

  void _loadProfile() {
    final userId = AuthGuardService.getCurrentUserId();
    if (userId != null) {
      context.read<ProfileBloc>().add(LoadProfile(userId));
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFields(ProfileModel profile) {
    _fullNameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _currentProfile = profile;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = ProfileModel(
        id: _currentProfile!.id,
        email: _currentProfile!.email,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        avatarUrl: _currentProfile!.avatarUrl,
        primaryRole: _currentProfile!.primaryRole,
        roles: _currentProfile!.roles,
        enableNotifications: _currentProfile!.enableNotifications,
        createdAt: _currentProfile!.createdAt,
        updatedAt: DateTime.now(),
      );

      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: NavigationHelper.createHamburgerMenuBackButton(context),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: ColorConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _populateFields(state.profile);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader(
                      'Personal Information',
                      onEdit: () => setState(() => _isEditing = !_isEditing),
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildPersonalInfoSection(),

                    const SizedBox(height: 32),

                    // Privacy Settings Section
                    _buildSectionHeader('Privacy Settings'),
                    const SizedBox(height: 16),
                    _buildPrivacySection(),

                    const SizedBox(height: 32),

                    // Security Settings Section
                    _buildSectionHeader('Security Settings'),
                    const SizedBox(height: 16),
                    _buildSecuritySection(),

                    const SizedBox(height: 32),

                    // Account Management Section
                    _buildSectionHeader('Account Management'),
                    const SizedBox(height: 16),
                    _buildAccountManagementSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {VoidCallback? onEdit, bool isEditing = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(
              isEditing ? Icons.close : Icons.edit,
              size: 16,
              color: ColorConstants.primaryColor,
            ),
            label: Text(
              isEditing ? 'Cancel' : 'Edit',
              style: const TextStyle(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        _buildInfoCard(
          child: Column(
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller:
                    TextEditingController(text: _currentProfile?.email ?? ''),
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: false, // Email should not be editable
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _isEditing
                  ? LocationPickerWidget(
                      initialLocation: _locationController.text,
                      onLocationSelected: (locationName, latitude, longitude) {
                        setState(() {
                          _locationController.text = locationName;
                        });
                      },
                    )
                  : _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      enabled: false,
                    ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.info_outline,
                enabled: _isEditing,
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Profile Visibility',
          subtitle: 'Make your profile visible to other users',
          icon: Icons.visibility_outlined,
          trailing: Switch(
            value: _profileVisibility,
            onChanged: (value) {
              setState(() {
                _profileVisibility = value;
              });
              _saveSetting('profile_visibility', value);
            },
            activeColor: ColorConstants.primaryColor,
          ),
        ),
        _buildSettingTile(
          title: 'Show Email',
          subtitle: 'Display email on your public profile',
          icon: Icons.email_outlined,
          trailing: Switch(
            value: _showEmail,
            onChanged: (value) {
              setState(() {
                _showEmail = value;
              });
              _saveSetting('show_email', value);
            },
            activeColor: ColorConstants.primaryColor,
          ),
        ),
        _buildSettingTile(
          title: 'Show Phone',
          subtitle: 'Display phone number on your public profile',
          icon: Icons.phone_outlined,
          trailing: Switch(
            value: _showPhone,
            onChanged: (value) {
              setState(() {
                _showPhone = value;
              });
              _saveSetting('show_phone', value);
            },
            activeColor: ColorConstants.primaryColor,
          ),
        ),
        _buildSettingTile(
          title: 'Account Visibility',
          subtitle: _accountVisibility,
          icon: Icons.public_outlined,
          onTap: () => _showAccountVisibilityDialog(),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Two-Factor Authentication',
          subtitle: _twoFactorEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.security_outlined,
          trailing: Switch(
            value: _twoFactorEnabled,
            onChanged: (value) {
              setState(() {
                _twoFactorEnabled = value;
              });
              _saveSetting('two_factor_enabled', value);
              if (value) {
                _showTwoFactorSetupDialog();
              }
            },
            activeColor: ColorConstants.primaryColor,
          ),
        ),
        _buildSettingTile(
          title: 'Change Password',
          subtitle: 'Update your account password',
          icon: Icons.lock_outline,
          onTap: () => _showChangePasswordDialog(),
        ),
        _buildSettingTile(
          title: 'Login Activity',
          subtitle: 'View recent login sessions',
          icon: Icons.history_outlined,
          onTap: () => _showLoginActivityDialog(),
        ),
        _buildSettingTile(
          title: 'Connected Accounts',
          subtitle: 'Manage linked social accounts',
          icon: Icons.link_outlined,
          onTap: () => _showConnectedAccountsDialog(),
        ),
      ],
    );
  }

  Widget _buildAccountManagementSection() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Download My Data',
          subtitle: 'Export your account data',
          icon: Icons.download_outlined,
          onTap: () => _showDownloadDataDialog(),
        ),
        _buildSettingTile(
          title: 'Deactivate Account',
          subtitle: 'Temporarily disable your account',
          icon: Icons.pause_circle_outline,
          onTap: () => _showDeactivateAccountDialog(),
          textColor: Colors.orange,
        ),
        _buildSettingTile(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          icon: Icons.delete_outline,
          onTap: () => _showDeleteAccountDialog(),
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ColorConstants.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorConstants.primaryColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ColorConstants.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  )
                : null),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  // Dialog methods
  void _showAccountVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVisibilityOption(
                'Public', 'Anyone can find and view your profile'),
            _buildVisibilityOption(
                'Friends Only', 'Only your connections can view your profile'),
            _buildVisibilityOption(
                'Private', 'Your profile is hidden from searches'),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(String option, String description) {
    return ListTile(
      title: Text(option),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: _accountVisibility == option
          ? const Icon(Icons.check, color: ColorConstants.primaryColor)
          : null,
      onTap: () {
        setState(() {
          _accountVisibility = option;
        });
        _saveSetting('account_visibility', option);
        Navigator.of(context).pop();
      },
    );
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. You will need to verify your identity using a second method when signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to 2FA setup screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Two-factor authentication setup would be implemented here'),
                ),
              );
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is PasswordChangeSuccess) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PasswordChangeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is PasswordChangeInProgress;

              return AlertDialog(
                title: const Text('Change Password'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                    ChangePasswordRequested(
                                      newPassword: newPasswordController.text,
                                    ),
                                  );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change Password'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLoginActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Activity'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone_android),
                title: Text('Mobile App'),
                subtitle: Text('Today, 2:30 PM\nLocation: New York, NY'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              ListTile(
                leading: Icon(Icons.computer),
                title: Text('Web Browser'),
                subtitle: Text('Yesterday, 9:15 AM\nLocation: New York, NY'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              ListTile(
                leading: Icon(Icons.phone_android),
                title: Text('Mobile App'),
                subtitle: Text('3 days ago, 6:45 PM\nLocation: Brooklyn, NY'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showConnectedAccountsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connected Accounts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.g_mobiledata, color: Colors.red),
              title: Text('Google'),
              subtitle: Text('Connected'),
              trailing: TextButton(
                onPressed: null,
                child: Text('Disconnect'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.facebook, color: Colors.blue),
              title: Text('Facebook'),
              subtitle: Text('Not connected'),
              trailing: TextButton(
                onPressed: null,
                child: Text('Connect'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.apple, color: Colors.black),
              title: Text('Apple'),
              subtitle: Text('Not connected'),
              trailing: TextButton(
                onPressed: null,
                child: Text('Connect'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Text(
          'We will prepare a copy of your data and send it to your email address. This may take up to 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export request submitted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Your account will be temporarily disabled. You can reactivate it by signing in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Account deactivation would be implemented here'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion would be implemented here'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
