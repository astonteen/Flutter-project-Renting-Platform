import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/app_constants.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rent_ease/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:rent_ease/features/messages/presentation/bloc/messages_bloc.dart';
import 'package:rent_ease/core/services/navigation_state_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userId = SupabaseService.currentUser?.id;
    if (userId != null) {
      // Load profile data
      context.read<ProfileBloc>().add(LoadProfile(userId));
      // Load conversations to get unread count
      context.read<MessagesBloc>().add(LoadConversations());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // User Profile Header
          _buildUserHeader(context),

          // Scrollable menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // My Items
                _buildSectionHeader('My Items'),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  text: 'My Listings',
                  route: '/my-listings',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  text: 'Track Orders',
                  route: '/track-orders',
                ),

                const Divider(height: 24),

                // Tools
                _buildSectionHeader('Tools'),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  text: 'Driver Dashboard',
                  route: '/driver-dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  text: 'Earnings',
                  route: '/earnings',
                ),

                const Divider(height: 24),

                // Support
                _buildSectionHeader('Support'),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  text: 'Settings',
                  route: '/settings',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  text: 'Help & Support',
                  route: '/help',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  text: 'About',
                  route: '/about',
                ),

                const Divider(height: 24),

                // Logout
                _buildDrawerItem(
                  context,
                  icon: Icons.logout_outlined,
                  text: 'Logout',
                  route: '/logout',
                  isDestructive: true,
                ),
              ],
            ),
          ),

          // App Version Footer
          _buildVersionFooter(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ColorConstants.primaryGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  // Get user data
                  final user =
                      authState is Authenticated ? authState.user : null;
                  final profile = profileState is ProfileLoaded
                      ? profileState.profile
                      : null;
                  final statistics = profileState is ProfileLoaded
                      ? profileState.statistics
                      : null;

                  // Default values
                  final displayName = profile?.fullName ??
                      user?.email?.split('@').first ??
                      'User';
                  final userRole = profile?.primaryRole ?? 'renter';
                  final roleDisplay = _getRoleDisplay(userRole);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar and Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                ColorConstants.white.withValues(alpha: 0.2),
                            backgroundImage: profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                            child: profile?.avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: ColorConstants.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: ColorConstants.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    roleDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Quick Stats
                      Row(
                        children: [
                          _buildQuickStat(
                            statistics?.averageRating.toStringAsFixed(1) ??
                                '0.0',
                            'Rating',
                          ),
                          const SizedBox(width: 24),
                          _buildQuickStat(
                            statistics?.rentalsCount.toString() ?? '0',
                            'Rentals',
                          ),
                          const SizedBox(width: 24),
                          _buildQuickStat(
                            statistics?.listingsCount.toString() ?? '0',
                            'Listings',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'renter':
        return 'Renter';
      case 'owner':
        return 'Owner';
      case 'driver':
        return 'Driver';
      default:
        return 'User';
    }
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String route,
    Widget? badge,
    bool isDestructive = false,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute.startsWith(route);

    final itemColor = isDestructive
        ? Colors.red[600]
        : isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey[700];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: itemColor,
        size: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isDestructive
              ? Colors.red[600]
              : isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
          fontSize: 16,
        ),
      ),
      trailing: badge,
      tileColor: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);

        if (route == '/logout') {
          _showLogoutDialog(context);
        } else {
          // Store current route before navigating to hamburger menu screens
          getIt<NavigationStateService>()
              .setBottomNavRouteForHamburgerNavigation(currentRoute);
          context.go(route);
        }
      },
    );
  }

  Widget _buildVersionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                // Trigger logout through AuthBloc
                context.read<AuthBloc>().add(SignOutRequested());
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
