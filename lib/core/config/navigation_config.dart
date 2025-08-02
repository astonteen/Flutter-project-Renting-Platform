import 'package:flutter/material.dart';

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class NavigationConfig {
  static const Map<String, List<NavigationItem>> roleBasedNavigation = {
    'renter': [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        route: '/home',
      ),
      NavigationItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Wishlists',
        route: '/wishlists',
      ),

      NavigationItem(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        label: 'My Rentals',
        route: '/rentals',
      ),
      NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        route: '/messages',
      ),
      NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: '/profile',
      ),
    ],
    'lender': [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        route: '/home',
      ),
      NavigationItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Calendar',
        route: '/calendar',
      ),

      NavigationItem(
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt,
        label: 'My Listings',
        route: '/my-listings',
      ),
      NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        route: '/messages',
      ),
      NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: '/profile',
      ),
    ],
    'driver': [
      NavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/driver-dashboard',
      ),
      NavigationItem(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Jobs',
        route: '/driver-jobs',
      ),

      NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Messages',
        route: '/messages',
      ),
      NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: '/profile',
      ),
    ],
  };

  static List<NavigationItem> getNavigationForRole(String role) {
    return roleBasedNavigation[role] ?? roleBasedNavigation['renter']!;
  }
}