import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/di/service_locator.dart';
import 'package:rent_ease/features/home/data/repositories/home_repository.dart';

import 'package:rent_ease/features/wishlist/data/repositories/viewed_items_repository.dart';
import 'package:rent_ease/features/wishlist/data/repositories/wishlist_repository.dart';
import 'package:rent_ease/features/wishlist/presentation/bloc/wishlist_event.dart';
import 'package:rent_ease/features/wishlist/presentation/bloc/wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc() : super(const WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
  }

  Future<void> _onLoadWishlist(
      LoadWishlist event, Emitter<WishlistState> emit) async {
    emit(const WishlistLoading());
    try {
      final likedIds = await getIt<WishlistRepository>().getWishlistItemIds();
      final viewedIds =
          await getIt<ViewedItemsRepository>().getRecentlyViewedItemIds();

      final likedItems = await getIt<HomeRepository>().getItemsByIds(likedIds);
      final viewedItems =
          await getIt<HomeRepository>().getItemsByIds(viewedIds);

      emit(WishlistLoaded(
        likedItems: likedItems,
        recentlyViewed: viewedItems,
      ));
    } catch (e) {
      emit(WishlistError(message: e.toString()));
    }
  }
}
