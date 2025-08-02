import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _timeoutOccurred = false;
  bool _navigating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen initialized');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(_animationController);
    _animationController.forward();
    // Add initialization logic here
    _navigateToNextScreen();

    // Add a timeout to prevent infinite loading
    _setupTimeout();
  }

  void _setupTimeout() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_timeoutOccurred && !_navigating) {
        debugPrint('SplashScreen timeout occurred - forcing navigation');
        setState(() {
          _timeoutOccurred = true;
        });
        _forceNavigate();
      }
    });
  }

  void _forceNavigate() {
    if (_navigating) return;

    _navigating = true;
    debugPrint('Force navigating to onboarding');

    try {
      // Use GoRouter instead of Navigator
      if (!mounted) return;

      context.go('/onboarding');
    } catch (e) {
      debugPrint('Error in _forceNavigate: $e');
      // Fallback to direct navigation if GoRouter fails
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    debugPrint('Starting navigation delay');
    try {
      // Reduced delay from 2 seconds to 1 second
      await Future.delayed(const Duration(seconds: 3));
      debugPrint('Navigation delay completed');

      if (mounted && !_timeoutOccurred && !_navigating) {
        debugPrint('Navigating to OnboardingScreen');
        _navigating = true;

        // Use GoRouter instead of Navigator
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Error in _navigateToNextScreen: $e');
      if (mounted && !_timeoutOccurred && !_navigating) {
        _forceNavigate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/RentEase_logo.png',
              width: 300,
              height: 300,
            ),
          ),
        ),
      ),
    );
  }
}
