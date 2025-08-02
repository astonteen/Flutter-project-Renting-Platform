import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/router/app_router.dart';
import 'package:rent_ease/core/config/environment_config.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/theme/app_theme.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/auth/data/repositories/auth_repository.dart';
import 'package:rent_ease/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rent_ease/features/home/data/repositories/home_repository.dart';
import 'package:rent_ease/features/home/presentation/bloc/home_bloc.dart';
import 'package:rent_ease/features/rental/presentation/bloc/booking_bloc.dart';
import 'package:rent_ease/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';
import 'package:rent_ease/features/delivery/data/repositories/delivery_repository.dart';
import 'package:rent_ease/features/messages/presentation/bloc/messages_bloc.dart';
import 'package:rent_ease/features/messages/presentation/cubit/messages_cubit.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/profile/presentation/bloc/profile_bloc.dart';

import 'package:rent_ease/core/services/notification_service.dart';
import 'package:rent_ease/core/services/delivery_scheduling_service.dart';
import 'package:rent_ease/core/services/app_rating_service.dart';
import 'package:rent_ease/core/services/app_navigation_service.dart';
import 'package:rent_ease/features/reviews/presentation/bloc/rating_prompt_bloc.dart';
import 'package:rent_ease/features/reviews/presentation/widgets/rate_rental_sheet.dart';
import 'package:rent_ease/features/profile/data/repositories/profile_repository.dart';
import 'package:rent_ease/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:rent_ease/features/home/data/repositories/lender_repository.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/features/booking/presentation/bloc/booking_management_bloc.dart';
import 'package:rent_ease/features/booking/data/repositories/booking_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize image cache to prevent buffer overflow
  PaintingBinding.instance.imageCache.maximumSize =
      100; // Reduce from default 1000
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      50 << 20; // 50MB instead of 100MB

  // Initialize service locator
  setupServiceLocator();

  // Initialize environment configuration
  try {
    await EnvironmentConfig.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error loading environment configuration: $e');
    }
  }

  // Initialize Supabase with environment configuration
  try {
    await SupabaseService.initialize(
      supabaseUrl: EnvironmentConfig.dbSupabaseUrl,
      supabaseAnonKey: EnvironmentConfig.dbSupabaseAnonKey,
      timeoutSeconds: EnvironmentConfig.apiTimeoutSeconds,
    );

    // Storage buckets are created via migrations, no need to create them programmatically
    if (kDebugMode && SupabaseService.isInitialized) {
      debugPrint(
          '✅ Supabase initialized - storage buckets should exist via migrations');
    }

    // Initialize notification services (deferred to avoid blocking main thread)
    Future.microtask(() async {
      try {
        await NotificationService.initialize();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error initializing notification services: $e');
        }
      }
    });

    // Initialize delivery scheduling service (deferred to avoid blocking main thread)
    Future.microtask(() {
      try {
        DeliverySchedulingService.startScheduling();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error initializing delivery scheduling service: $e');
        }
      }
    });

    // Initialize rating service (deferred to avoid blocking main thread)
    Future.microtask(() async {
      try {
        await AppRatingService.initialize();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error initializing rating service: $e');
        }
      }
    });
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error during initialization: $e');
    }
    // Continue with app launch even if services fail
  }

  runApp(const RentEaseApp());
}

class RentEaseApp extends StatelessWidget {
  const RentEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (context) => HomeRepository(),
        ),
        RepositoryProvider<DeliveryRepository>(
          create: (context) => SupabaseDeliveryRepository(),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(),
        ),
        RepositoryProvider<LenderRepository>(
          create: (context) => LenderRepository(),
        ),
        RepositoryProvider<BookingRepository>(
          create: (context) => BookingRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              homeRepository: context.read<HomeRepository>(),
            ),
          ),
          BlocProvider<BookingBloc>(
            create: (context) => BookingBloc(),
          ),
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc(),
          ),
          BlocProvider<DeliveryBloc>(
            create: (context) {
              final repo = context.read<DeliveryRepository>();
              final bloc = DeliveryBloc(repo);
              return bloc;
            },
          ),
          BlocProvider<MessagesBloc>(
            create: (context) => MessagesBloc(),
          ),
          BlocProvider<ListingBloc>(
            create: (context) => ListingBloc(),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(),
          ),
          BlocProvider<WishlistBloc>(
            create: (context) => getIt<WishlistBloc>(),
            lazy: true,
          ),
          BlocProvider<LenderBloc>(
            create: (context) => LenderBloc(
              lenderRepository: context.read<LenderRepository>(),
            ),
          ),
          BlocProvider<MessagesCubit>(
            create: (context) => MessagesCubit(),
          ),
          BlocProvider<BookingManagementBloc>(
            create: (context) => BookingManagementBloc(
              repository: context.read<BookingRepository>(),
            ),
          ),
          BlocProvider<RatingPromptBloc>(
            create: (context) =>
                RatingPromptBloc()..add(const StartListeningForRatingPrompts()),
          ),
        ],
        child: const GlobalRatingListener(),
      ),
    );
  }
}

/// Global listener for rating prompts and auth state that wraps the entire app
class GlobalRatingListener extends StatelessWidget {
  const GlobalRatingListener({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RatingPromptBloc, RatingPromptState>(
          listener: (context, state) {
            if (state is RatingPromptVisible) {
              // Show rating bottom sheet
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                isDismissible: true,
                enableDrag: true,
                builder: (context) => RateRentalSheet(
                  promptData: state.promptData,
                ),
              );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is PasswordRecoveryInProgress) {
              debugPrint(
                  'Password recovery in progress - navigating to reset screen');
              AppRouter.router.go('/reset-password');
            }
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          // Set navigation context for the AppNavigationService
          AppNavigationService.setContext(context);

          return MaterialApp.router(
            title: 'RentEase',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
