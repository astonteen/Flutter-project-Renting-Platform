import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../home/data/models/rental_item_model.dart';
import '../../../home/data/repositories/home_repository.dart';

// Events
abstract class ItemDetailsEvent extends Equatable {
  const ItemDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadItemDetails extends ItemDetailsEvent {
  final String itemId;

  const LoadItemDetails(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class RefreshItemDetails extends ItemDetailsEvent {
  final String itemId;

  const RefreshItemDetails(this.itemId);

  @override
  List<Object> get props => [itemId];
}

// States
abstract class ItemDetailsState extends Equatable {
  const ItemDetailsState();

  @override
  List<Object?> get props => [];
}

class ItemDetailsInitial extends ItemDetailsState {}

class ItemDetailsLoading extends ItemDetailsState {}

class ItemDetailsLoaded extends ItemDetailsState {
  final RentalItemModel item;

  const ItemDetailsLoaded(this.item);

  @override
  List<Object?> get props => [item];
}

class ItemDetailsError extends ItemDetailsState {
  final String message;

  const ItemDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ItemDetailsBloc extends Bloc<ItemDetailsEvent, ItemDetailsState> {
  final HomeRepository homeRepository;

  ItemDetailsBloc({
    required this.homeRepository,
  }) : super(ItemDetailsInitial()) {
    on<LoadItemDetails>(_onLoadItemDetails);
    on<RefreshItemDetails>(_onRefreshItemDetails);
  }

  Future<void> _onLoadItemDetails(
    LoadItemDetails event,
    Emitter<ItemDetailsState> emit,
  ) async {
    emit(ItemDetailsLoading());
    await _loadItemDetails(event.itemId, emit);
  }

  Future<void> _onRefreshItemDetails(
    RefreshItemDetails event,
    Emitter<ItemDetailsState> emit,
  ) async {
    await _loadItemDetails(event.itemId, emit);
  }

  Future<void> _loadItemDetails(
    String itemId,
    Emitter<ItemDetailsState> emit,
  ) async {
    try {
      final item = await homeRepository.getItemDetails(itemId);
      if (item != null) {
        emit(ItemDetailsLoaded(item));
      } else {
        emit(const ItemDetailsError('Item not found'));
      }
    } catch (e) {
      emit(ItemDetailsError('Failed to load item details: ${e.toString()}'));
    }
  }
}
