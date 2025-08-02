import 'package:flutter/foundation.dart';

class NavigationStateService extends ChangeNotifier {
  static final NavigationStateService _instance =
      NavigationStateService._internal();
  factory NavigationStateService() => _instance;
  NavigationStateService._internal();

  String _currentBottomNavRoute = '/home';

  String get currentBottomNavRoute => _currentBottomNavRoute;

  // Bottom navigation routes
  static const List<String> bottomNavRoutes = [
    '/home',
    '/rentals',
    '/create-listing',
    '/messages',
    '/profile',
  ];

  // Hamburger menu routes
  static const List<String> hamburgerMenuRoutes = [
    '/my-listings',
    '/track-orders',
    '/driver-dashboard',
    '/earnings',
    '/settings',
    '/help',
    '/about',
  ];

  void updateCurrentBottomNavRoute(String route) {
    if (bottomNavRoutes.contains(route)) {
      _currentBottomNavRoute = route;
      notifyListeners();
    }
  }

  void setBottomNavRouteForHamburgerNavigation(String currentRoute) {
    // If we're currently on a bottom nav route, store it
    if (bottomNavRoutes.contains(currentRoute)) {
      _currentBottomNavRoute = currentRoute;
      notifyListeners();
    }
    // If we're on a hamburger menu route, keep the existing stored route
    // If we're on some other route, default to home
    else if (!hamburgerMenuRoutes.contains(currentRoute)) {
      _currentBottomNavRoute = '/home';
      notifyListeners();
    }
  }

  String getBackRouteForHamburgerMenu() {
    return _currentBottomNavRoute;
  }
}
