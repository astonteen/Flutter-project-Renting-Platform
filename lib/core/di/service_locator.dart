import 'package:get_it/get_it.dart';
import 'package:rent_ease/core/services/navigation_state_service.dart';
import 'package:rent_ease/core/services/role_switching_service.dart';
import 'package:rent_ease/features/auth/data/repositories/auth_repository.dart';
import 'package:rent_ease/features/messages/data/repositories/messages_repository.dart';
import 'package:rent_ease/features/profile/data/repositories/profile_repository.dart';
import 'package:rent_ease/features/profile/data/repositories/saved_address_repository.dart';
import 'package:rent_ease/features/delivery/data/repositories/delivery_repository.dart';
import 'package:rent_ease/features/booking/data/repositories/booking_repository.dart';
import 'package:rent_ease/features/listing/data/repositories/listing_repository.dart';
import 'package:rent_ease/features/wishlist/data/repositories/wishlist_repository.dart';
import 'package:rent_ease/features/wishlist/data/repositories/viewed_items_repository.dart';
import 'package:rent_ease/features/home/data/repositories/home_repository.dart';
import 'package:rent_ease/features/wishlist/presentation/bloc/wishlist_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register repositories first
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<MessagesRepository>(() => MessagesRepository());
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  getIt.registerLazySingleton<SavedAddressRepository>(() => SavedAddressRepository());
  getIt.registerLazySingleton<DeliveryRepository>(
      () => SupabaseDeliveryRepository());
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepository());
  getIt.registerLazySingleton<ListingRepository>(() => ListingRepository());
  getIt.registerLazySingleton<WishlistRepository>(() => WishlistRepository());
  getIt.registerLazySingleton<HomeRepository>(() => HomeRepository());
  getIt.registerLazySingleton<ViewedItemsRepository>(
      () => ViewedItemsRepository());
  getIt.registerLazySingleton<WishlistBloc>(() => WishlistBloc());

  // Register services that depend on repositories
  getIt.registerLazySingleton<NavigationStateService>(
      () => NavigationStateService());
  getIt.registerLazySingleton<RoleSwitchingService>(
    () => RoleSwitchingService(getIt<ProfileRepository>()),
  );
}
