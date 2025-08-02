import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/features/home/data/models/category_model.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:rent_ease/features/home/data/repositories/home_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshHomeData extends HomeEvent {}

class SearchItems extends HomeEvent {
  final String query;

  const SearchItems(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadCategoryItems extends HomeEvent {
  final String categoryId;

  const LoadCategoryItems(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class InitializeSampleData extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<CategoryModel> categories;
  final List<RentalItemModel> featuredItems;
  final List<RentalItemModel> nearbyItems;

  const HomeLoaded({
    required this.categories,
    required this.featuredItems,
    required this.nearbyItems,
  });

  @override
  List<Object?> get props => [categories, featuredItems, nearbyItems];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class SearchLoading extends HomeState {}

class SearchResults extends HomeState {
  final List<RentalItemModel> results;
  final String query;

  const SearchResults({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

class CategoryItemsLoading extends HomeState {}

class CategoryItemsLoaded extends HomeState {
  final List<RentalItemModel> items;
  final String categoryId;

  const CategoryItemsLoaded({
    required this.items,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [items, categoryId];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;

  HomeBloc({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<SearchItems>(_onSearchItems);
    on<LoadCategoryItems>(_onLoadCategoryItems);
    on<InitializeSampleData>(_onInitializeSampleData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    // Check if Supabase is initialized
    if (!SupabaseService.isInitialized) {
      emit(const HomeError('Service unavailable'));
      return;
    }

    try {
      // Load all data in parallel
      final futures = await Future.wait([
        _homeRepository.getCategories(),
        _homeRepository.getFeaturedItems(limit: 5),
        _homeRepository.getNearbyItems(limit: 10),
      ]);

      final categories = futures[0] as List<CategoryModel>;
      final featuredItems = futures[1] as List<RentalItemModel>;
      final nearbyItems = futures[2] as List<RentalItemModel>;

      emit(HomeLoaded(
        categories: categories,
        featuredItems: featuredItems,
        nearbyItems: nearbyItems,
      ));
    } catch (e) {
      debugPrint('Error loading home data: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    // Don't show loading for refresh
    if (!SupabaseService.isInitialized) {
      emit(const HomeError('Service unavailable'));
      return;
    }

    try {
      final futures = await Future.wait([
        _homeRepository.getCategories(),
        _homeRepository.getFeaturedItems(limit: 5),
        _homeRepository.getNearbyItems(limit: 10),
      ]);

      final categories = futures[0] as List<CategoryModel>;
      final featuredItems = futures[1] as List<RentalItemModel>;
      final nearbyItems = futures[2] as List<RentalItemModel>;

      emit(HomeLoaded(
        categories: categories,
        featuredItems: featuredItems,
        nearbyItems: nearbyItems,
      ));
    } catch (e) {
      debugPrint('Error refreshing home data: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onSearchItems(
    SearchItems event,
    Emitter<HomeState> emit,
  ) async {
    emit(SearchLoading());

    if (!SupabaseService.isInitialized) {
      emit(const HomeError('Service unavailable'));
      return;
    }

    try {
      final results = await _homeRepository.searchItems(
        query: event.query,
        limit: 20,
      );

      emit(SearchResults(
        results: results,
        query: event.query,
      ));
    } catch (e) {
      debugPrint('Error searching items: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadCategoryItems(
    LoadCategoryItems event,
    Emitter<HomeState> emit,
  ) async {
    emit(CategoryItemsLoading());

    if (!SupabaseService.isInitialized) {
      emit(const HomeError('Service unavailable'));
      return;
    }

    try {
      final items = await _homeRepository.getItemsByCategory(
        categoryId: event.categoryId,
        limit: 20,
      );

      emit(CategoryItemsLoaded(
        items: items,
        categoryId: event.categoryId,
      ));
    } catch (e) {
      debugPrint('Error loading category items: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onInitializeSampleData(
    InitializeSampleData event,
    Emitter<HomeState> emit,
  ) async {
    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _homeRepository.insertSampleData();
      debugPrint('Sample data initialized');

      // Reload home data after initializing sample data
      add(LoadHomeData());
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }
}
