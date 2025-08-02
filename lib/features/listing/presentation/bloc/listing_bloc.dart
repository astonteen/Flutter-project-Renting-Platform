import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/features/listing/data/repositories/listing_repository.dart';

// Events
abstract class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object?> get props => [];
}

class CreateListing extends ListingEvent {
  final String name;
  final String description;
  final String categoryId;
  final double pricePerDay;
  final double pricePerWeek;
  final double pricePerMonth;
  final double securityDeposit;
  final List<String> imageUrls;
  final String condition;
  final String location;
  final List<String> features;
  final bool requiresDelivery;
  final double? deliveryFee;
  final String? deliveryInstructions;
  final int quantity;
  final int blockingDays;
  final String? blockingReason;

  const CreateListing({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.pricePerMonth,
    required this.securityDeposit,
    required this.imageUrls,
    required this.condition,
    required this.location,
    required this.features,
    this.requiresDelivery = false,
    this.deliveryFee,
    this.deliveryInstructions,
    this.quantity = 1,
    this.blockingDays = 2,
    this.blockingReason,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        categoryId,
        pricePerDay,
        pricePerWeek,
        pricePerMonth,
        securityDeposit,
        imageUrls,
        condition,
        location,
        features,
        requiresDelivery,
        deliveryFee,
        deliveryInstructions,
        quantity,
        blockingDays,
        blockingReason,
      ];
}

class LoadUserListings extends ListingEvent {
  final String userId;

  const LoadUserListings(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadMyListings extends ListingEvent {}

class LoadAvailableListings extends ListingEvent {
  final String? categoryId;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const LoadAvailableListings({
    this.categoryId,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [categoryId, searchQuery, limit, offset];
}

class LoadFeaturedListings extends ListingEvent {
  final int limit;

  const LoadFeaturedListings({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class UpdateListing extends ListingEvent {
  final String listingId;
  final Map<String, dynamic> updates;

  const UpdateListing({
    required this.listingId,
    required this.updates,
  });

  @override
  List<Object?> get props => [listingId, updates];
}

class DeleteListing extends ListingEvent {
  final String listingId;

  const DeleteListing(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class ToggleListingAvailability extends ListingEvent {
  final String listingId;
  final bool isAvailable;

  const ToggleListingAvailability({
    required this.listingId,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [listingId, isAvailable];
}

// States
abstract class ListingState extends Equatable {
  const ListingState();

  @override
  List<Object?> get props => [];
}

class ListingInitial extends ListingState {}

class ListingLoading extends ListingState {}

class ListingCreated extends ListingState {
  final ListingModel listing;

  const ListingCreated(this.listing);

  @override
  List<Object?> get props => [listing];
}

class ListingsLoaded extends ListingState {
  final List<ListingModel> listings;

  const ListingsLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class MyListingsLoaded extends ListingState {
  final List<ListingModel> listings;

  const MyListingsLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class AvailableListingsLoaded extends ListingState {
  final List<ListingModel> listings;

  const AvailableListingsLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class FeaturedListingsLoaded extends ListingState {
  final List<ListingModel> listings;

  const FeaturedListingsLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

class ListingUpdated extends ListingState {
  final ListingModel listing;

  const ListingUpdated(this.listing);

  @override
  List<Object?> get props => [listing];
}

class ListingDeleted extends ListingState {
  final String listingId;

  const ListingDeleted(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class ListingError extends ListingState {
  final String message;

  const ListingError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ListingBloc extends Bloc<ListingEvent, ListingState> {
  final ListingRepository _repository;

  ListingBloc({ListingRepository? repository})
      : _repository = repository ?? ListingRepository(),
        super(ListingInitial()) {
    on<CreateListing>(_onCreateListing);
    on<LoadUserListings>(_onLoadUserListings);
    on<LoadMyListings>(_onLoadMyListings);
    on<LoadAvailableListings>(_onLoadAvailableListings);
    on<LoadFeaturedListings>(_onLoadFeaturedListings);
    on<UpdateListing>(_onUpdateListing);
    on<DeleteListing>(_onDeleteListing);
    on<ToggleListingAvailability>(_onToggleListingAvailability);
  }

  Future<void> _onCreateListing(
    CreateListing event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final listing = ListingModel(
        id: '', // Will be generated by Supabase
        ownerId: '', // Will be set by repository
        name: event.name,
        description: event.description,
        categoryId: event.categoryId,
        pricePerDay: event.pricePerDay,
        pricePerWeek: event.pricePerWeek,
        pricePerMonth: event.pricePerMonth,
        securityDeposit: event.securityDeposit,
        imageUrls: event.imageUrls,
        primaryImageUrl:
            event.imageUrls.isNotEmpty ? event.imageUrls.first : '',
        condition: event.condition,
        isAvailable: true,
        location: event.location,
        features: event.features,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        requiresDelivery: event.requiresDelivery,
        deliveryFee: event.deliveryFee,
        deliveryInstructions: event.deliveryInstructions,
        quantity: event.quantity,
        blockingDays: event.blockingDays,
        blockingReason: event.blockingReason,
      );

      final createdListing = await _repository.createListing(listing);
      emit(ListingCreated(createdListing));
    } catch (e) {
      emit(ListingError('Failed to create listing: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserListings(
    LoadUserListings event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      // For now, load available listings since we don't have user-specific filtering
      final listings = await _repository.getAvailableListings(limit: 20);
      emit(ListingsLoaded(listings));
    } catch (e) {
      emit(ListingError('Failed to load listings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMyListings(
    LoadMyListings event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final listings = await _repository.getMyListings();
      emit(MyListingsLoaded(listings));
    } catch (e) {
      emit(ListingError('Failed to load my listings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAvailableListings(
    LoadAvailableListings event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final listings = await _repository.getAvailableListings(
        categoryId: event.categoryId,
        searchQuery: event.searchQuery,
        limit: event.limit,
        offset: event.offset,
      );
      emit(AvailableListingsLoaded(listings));
    } catch (e) {
      emit(ListingError('Failed to load available listings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadFeaturedListings(
    LoadFeaturedListings event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final listings =
          await _repository.getFeaturedListings(limit: event.limit);
      emit(FeaturedListingsLoaded(listings));
    } catch (e) {
      emit(ListingError('Failed to load featured listings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateListing(
    UpdateListing event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final updatedListing = await _repository.updateListing(
        event.listingId,
        event.updates,
      );
      emit(ListingUpdated(updatedListing));
    } catch (e) {
      emit(ListingError('Failed to update listing: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteListing(
    DeleteListing event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      await _repository.deleteListing(event.listingId);
      emit(ListingDeleted(event.listingId));
    } catch (e) {
      emit(ListingError('Failed to delete listing: ${e.toString()}'));
    }
  }

  Future<void> _onToggleListingAvailability(
    ToggleListingAvailability event,
    Emitter<ListingState> emit,
  ) async {
    emit(ListingLoading());

    try {
      final updatedListing = await _repository.toggleAvailability(
        event.listingId,
        event.isAvailable,
      );
      emit(ListingUpdated(updatedListing));
    } catch (e) {
      emit(ListingError('Failed to toggle availability: ${e.toString()}'));
    }
  }
}
