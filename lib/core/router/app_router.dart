import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/services/auth_guard_service.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/auth/presentation/screens/login_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/register_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/splash_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:rent_ease/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:rent_ease/features/home/presentation/screens/home_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/delivery_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/driver_profile_screen.dart';
import 'package:rent_ease/features/messages/presentation/screens/messages_screen.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/features/messages/data/models/conversation_model.dart';
import 'package:rent_ease/features/profile/presentation/screens/profile_screen.dart';
import 'package:rent_ease/features/rentals/presentation/screens/rentals_screen.dart';
import 'package:rent_ease/features/home/presentation/screens/main_screen.dart';
import 'package:rent_ease/features/rental/presentation/screens/item_details_screen.dart';
import 'package:rent_ease/features/listing/presentation/screens/create_listing_screen.dart';
import 'package:rent_ease/features/listing/presentation/screens/my_listings_screen.dart';
import 'package:rent_ease/features/booking/presentation/screens/booking_management_screen.dart';
import 'package:rent_ease/features/booking/presentation/bloc/booking_management_bloc.dart';
import 'package:rent_ease/features/booking/data/repositories/booking_repository.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';

import 'package:rent_ease/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/notifications_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/account_settings_screen.dart';

import 'package:rent_ease/features/delivery/presentation/screens/driver_dashboard_entry.dart';
import 'package:rent_ease/features/delivery/presentation/screens/delivery_tracking_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/earnings_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/settings_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/help_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/about_screen.dart';
import 'package:rent_ease/features/listing/presentation/screens/refactored_lender_calendar_screen.dart';
import 'package:rent_ease/features/listing/presentation/bloc/calendar_availability_bloc.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/listing/data/repositories/listing_repository.dart';
import 'package:rent_ease/features/services/presentation/screens/services_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/driver_jobs_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/delivery_address_update_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/driver_registration_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/lender_delivery_approval_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/return_delivery_request_screen.dart';
import 'package:rent_ease/features/delivery/presentation/screens/unified_delivery_tracking_screen.dart';
import 'package:rent_ease/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/saved_addresses_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/add_edit_address_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/address_selection_screen.dart';
import 'package:rent_ease/features/profile/presentation/screens/connections_screen.dart';
import 'package:rent_ease/features/booking/presentation/screens/booking_list_screen.dart';
import 'package:rent_ease/features/booking/presentation/screens/booking_details_screen.dart';
import 'package:rent_ease/features/listing/presentation/screens/all_listings_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Auth flow
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'renter';
          return ProfileSetupScreen(selectedRole: role);
        },
      ),

      // Item details (full screen)
      GoRoute(
        path: '/item/:itemId',
        name: 'item-details',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return ItemDetailsScreen(itemId: itemId);
        },
      ),

      // All listings screen (full screen)
      GoRoute(
        path: '/all-listings',
        name: 'all-listings',
        builder: (context, state) {
          final sectionType = state.uri.queryParameters['section'];
          return AllListingsScreen(sectionType: sectionType);
        },
      ),

      // Booking management (full screen)
      GoRoute(
        path: '/booking-management/:listingId',
        name: 'booking-management',
        builder: (context, state) {
          final listing = state.extra as ListingModel?;

          if (listing == null) {
            // If no listing object passed, we need to handle this case
            // For now, redirect back or show error
            return const Scaffold(
              body: Center(
                child: Text('Listing not found'),
              ),
            );
          }

          return BlocProvider(
            create: (context) => BookingManagementBloc(
              repository: getIt<BookingRepository>(),
            ),
            child: BookingManagementScreen(listing: listing),
          );
        },
      ),

      // Delivery screen (full screen)
      GoRoute(
        path: '/delivery-full',
        name: 'delivery-full',
        builder: (context, state) => const DeliveryScreen(),
      ),

      // Delivery tracking for individual orders
      GoRoute(
        path: '/delivery/:deliveryId',
        name: 'delivery-tracking',
        builder: (context, state) {
          final deliveryId = state.pathParameters['deliveryId']!;
          return DeliveryTrackingScreen(deliveryId: deliveryId);
        },
      ),

      // Delivery address update
      GoRoute(
        path: '/delivery-address/:rentalId',
        name: 'delivery-address-update',
        builder: (context, state) {
          final rentalId = state.pathParameters['rentalId']!;
          return DeliveryAddressUpdateScreen(rentalId: rentalId);
        },
      ),

      // Lender delivery approval
      GoRoute(
        path: '/lender-delivery-approval/:deliveryId',
        name: 'lender-delivery-approval',
        builder: (context, state) {
          final deliveryId = state.pathParameters['deliveryId']!;
          return LenderDeliveryApprovalScreen(deliveryId: deliveryId);
        },
      ),

      // Unified delivery tracking
      GoRoute(
        path: '/unified-tracking',
        name: 'unified-tracking',
        builder: (context, state) => const UnifiedDeliveryTrackingScreen(),
      ),

      // Driver profile screen (full screen)
      GoRoute(
        path: '/driver-profile',
        name: 'driver-profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),

      // Driver registration screen (full screen)
      GoRoute(
        path: '/driver-registration',
        name: 'driver-registration',
        builder: (context, state) => const DriverRegistrationScreen(),
      ),

      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      GoRoute(
        path: '/account-settings',
        name: 'account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),

      // Saved addresses routes
      GoRoute(
        path: '/saved-addresses',
        name: 'saved-addresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: '/saved-addresses/add',
        name: 'add-address',
        builder: (context, state) => const AddEditAddressScreen(),
      ),
      GoRoute(
        path: '/saved-addresses/edit/:addressId',
        name: 'edit-address',
        builder: (context, state) {
          final addressId = state.pathParameters['addressId']!;
          return AddEditAddressScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/address-selection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddressSelectionScreen(
            selectedAddress: extra?['selectedAddress'],
            onAddressSelected: extra?['onAddressSelected'],
          );
        },
      ),

      // Booking routes
      GoRoute(
        path: '/bookings',
        name: 'booking-list',
        builder: (context, state) => const BookingListScreen(),
      ),
      GoRoute(
        path: '/booking/:bookingId',
        name: 'booking-details',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingDetailsScreen(bookingId: bookingId);
        },
      ),

      // Message conversation route - REMOVED: Now using direct Navigator calls with fullscreenDialog
      // GoRoute(
      //   path: '/messages/:conversationId',
      //   name: 'message-conversation',
      //   builder: (context, state) {
      //     final conversationId = state.pathParameters['conversationId']!;
      //     return BlocProvider(
      //       create: (context) => MessagesBloc(
      //         messagesRepository: getIt<MessagesRepository>(),
      //       ),
      //       child: ConversationScreen(conversationId: conversationId),
      //     );
      //   },
      // ),

      // Hamburger menu screens
      GoRoute(
        path: '/earnings',
        name: 'earnings',
        builder: (context, state) => const EarningsScreen(),
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),

      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Connections screen (full screen)
      GoRoute(
        path: '/connections',
        name: 'connections',
        builder: (context, state) => const ConnectionsScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: const [
              // Add nested routes for home here
            ],
          ),

          // Wishlists tab
          GoRoute(
            path: '/wishlists',
            name: 'wishlists',
            builder: (context, state) => const WishlistScreen(),
            routes: const [
              // Add nested routes for wishlists here
            ],
          ),

          // Rentals tab
          GoRoute(
            path: '/rentals',
            name: 'rentals',
            builder: (context, state) => const RentalsScreen(),
            routes: const [
              // Add nested routes for rentals here
            ],
          ),

          // Create Listing tab (was Delivery)
          GoRoute(
            path: '/create-listing',
            name: 'create-listing',
            builder: (context, state) => const CreateListingScreen(),
            routes: const [
              // Add nested routes for create listing here
            ],
          ),

          // Messages tab
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
            routes: const [
              // Add nested routes for messages here
            ],
          ),

          // Services tab
          GoRoute(
            path: '/services',
            name: 'services',
            builder: (context, state) => const ServicesScreen(),
            routes: const [
              // Add nested routes for services here
            ],
          ),

          // Profile tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: const [
              // Add nested routes for profile here
            ],
          ),

          // Track Orders (within shell to preserve bottom navigation)
          GoRoute(
            path: '/track-orders',
            name: 'track-orders',
            builder: (context, state) => const UnifiedDeliveryTrackingScreen(),
          ),

          // Return delivery request (within shell to preserve bottom navigation)
          GoRoute(
            path: '/return-delivery-request',
            name: 'return-delivery-request',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final originalDeliveryId = extra?['originalDeliveryId'] ?? '';
              final itemName = extra?['itemName'] ?? '';
              return ReturnDeliveryRequestScreen(
                originalDeliveryId: originalDeliveryId,
                itemName: itemName,
              );
            },
          ),

          // Calendar tab (for lender mode)
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ListingBloc(
                    repository: getIt<ListingRepository>(),
                  ),
                ),
                BlocProvider(
                  create: (context) => CalendarAvailabilityBloc(),
                ),
              ],
              child: const RefactoredLenderCalendarScreen(),
            ),
            routes: const [
              // Add nested routes for calendar here
            ],
          ),
          GoRoute(
            path: '/driver-dashboard',
            name: 'driver-dashboard',
            builder: (context, state) {
              final showRoute =
                  state.uri.queryParameters['showRoute'] == 'true';
              final jobId = state.uri.queryParameters['jobId'];

              Map<String, dynamic>? routeData;
              if (showRoute && jobId != null) {
                routeData = {
                  'showRoute': true,
                  'jobId': jobId,
                };
              }

              return DriverDashboardEntry(routeData: routeData);
            },
            routes: const [
              // Add nested routes for dashboard here
            ],
          ),
          GoRoute(
            path: '/driver-jobs',
            name: 'driver-jobs',
            builder: (context, state) => const DriverJobsScreen(),
            routes: const [
              // Add nested routes for jobs here
            ],
          ),

          // My Listings (within shell to preserve bottom navigation)
          GoRoute(
            path: '/my-listings',
            name: 'my-listings',
            builder: (context, state) => const MyListingsScreen(),
            routes: const [
              // Add nested routes for my listings here
            ],
          ),
        ],
      ),
    ],

    // Authentication guard with proper redirect logic
    redirect: (BuildContext context, GoRouterState state) async {
      debugPrint('Router redirect called for: ${state.uri.path}');

      try {
        final redirectPath = await AuthGuardService.getRedirectRoute(
          state.uri.path,
        );

        if (redirectPath != null) {
          debugPrint('Redirecting to: $redirectPath');
        }

        return redirectPath;
      } catch (e) {
        debugPrint('Error in auth guard: $e');
        // On error, allow navigation to continue
        return null;
      }
    },
  );
}

// Helper widget to load conversation and display ChatScreen
class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late MessagesRepository _repository;
  ConversationModel? _conversation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<MessagesRepository>();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final conversation =
          await _repository.getConversation(widget.conversationId);

      if (mounted) {
        setState(() {
          _conversation = conversation;
          _isLoading = false;
          if (conversation == null) {
            _error = 'Conversation not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading conversation: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _conversation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Message'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Conversation not found',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return ChatScreen(conversation: _conversation!);
  }
}
