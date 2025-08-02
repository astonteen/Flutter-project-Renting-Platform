import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rent_ease/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:rent_ease/features/profile/data/models/profile_model.dart';
import 'package:rent_ease/features/profile/data/models/user_statistics_model.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/rental/presentation/bloc/booking_bloc.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/core/widgets/role_switching_loading_screen.dart';

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileBloc? _profileBloc;
  late PageController _actionButtonsController;
  bool _isLoadingDriverProfile = false;

  @override
  void initState() {
    super.initState();
    _actionButtonsController = PageController();
    _loadProfile();
    _loadMyListings();
    _loadUserBookings();
    _loadDriverProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileBloc = context.read<ProfileBloc>();
  }

  @override
  void dispose() {
    _profileBloc?.add(StopRealtimeUpdates());
    _actionButtonsController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final userId = AuthGuardService.getCurrentUserId();
    if (userId != null) {
      context.read<ProfileBloc>().add(LoadProfile(userId));
      context.read<ProfileBloc>().add(StartRealtimeUpdates(userId));
    }
  }

  void _loadMyListings() {
    context.read<ListingBloc>().add(LoadMyListings());
  }

  void _loadUserBookings() {
    final userId = AuthGuardService.getCurrentUserId();
    if (userId != null) {
      context.read<BookingBloc>().add(LoadUserBookings(userId));
    }
  }

  void _loadDriverProfile() async {
    final userId = AuthGuardService.getCurrentUserId();
    if (userId != null) {
      setState(() {
        _isLoadingDriverProfile = true;
      });

      context.read<DeliveryBloc>().add(LoadDriverProfile(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                context.pushReplacement('/login');
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              // Handle profile-specific state changes if needed
            },
          ),
          BlocListener<DeliveryBloc, DeliveryState>(
            listener: (context, state) {
              if (state is DriverProfileLoaded) {
                setState(() {
                  _isLoadingDriverProfile = false;
                });
              } else if (state is DeliveryError &&
                  state.errorType == 'profile_not_found') {
                setState(() {
                  _isLoadingDriverProfile = false;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const LoadingWidget(message: 'Loading profile...');
            }

            if (state is ProfileError) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: () => _loadProfile(),
              );
            }

            if (state is ProfileLoaded) {
              return _buildProfileContent(state.profile, state.statistics);
            }

            return const Center(
              child: Text('No profile data available'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      ProfileModel profile, UserStatisticsModel statistics) {
    return CustomScrollView(
      slivers: [
        _buildProfileHeader(profile, statistics),
      ],
    );
  }

  Widget _buildProfileHeader(
      ProfileModel profile, UserStatisticsModel statistics) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top bar
                Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.black87),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Profile section
                Column(
                  children: [
                    // Avatar with initial-based fallback
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: profile.hasAvatar
                          ? Colors.transparent
                          : Colors.grey[100],
                      backgroundImage: profile.hasAvatar
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.hasAvatar
                          ? null
                          : Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // Name and role
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      profile.primaryRole?.capitalize() ?? 'Guest',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Feature cards section
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: profile.primaryRole == 'lender'
                                ? Icons.attach_money
                                : Icons.local_shipping_outlined,
                            title: profile.primaryRole == 'lender'
                                ? 'Earnings'
                                : 'Track My Orders',
                            subtitle: profile.primaryRole == 'lender'
                                ? 'View your earnings'
                                : 'Track your rental orders',
                            onTap: () => context.push(
                                profile.primaryRole == 'lender'
                                    ? '/earnings'
                                    : '/track-orders'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.people,
                            title: 'Connections',
                            subtitle: 'Your rental network',
                            onTap: () => context.push('/connections'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCards(),
                  ],
                ),

                const SizedBox(height: 16),

                // Account settings
                _buildSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: [
        _buildDriverCard(),
        const SizedBox(height: 12),
        _buildLenderCard(),
      ],
    );
  }

  Widget _buildLenderCard() {
    final roleSwitchingService = getIt<RoleSwitchingService>();
    final bool isLender = roleSwitchingService.hasRole('lender');

    final String title = isLender ? 'Lender Dashboard' : 'Become a Lender';
    final String subtitle = isLender
        ? 'Manage your rental listings'
        : 'Start earning by renting out items';
    final IconData icon = isLender ? Icons.dashboard : Icons.store;
    final Color? backgroundColor = isLender ? Colors.blue[50] : Colors.grey[50];
    final Color? borderColor = isLender ? Colors.blue[200] : Colors.grey[200];
    final Color? iconColor =
        isLender ? Colors.blue[600] : ColorConstants.primaryColor;
    final Color? titleColor = isLender ? Colors.blue[700] : Colors.black87;

    return GestureDetector(
      onTap: () async {
        if (isLender) {
          // Show loading screen and switch to lender role, then navigate to home
          showRoleSwitchingLoadingScreen(
            context,
            'lender',
            onComplete: () {
              // Navigation will be handled by the loading screen
              // User will land on home with lender-specific content
            },
          );
        } else {
          // Show become lender dialog
          _showBecomeLenderDialog();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    final roleSwitchingService = getIt<RoleSwitchingService>();
    final bool isDriver = roleSwitchingService.hasRole('driver');

    if (_isLoadingDriverProfile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loading driver status...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String title = isDriver ? 'Driver Dashboard' : 'Become a Driver';
    final String subtitle = isDriver
        ? 'Manage your delivery services'
        : 'Start earning by delivering items';
    final IconData icon = isDriver ? Icons.dashboard : Icons.local_shipping;
    final Color? backgroundColor =
        isDriver ? Colors.green[50] : Colors.grey[50];
    final Color? borderColor = isDriver ? Colors.green[200] : Colors.grey[200];
    final Color? iconColor =
        isDriver ? Colors.green[600] : ColorConstants.primaryColor;
    final Color? titleColor = isDriver ? Colors.green[700] : Colors.black87;

    return GestureDetector(
      onTap: () async {
        if (isDriver) {
          // Show loading screen with car animation and switch to driver role
          showRoleSwitchingLoadingScreen(
            context,
            'driver',
            onComplete: () {
              // Navigation will be handled by the loading screen
              // It will automatically navigate to enhanced driver dashboard
            },
          );
        } else {
          // Show become driver dialog
          _showBecomeDriverDialog();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: ColorConstants.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildSettingsItem(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          onTap: () => context.push('/saved-addresses'),
        ),
        _buildSettingsItem(
          icon: Icons.settings,
          title: 'Account settings',
          onTap: () => context.push('/account-settings'),
        ),
        _buildSettingsItem(
          icon: Icons.notifications_outlined,
          title: 'Notification settings',
          onTap: () => context.push('/notification-settings'),
        ),
        _buildSettingsItem(
          icon: Icons.help_outline,
          title: 'Get help',
          onTap: () => context.push('/help'),
        ),
        _buildSettingsItem(
          icon: Icons.person_outline,
          title: 'View profile',
          onTap: () => context.push('/view-profile'),
        ),
        _buildSettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy',
          onTap: () => context.push('/privacy'),
        ),
        _buildSettingsItem(
          icon: Icons.logout,
          title: 'Log out',
          onTap: () => _showLogoutDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _showBecomeLenderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become a Lender'),
        content: const Text(
          'Join our marketplace and start earning money by renting out your items. '
          'You can list anything from tools and equipment to electronics and more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final roleSwitchingService = getIt<RoleSwitchingService>();
              final success = await roleSwitchingService.addRole('lender');

              if (success) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Welcome to the lender community!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                  setState(() {}); // Refresh the UI
                }
              } else {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to add lender role. Please try again.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Become a Lender'),
          ),
        ],
      ),
    );
  }

  void _showBecomeDriverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 40,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Become a Driver',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Content
                const Text(
                  'Join our delivery network and start earning! You\'ll need to provide vehicle and payment information to get started.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Navigate to driver registration screen
                          context.go('/driver-registration');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
