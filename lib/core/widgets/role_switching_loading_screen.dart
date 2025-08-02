import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class RoleSwitchingLoadingScreen extends StatefulWidget {
  final String targetRole;
  final VoidCallback? onComplete;

  const RoleSwitchingLoadingScreen({
    super.key,
    required this.targetRole,
    this.onComplete,
  });

  @override
  State<RoleSwitchingLoadingScreen> createState() =>
      _RoleSwitchingLoadingScreenState();
}

class _RoleSwitchingLoadingScreenState extends State<RoleSwitchingLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late RoleSwitchingService _roleSwitchingService;

  @override
  void initState() {
    super.initState();
    _roleSwitchingService = getIt<RoleSwitchingService>();

    // Set fullscreen mode immediately
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Defer the role switching to after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRoleSwitching();
    });
  }

  @override
  void dispose() {
    // Restore system UI when leaving the loading screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startRoleSwitching() async {
    debugPrint(
        'RoleSwitchingLoadingScreen: Starting role switch to ${widget.targetRole}');

    // Start animations
    _animationController.forward();

    try {
      // Perform the role switch
      debugPrint('RoleSwitchingLoadingScreen: Calling switchRole service');
      await _roleSwitchingService.switchRole(widget.targetRole);
      debugPrint(
          'RoleSwitchingLoadingScreen: Role switch completed successfully');

      // Wait for animations to complete (if not already completed)
      if (!_animationController.isCompleted) {
        await _animationController.forward();
      }

      // Add a small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint(
            'RoleSwitchingLoadingScreen: Setting completion state and navigating');
        _navigateToHomeScreen();
      }
    } catch (e) {
      debugPrint('RoleSwitchingLoadingScreen: Error during role switch: $e');
      if (mounted) {
        _showErrorAndGoBack(e.toString());
      }
    }
  }

  void _navigateToHomeScreen() {
    debugPrint(
        'RoleSwitchingLoadingScreen: Starting navigation to home screen');

    // Close the loading screen first using root navigator
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      debugPrint('RoleSwitchingLoadingScreen: Popping loading screen');
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Call the completion callback
    debugPrint('RoleSwitchingLoadingScreen: Calling onComplete callback');
    widget.onComplete?.call();

    // Navigate to the appropriate default screen for the new role
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final defaultRoute = _getDefaultRouteForRole(widget.targetRole);
        debugPrint(
            'RoleSwitchingLoadingScreen: Navigating to $defaultRoute for role ${widget.targetRole}');
        context.go(defaultRoute);
      }
    });
  }

  String _getDefaultRouteForRole(String role) {
    switch (role) {
      case 'renter':
        return '/home';
      case 'lender':
        return '/home'; // Start with home for lenders too, but they'll see lender-specific content
      case 'driver':
        return '/driver-dashboard';
      default:
        return '/home';
    }
  }

  void _showErrorAndGoBack(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to switch role: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // Go back after showing error using root navigator
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Hide the app bar completely
        automaticallyImplyLeading: false, // Remove back button
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstants.primaryColor,
                  ColorConstants.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Role icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: _buildRoleAnimation(widget.targetRole),
                      ),

                      const SizedBox(height: 40),

                      // Loading indicator
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Switching text
                      Text(
                        'Switching to ${_getRoleDisplayName(widget.targetRole)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Setting up your ${_getRoleDisplayName(widget.targetRole).toLowerCase()} experience...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 60),

                      // Progress dots
                      _buildProgressDots(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _animationController.value > (index * 0.3)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildRoleAnimation(String role) {
    // For driver role, try to show car.gif animation if available
    if (role == 'driver') {
      // TODO: When car.gif is added to assets/images/, uncomment the following:
      // try {
      //   return Image.asset(
      //     'assets/images/car.gif',
      //     width: 60,
      //     height: 60,
      //     color: Colors.white,
      //     colorBlendMode: BlendMode.srcIn,
      //     errorBuilder: (context, error, stackTrace) {
      //       return Icon(
      //         _getRoleIcon(role),
      //         size: 60,
      //         color: Colors.white,
      //       );
      //     },
      //   );
      // } catch (e) {
      //   // Fallback to icon if gif is not available
      //   return Icon(
      //     _getRoleIcon(role),
      //     size: 60,
      //     color: Colors.white,
      //   );
      // }
    }

    // For other roles or when car.gif is not available, show icon
    return Icon(
      _getRoleIcon(role),
      size: 60,
      color: Colors.white,
    );
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

  String _getRoleDisplayName(String role) {
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
}

// Helper function to show the role switching loading screen
void showRoleSwitchingLoadingScreen(
  BuildContext context,
  String targetRole, {
  VoidCallback? onComplete,
}) {
  // Use root navigator to ensure fullscreen overlay
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          RoleSwitchingLoadingScreen(
        targetRole: targetRole,
        onComplete: onComplete,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      fullscreenDialog: true,
      opaque: true, // Make it completely opaque
      barrierDismissible: false, // Prevent dismissing by tapping outside
      maintainState: false, // Don't maintain state when popped
    ),
  );
}
