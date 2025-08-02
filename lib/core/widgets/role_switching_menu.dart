import 'package:flutter/material.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/core/widgets/role_switching_loading_screen.dart';

class RoleSwitchingMenu extends StatefulWidget {
  final VoidCallback? onRoleChanged;

  const RoleSwitchingMenu({super.key, this.onRoleChanged});

  @override
  State<RoleSwitchingMenu> createState() => _RoleSwitchingMenuState();
}

class _RoleSwitchingMenuState extends State<RoleSwitchingMenu> {
  late RoleSwitchingService _roleSwitchingService;

  @override
  void initState() {
    super.initState();
    _roleSwitchingService = getIt<RoleSwitchingService>();
    _roleSwitchingService.addListener(_onRoleServiceChanged);
  }

  @override
  void dispose() {
    _roleSwitchingService.removeListener(_onRoleServiceChanged);
    super.dispose();
  }

  void _onRoleServiceChanged() {
    if (mounted) {
      // Defer setState to avoid calling it during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoles = _roleSwitchingService.availableRoles;
    final activeRole = _roleSwitchingService.activeRole;
    final isLoading = _roleSwitchingService.isLoading;
    final loadingRole = _roleSwitchingService.loadingRole;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: ColorConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Switch Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...availableRoles.map((role) => _buildRoleOption(
                context,
                role,
                activeRole == role,
                isLoading && loadingRole == role,
                isLoading,
              )),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    String role,
    bool isActive,
    bool isLoadingThisRole,
    bool isAnyRoleLoading,
  ) {
    return ListTile(
      leading: Icon(
        _getRoleIcon(role),
        color: isActive ? ColorConstants.primaryColor : Colors.grey[600],
      ),
      title: Text(
        _roleSwitchingService.getRoleDisplayName(role),
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? ColorConstants.primaryColor : Colors.black87,
        ),
      ),
      trailing: _buildTrailing(isActive, isLoadingThisRole),
      onTap:
          (isActive || isAnyRoleLoading) ? null : () => _handleRoleSwitch(role),
    );
  }

  void _handleRoleSwitch(String role) async {
    // Close the menu first
    Navigator.of(context).pop();

    // Show fullscreen loading screen
    showRoleSwitchingLoadingScreen(
      context,
      role,
      onComplete: () {
        widget.onRoleChanged?.call();
      },
    );
  }

  Widget? _buildTrailing(bool isActive, bool isLoadingThisRole) {
    // Remove inline loading indicators since we now use fullscreen loading
    if (isActive) {
      return const Icon(
        Icons.check_circle,
        color: ColorConstants.primaryColor,
        size: 20,
      );
    }

    return null;
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'renter':
        return Icons.shopping_bag;
      case 'lender':
        return Icons.store;
      case 'driver':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }
}
