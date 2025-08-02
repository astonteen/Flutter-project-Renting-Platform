import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final ValueNotifier<bool> _isConnected = ValueNotifier(true);
  final ValueNotifier<ConnectivityResult> _connectionType =
      ValueNotifier(ConnectivityResult.wifi);

  bool get isConnected => _isConnected.value;
  ConnectivityResult get connectionType => _connectionType.value;

  ValueNotifier<bool> get isConnectedNotifier => _isConnected;
  ValueNotifier<ConnectivityResult> get connectionTypeNotifier =>
      _connectionType;

  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionType.value = result;
    _isConnected.value = result != ConnectivityResult.none;

    debugPrint(
        'Connectivity changed: ${result.name} (Connected: ${_isConnected.value})');
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }

  String getConnectionDescription() {
    switch (_connectionType.value) {
      case ConnectivityResult.wifi:
        return 'Connected via WiFi';
      case ConnectivityResult.mobile:
        return 'Connected via Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected via Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.none:
        return 'No internet connection';
      case ConnectivityResult.other:
        return 'Connected via Other';
    }
  }

  bool get isOnMobileData => _connectionType.value == ConnectivityResult.mobile;
  bool get isOnWifi => _connectionType.value == ConnectivityResult.wifi;
  bool get isOnLowBandwidth => isOnMobileData;

  void dispose() {
    _connectivitySubscription?.cancel();
    _isConnected.dispose();
    _connectionType.dispose();
  }
}

// Retry mechanism for network operations
class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    double backoffMultiplier = 2.0,
  }) async {
    int attempts = 0;
    Duration currentDelay = delay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        debugPrint('Retry attempt $attempts failed: $e');

        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds:
              (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );

        if (currentDelay > maxDelay) {
          currentDelay = maxDelay;
        }
      }
    }

    throw Exception('Max retries exceeded');
  }

  static Future<T> retryWithConnectivity<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    final connectivity = ConnectivityService();

    return retry<T>(
      () async {
        if (!connectivity.isConnected) {
          throw Exception('No internet connection');
        }
        return await operation();
      },
      maxRetries: maxRetries,
      delay: delay,
    );
  }
}

// Offline data cache
class OfflineDataCache {
  static final Map<String, CachedData> _cache = {};

  static void store(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = CachedData(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(hours: 1),
    );
  }

  static T? retrieve<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (cached.isExpired) {
      _cache.remove(key);
      return null;
    }

    return cached.data as T?;
  }

  static bool has(String key) {
    final cached = _cache[key];
    return cached != null && !cached.isExpired;
  }

  static void clear() {
    _cache.clear();
  }

  static void removeExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
}

class CachedData {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

// Network-aware image loading
class NetworkAwareImageLoader {
  static String getOptimizedImageUrl(String originalUrl,
      {int? width, int? height}) {
    final connectivity = ConnectivityService();

    if (!connectivity.isConnected) {
      return originalUrl; // Return original, will be handled by cache
    }

    if (connectivity.isOnLowBandwidth) {
      // Return compressed version for mobile data
      return _getCompressedImageUrl(originalUrl, quality: 60);
    }

    return originalUrl;
  }

  static String _getCompressedImageUrl(String url, {int quality = 80}) {
    // This would typically integrate with a service like Cloudinary or similar
    // For now, return the original URL
    return url;
  }
}
