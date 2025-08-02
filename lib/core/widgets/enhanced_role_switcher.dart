import 'package:flutter/material.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class EnhancedRoleSwitcher extends StatefulWidget {
  final VoidCallback? onRoleChanged;
  final bool showAsBottomSheet;
  final String? title;
  final String? subtitle;

  const EnhancedRoleSwitcher({
    super.key,
    this.onRoleChanged,
    this.showAsBottomSheet = false,
    this.title,
    this.subtitle,
  });

  @override
  State<EnhancedRoleSwitcher> createState() => _EnhancedRoleSwitcherState();
}

class _EnhancedRoleSwitcherState extends State<EnhancedRoleSwitcher>
    with TickerProviderStateMixin {
  late RoleSwitchingService _roleSwitchingService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _roleSwitchingService = getIt<RoleSwitchingService>();
    _roleSwitchingService.addListener(_onRoleServiceChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _roleSwitchingService.removeListener(_onRoleServiceChanged);
    _animationController.dispose();
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final availableRoles = _roleSwitchingService.availableRoles;
    final activeRole = _roleSwitchingService.activeRole;
    final isLoading = _roleSwitchingService.isLoading;
    final loadingRole = _roleSwitchingService.loadingRole;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildRoleList(availableRoles, activeRole, isLoading, loadingRole),
          if (availableRoles.length > 1) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: ColorConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Switch Role',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleList(
    List<String> availableRoles,
    String activeRole,
    bool isLoading,
    String? loadingRole,
  ) {
    return Column(
      children: availableRoles
          .map((role) => _buildRoleOption(
                role,
                activeRole == role,
                isLoading && loadingRole == role,
                isLoading,
              ))
          .toList(),
    );
  }

  Widget _buildRoleOption(
    String role,
    bool isActive,
    bool isLoadingThisRole,
    bool isAnyRoleLoading,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? ColorConstants.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(
                color: ColorConstants.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? ColorConstants.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getRoleIcon(role),
            color: isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          _roleSwitchingService.getRoleDisplayName(role),
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? ColorConstants.primaryColor : Colors.black87,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _getRoleDescription(role),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: _buildTrailing(isActive, isLoadingThisRole),
        onTap: (isActive || isAnyRoleLoading)
            ? null
            : () => _handleRoleSwitch(role),
      ),
    );
  }

  Widget _buildTrailing(bool isActive, bool isLoadingThisRole) {
    if (isLoadingThisRole) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation<Color>(ColorConstants.primaryColor),
        ),
      );
    }

    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: ColorConstants.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.grey[400],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Long press the profile tab to quickly switch roles',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _handleRoleSwitch(String role) async {
    try {
      await _roleSwitchingService.switchRole(role);
      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                    'Switched to ${_roleSwitchingService.getRoleDisplayName(role)}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.fixed,
          ),
        );

        // Close dialog/bottom sheet
        Navigator.of(context).pop();
        widget.onRoleChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to switch role: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
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

  String _getRoleDescription(String role) {
    switch (role) {
      case 'renter':
        return 'Browse and rent items';
      case 'lender':
        return 'List and manage your items';
      case 'driver':
        return 'Deliver items and earn';
      default:
        return 'User role';
    }
  }
}

// Helper function to show the enhanced role switcher
void showEnhancedRoleSwitcher(
  BuildContext context, {
  VoidCallback? onRoleChanged,
  String? title,
  String? subtitle,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: EnhancedRoleSwitcher(
        onRoleChanged: onRoleChanged,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

// Helper function to show as bottom sheet
void showEnhancedRoleSwitcherBottomSheet(
  BuildContext context, {
  VoidCallback? onRoleChanged,
  String? title,
  String? subtitle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      child: EnhancedRoleSwitcher(
        onRoleChanged: onRoleChanged,
        showAsBottomSheet: true,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}
