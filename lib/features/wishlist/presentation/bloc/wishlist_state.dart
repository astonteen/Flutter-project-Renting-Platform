import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object> get props => [];
}

class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

class WishlistLoaded extends WishlistState {
  final List<RentalItemModel> likedItems;
  final List<RentalItemModel> recentlyViewed;

  const WishlistLoaded({
    required this.likedItems,
    required this.recentlyViewed,
  });

  @override
  List<Object> get props => [likedItems, recentlyViewed];
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError({required this.message});

  @override
  List<Object> get props => [message];
}
