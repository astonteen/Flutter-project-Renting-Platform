import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Rent Anything',
      description:
          'Find and rent items from people around you for your daily needs',
      icon: Icons.shopping_bag,
    ),
    OnboardingItem(
      title: 'List Your Items',
      description: 'Make money by renting out items you don\'t use every day',
      icon: Icons.monetization_on,
    ),
    OnboardingItem(
      title: 'Deliver Items',
      description: 'Earn by delivering rented items between owners and renters',
      icon: Icons.delivery_dining,
    ),
    OnboardingItem(
      title: 'All in One App',
      description: 'Switch between renting, lending, and delivering seamlessly',
      icon: Icons.swap_horiz,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToLogin() async {
    debugPrint('Navigating to login from onboarding');
    try {
      // Mark onboarding as completed
      await AuthGuardService.setOnboardingCompleted();
      debugPrint('Onboarding marked as completed');

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error navigating to login: $e');
      // Fallback navigation if GoRouter fails
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingItems.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return OnboardingPage(item: _onboardingItems[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingItems.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? ColorConstants.primaryColor
                          : ColorConstants.lightGrey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CustomButton(
                    text: _currentPage == _onboardingItems.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: () {
                      debugPrint(
                          'Button pressed. Current page: $_currentPage, Total pages: ${_onboardingItems.length}');
                      if (_currentPage < _onboardingItems.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        debugPrint('Navigating to login - Get Started pressed');
                        _navigateToLogin();
                      }
                    },
                  ),
                  // Temporary debug button - remove this later
                  if (_currentPage == _onboardingItems.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        debugPrint('Debug: Force navigation to login');
                        try {
                          // Try multiple navigation methods
                          context.go('/login');
                        } catch (e) {
                          debugPrint('GoRouter failed: $e');
                          try {
                            context.push('/login');
                          } catch (e2) {
                            debugPrint('Push failed: $e2');
                            // Last resort - replace current route
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          }
                        }
                      },
                      child: const Text(
                        'Debug: Go to Login',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 80,
              color: ColorConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            item.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ColorConstants.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
