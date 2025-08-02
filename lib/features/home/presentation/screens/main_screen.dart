import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/services/navigation_state_service.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/core/config/navigation_config.dart';
import 'package:rent_ease/core/widgets/role_switching_menu.dart';
import 'package:rent_ease/core/di/service_locator.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late RoleSwitchingService _roleSwitchingService;
  List<NavigationItem> _currentNavItems = [];

  @override
  void initState() {
    super.initState();
    _roleSwitchingService = getIt<RoleSwitchingService>();
    _updateNavigationItems();
    _roleSwitchingService.addListener(_onRoleChanged);
  }

  @override
  void dispose() {
    _roleSwitchingService.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _updateNavigationItems();
            _updateCurrentIndex();
          });

          // Force navigation to the appropriate screen for the new role
          _navigateToRoleDefaultScreen();
        }
      });
    }
  }

  void _navigateToRoleDefaultScreen() {
    final currentLocation = GoRouterState.of(context).uri.path;
    final newNavItems = NavigationConfig.getNavigationForRole(
      _roleSwitchingService.activeRole,
    );

    // Check if current route is still valid for the new role
    final isCurrentRouteValid = newNavItems.any(
      (item) => currentLocation.startsWith(item.route),
    );

    // If current route is not valid for new role, navigate to first tab
    if (!isCurrentRouteValid && newNavItems.isNotEmpty) {
      context.go(newNavItems.first.route);
    }
  }

  void _updateNavigationItems() {
    _currentNavItems = NavigationConfig.getNavigationForRole(
      _roleSwitchingService.activeRole,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final String location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _currentNavItems.length; i++) {
      if (location.startsWith(_currentNavItems[i].route)) {
        setState(() {
          _currentIndex = i;
        });
        getIt<NavigationStateService>()
            .updateCurrentBottomNavRoute(_currentNavItems[i].route);
        break;
      }
    }
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      context.go(_currentNavItems[index].route);
    }
  }

  void _showRoleSwitchingMenu() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: RoleSwitchingMenu(
          onRoleChanged: () {
            // Navigation will be updated automatically via listener
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey('main_screen_${_roleSwitchingService.activeRole}'),
        child: widget.child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Check if it's the profile tab and handle long press
          if (index == _currentNavItems.length - 1) {
            _onItemTapped(index);
          } else {
            _onItemTapped(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ColorConstants.primaryColor,
        unselectedItemColor: ColorConstants.grey,
        items: _currentNavItems
            .asMap()
            .entries
            .map(
              (entry) => BottomNavigationBarItem(
                icon: entry.key == _currentNavItems.length - 1
                    ? GestureDetector(
                        onLongPress: _showRoleSwitchingMenu,
                        child: Stack(
                          children: [
                            Icon(entry.value.icon),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                      _roleSwitchingService.activeRole),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Icon(entry.value.icon),
                activeIcon: entry.key == _currentNavItems.length - 1
                    ? GestureDetector(
                        onLongPress: _showRoleSwitchingMenu,
                        child: Stack(
                          children: [
                            Icon(entry.value.activeIcon),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                      _roleSwitchingService.activeRole),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Icon(entry.value.activeIcon),
                label: entry.value.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'renter':
        return Colors.blue;
      case 'lender':
        return Colors.green;
      case 'driver':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
