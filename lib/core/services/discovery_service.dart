import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryService {
  static final DiscoveryService _instance = DiscoveryService._internal();
  factory DiscoveryService() => _instance;
  DiscoveryService._internal();

  static const String _locationPermissionKey = 'location_permission_requested';
  static const String _lastKnownLocationKey = 'last_known_location';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _viewHistoryKey = 'view_history';

  Position? _currentPosition;
  List<String> _viewHistory = [];
  final Map<String, double> _categoryPreferences = {};
  Timer? _locationUpdateTimer;

  bool _isLocationEnabled = false;
  bool _hasLocationPermission = false;

  // Mock data for demonstration
  final List<TrendingItem> _trendingItems = [
    TrendingItem(
      id: '1',
      title: 'iPhone 14 Pro',
      category: 'Electronics',
      trendScore: 95,
      priceRange: '\$50-80/day',
      imageUrl: 'https://example.com/iphone14.jpg',
      location: const LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        address: 'San Francisco, CA',
      ),
    ),
    TrendingItem(
      id: '2',
      title: 'MacBook Pro M2',
      category: 'Electronics',
      trendScore: 90,
      priceRange: '\$80-120/day',
      imageUrl: 'https://example.com/macbook.jpg',
      location: const LocationData(
        latitude: 37.7849,
        longitude: -122.4094,
        address: 'San Francisco, CA',
      ),
    ),
    TrendingItem(
      id: '3',
      title: 'Canon EOS R5',
      category: 'Photography',
      trendScore: 85,
      priceRange: '\$100-150/day',
      imageUrl: 'https://example.com/canon.jpg',
      location: const LocationData(
        latitude: 37.7649,
        longitude: -122.4294,
        address: 'San Francisco, CA',
      ),
    ),
  ];

  final List<String> _popularCategories = [
    'Electronics',
    'Photography',
    'Tools & Equipment',
    'Sports & Outdoors',
    'Furniture',
    'Vehicles',
    'Music & Instruments',
    'Kitchen & Appliances',
  ];

  // Initialize discovery service
  Future<void> initialize() async {
    await _loadUserPreferences();
    await _loadViewHistory();
    await _checkLocationPermission();
    _startLocationUpdates();
  }

  // Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_userPreferencesKey);
      if (prefsJson != null) {
        // Parse and load preferences
        debugPrint('Loaded user preferences');
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  // Load view history from storage
  Future<void> _loadViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _viewHistory = prefs.getStringList(_viewHistoryKey) ?? [];
    } catch (e) {
      debugPrint('Error loading view history: $e');
    }
  }

  // Check and request location permission
  Future<void> _checkLocationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedBefore = prefs.getBool(_locationPermissionKey) ?? false;

      // Check if location services are enabled
      _isLocationEnabled = await Geolocator.isLocationServiceEnabled();

      if (!_isLocationEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (!hasRequestedBefore) {
          permission = await Geolocator.requestPermission();
          await prefs.setBool(_locationPermissionKey, true);
        }
      }

      _hasLocationPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (_hasLocationPermission) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      if (!_hasLocationPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save last known location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastKnownLocationKey,
          '${_currentPosition!.latitude},${_currentPosition!.longitude}');

      debugPrint(
          'Current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  // Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_hasLocationPermission) {
        _getCurrentLocation();
      }
    });
  }

  // Get nearby items based on current location
  Future<List<NearbyItem>> getNearbyItems({
    double radiusKm = 10.0,
    String? category,
    int limit = 20,
  }) async {
    if (_currentPosition == null) {
      return _getMockNearbyItems(limit: limit, category: category);
    }

    // In a real app, this would query the database with location filters
    return _getMockNearbyItems(limit: limit, category: category);
  }

  // Get mock nearby items for demonstration
  List<NearbyItem> _getMockNearbyItems({
    int limit = 20,
    String? category,
  }) {
    final random = Random();
    final items = <NearbyItem>[];

    for (int i = 0; i < limit; i++) {
      final itemCategory = category ??
          _popularCategories[random.nextInt(_popularCategories.length)];
      final distance = random.nextDouble() * 10; // 0-10 km

      items.add(NearbyItem(
        id: 'nearby_$i',
        title: '$itemCategory Item ${i + 1}',
        category: itemCategory,
        pricePerDay: 20 + random.nextDouble() * 80,
        distance: distance,
        rating: 3.5 + random.nextDouble() * 1.5,
        imageUrl: 'https://example.com/item_$i.jpg',
        location: LocationData(
          latitude: (_currentPosition?.latitude ?? 37.7749) +
              (random.nextDouble() - 0.5) * 0.1,
          longitude: (_currentPosition?.longitude ?? -122.4194) +
              (random.nextDouble() - 0.5) * 0.1,
          address: 'Location ${i + 1}',
        ),
        isAvailable: random.nextBool(),
        ownerId: 'owner_$i',
      ));
    }

    // Sort by distance
    items.sort((a, b) => a.distance.compareTo(b.distance));
    return items;
  }

  // Get trending items
  List<TrendingItem> getTrendingItems({int limit = 10}) {
    final sortedItems = List<TrendingItem>.from(_trendingItems);
    sortedItems.sort((a, b) => b.trendScore.compareTo(a.trendScore));
    return sortedItems.take(limit).toList();
  }

  // Get personalized recommendations
  Future<List<RecommendedItem>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    // Analyze user preferences based on view history
    _analyzeUserPreferences();

    // Generate recommendations based on preferences
    final recommendations = <RecommendedItem>[];
    final random = Random();

    for (final category in _categoryPreferences.keys) {
      final preference = _categoryPreferences[category]!;
      if (preference > 0.3) {
        // Only recommend categories with decent preference
        recommendations.add(RecommendedItem(
          id: 'rec_${category.toLowerCase()}',
          title: 'Recommended $category',
          category: category,
          recommendationScore: preference,
          reason: 'Based on your viewing history',
          priceRange:
              '\$${20 + random.nextInt(80)}-${50 + random.nextInt(100)}/day',
          imageUrl: 'https://example.com/${category.toLowerCase()}.jpg',
          estimatedInterest: preference,
        ));
      }
    }

    // Sort by recommendation score
    recommendations
        .sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
    return recommendations.take(limit).toList();
  }

  // Analyze user preferences from view history
  void _analyzeUserPreferences() {
    _categoryPreferences.clear();

    for (final item in _viewHistory) {
      // In a real app, this would extract category from item data
      // For demo, we'll simulate category extraction
      for (final category in _popularCategories) {
        if (item.toLowerCase().contains(category.toLowerCase())) {
          _categoryPreferences[category] =
              (_categoryPreferences[category] ?? 0) + 0.1;
        }
      }
    }

    // Normalize preferences
    final maxPreference =
        _categoryPreferences.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxPreference > 0) {
      _categoryPreferences.updateAll((key, value) => value / maxPreference);
    }
  }

  // Track item view for recommendations
  Future<void> trackItemView(String itemId, String category) async {
    _viewHistory.insert(0, itemId);

    // Limit history size
    if (_viewHistory.length > 100) {
      _viewHistory = _viewHistory.take(100).toList();
    }

    // Save to storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_viewHistoryKey, _viewHistory);
    } catch (e) {
      debugPrint('Error saving view history: $e');
    }
  }

  // Get popular categories
  List<String> getPopularCategories() {
    return List.unmodifiable(_popularCategories);
  }

  // Get featured collections
  List<FeaturedCollection> getFeaturedCollections() {
    return [
      FeaturedCollection(
        id: 'tech_essentials',
        title: 'Tech Essentials',
        description: 'Latest gadgets and electronics',
        imageUrl: 'https://example.com/tech_collection.jpg',
        itemCount: 25,
        categories: ['Electronics', 'Photography'],
      ),
      FeaturedCollection(
        id: 'outdoor_adventures',
        title: 'Outdoor Adventures',
        description: 'Gear for your next adventure',
        imageUrl: 'https://example.com/outdoor_collection.jpg',
        itemCount: 18,
        categories: ['Sports & Outdoors', 'Camping'],
      ),
      FeaturedCollection(
        id: 'home_improvement',
        title: 'Home Improvement',
        description: 'Tools and equipment for DIY projects',
        imageUrl: 'https://example.com/tools_collection.jpg',
        itemCount: 32,
        categories: ['Tools & Equipment', 'Furniture'],
      ),
    ];
  }

  // Calculate distance between two locations
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Get current location data
  LocationData? get currentLocation {
    if (_currentPosition == null) return null;
    return LocationData(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      address: 'Current Location',
    );
  }

  // Check if location services are available
  bool get isLocationAvailable => _hasLocationPermission && _isLocationEnabled;

  // Dispose resources
  void dispose() {
    _locationUpdateTimer?.cancel();
  }
}

// Data models
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class NearbyItem {
  final String id;
  final String title;
  final String category;
  final double pricePerDay;
  final double distance;
  final double rating;
  final String imageUrl;
  final LocationData location;
  final bool isAvailable;
  final String ownerId;

  NearbyItem({
    required this.id,
    required this.title,
    required this.category,
    required this.pricePerDay,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.location,
    required this.isAvailable,
    required this.ownerId,
  });
}

class TrendingItem {
  final String id;
  final String title;
  final String category;
  final int trendScore;
  final String priceRange;
  final String imageUrl;
  final LocationData location;

  TrendingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.trendScore,
    required this.priceRange,
    required this.imageUrl,
    required this.location,
  });
}

class RecommendedItem {
  final String id;
  final String title;
  final String category;
  final double recommendationScore;
  final String reason;
  final String priceRange;
  final String imageUrl;
  final double estimatedInterest;

  RecommendedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.recommendationScore,
    required this.reason,
    required this.priceRange,
    required this.imageUrl,
    required this.estimatedInterest,
  });
}

class FeaturedCollection {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int itemCount;
  final List<String> categories;

  FeaturedCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.itemCount,
    required this.categories,
  });
}
