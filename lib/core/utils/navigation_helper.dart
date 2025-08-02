import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/services/navigation_state_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class NavigationHelper {
  /// Creates a back button for hamburger menu screens that navigates back to the appropriate bottom navigation tab
  static Widget createHamburgerMenuBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => navigateBackFromHamburgerMenu(context),
      tooltip: 'Back',
    );
  }

  /// Navigates back from a hamburger menu screen to the appropriate bottom navigation tab
  static void navigateBackFromHamburgerMenu(BuildContext context) {
    final backRoute =
        getIt<NavigationStateService>().getBackRouteForHamburgerMenu();
    context.go(backRoute);
  }

  /// Checks if the current route is a hamburger menu route
  static bool isHamburgerMenuRoute(String route) {
    return NavigationStateService.hamburgerMenuRoutes.contains(route);
  }

  /// Checks if the current route is a bottom navigation route
  static bool isBottomNavRoute(String route) {
    return NavigationStateService.bottomNavRoutes.contains(route);
  }
}
