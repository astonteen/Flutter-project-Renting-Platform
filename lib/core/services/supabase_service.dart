import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitializing = false;
  static String? _initializationError;

  /// Check if there's an active internet connection
  static Future<bool> _checkInternetConnection() async {
    try {
      // Try multiple reliable endpoints for better connectivity detection
      final results = await Future.wait([
        InternetAddress.lookup('google.com'),
        InternetAddress.lookup('cloudflare.com'),
        InternetAddress.lookup('supabase.com'),
      ].map((lookup) => lookup.timeout(
            const Duration(seconds: 3),
            onTimeout: () => <InternetAddress>[],
          )));

      // Return true if any lookup succeeds
      return results.any((result) => result.isNotEmpty);
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      // In case of error, assume connection is available (fail-safe)
      return true;
    }
  }

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    int timeoutSeconds = 15, // Increased timeout
  }) async {
    if (_isInitializing) {
      debugPrint('Supabase initialization already in progress, skipping');
      return;
    }

    _isInitializing = true;
    _initializationError = null;

    try {
      debugPrint(
          'Starting Supabase initialization with timeout: $timeoutSeconds seconds');
      debugPrint('URL: $supabaseUrl');
      debugPrint('Key length: ${supabaseAnonKey.length}');

      // Check for internet connectivity first
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        debugPrint(
            '⚠️ Internet connectivity check failed, but proceeding with Supabase initialization anyway');
        // Continue with initialization even if connectivity check fails
        // This is more robust for development environments
      }

      // Create a timeout that will complete after specified seconds
      final timeoutFuture =
          Future.delayed(Duration(seconds: timeoutSeconds), () {
        throw TimeoutException(
            'Supabase initialization timed out after $timeoutSeconds seconds');
      });

      // Try initialization with DNS fallback for emulator issues
      await _initializeWithFallback(
          supabaseUrl, supabaseAnonKey, timeoutFuture);

      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');

      // Test the connection by making a simple query
      try {
        await _client!.from('profiles').select('id').limit(1);
        debugPrint('Supabase connection test successful');
      } catch (e) {
        debugPrint('Supabase connection test failed: $e');
        _initializationError = 'Connection test failed: $e';
      }
    } on TimeoutException {
      _initializationError =
          'Initialization timed out after $timeoutSeconds seconds';
      debugPrint('Supabase initialization timed out');
      _client = null;
    } catch (e) {
      _initializationError = 'Initialization failed: $e';
      debugPrint('Error initializing Supabase: $e');
      _client = null;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize Supabase with DNS fallback for emulator issues
  static Future<void> _initializeWithFallback(
    String supabaseUrl,
    String supabaseAnonKey,
    Future<void> timeoutFuture,
  ) async {
    try {
      // First attempt with original URL
      await Future.any([
        Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        ),
        timeoutFuture,
      ]);
    } catch (e) {
      debugPrint('Primary Supabase initialization failed: $e');

      // In development, try with IP address fallback for DNS issues
      if (kDebugMode &&
          supabaseUrl.contains('iwefwascboexieneeaks.supabase.co')) {
        debugPrint('🔄 Attempting Supabase initialization with IP fallback...');

        try {
          // Use one of the resolved IP addresses
          final fallbackUrl = supabaseUrl.replaceAll(
            'iwefwascboexieneeaks.supabase.co',
            '104.18.38.10', // From nslookup result
          );

          await Future.any([
            Supabase.initialize(
              url: fallbackUrl,
              anonKey: supabaseAnonKey,
              debug: kDebugMode,
              authOptions: const FlutterAuthClientOptions(
                authFlowType: AuthFlowType.pkce,
              ),
            ),
            timeoutFuture,
          ]);

          debugPrint('✅ Supabase initialized with IP fallback');
        } catch (fallbackError) {
          debugPrint('❌ IP fallback also failed: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      final errorMsg =
          _initializationError ?? 'Supabase client not initialized';
      debugPrint(
          'WARNING: Attempting to use Supabase client before initialization');
      debugPrint('Error: $errorMsg');
      throw Exception('Authentication service unavailable: $errorMsg');
    }
    return _client!;
  }

  // Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  // Get initialization error if any
  static String? get initializationError => _initializationError;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Database methods
  static Future<List<Map<String, dynamic>>> getItems({
    int? limit,
    int? offset,
    String? category,
    String? searchQuery,
  }) async {
    try {
      // Create the base query
      final query = client.from('items').select('*');

      // Apply filters
      if (category != null) {
        query.eq('category_id', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query.ilike('name', '%$searchQuery%');
      }

      // Apply ordering
      query.order('created_at', ascending: false);

      // Apply pagination
      if (limit != null) {
        query.limit(limit);
      }

      if (offset != null) {
        query.range(offset, offset + (limit ?? 10) - 1);
      }

      // Execute the query
      final response = await query;
      return response;
    } catch (e) {
      debugPrint('Error fetching items: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getItemById(String id) async {
    try {
      final response = await client
          .from('items')
          .select('*, profiles(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching item: $e');
      rethrow;
    }
  }

  static Future<void> createItem(Map<String, dynamic> data) async {
    try {
      await client.from('items').insert(data);
    } catch (e) {
      debugPrint('Error creating item: $e');
      rethrow;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final userId = currentUser?.id;
      if (userId != null) {
        await client.from('profiles').update(data).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('profiles').select().eq('id', userId).single();
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRentals({
    required String userId,
    String? status,
  }) async {
    try {
      final query = client
          .from('rentals')
          .select('*, items(*), profiles!rentals_owner_id_fkey(*)');

      query.eq('renter_id', userId);

      if (status != null) {
        query.eq('status', status);
      }

      query.order('created_at', ascending: false);
      final response = await query;
      return response;
    } catch (e) {
      debugPrint('Error fetching rentals: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getListings({
    required String userId,
    String? status,
  }) async {
    try {
      final query = client
          .from('rentals')
          .select('*, items(*), profiles!rentals_renter_id_fkey(*)');

      query.eq('owner_id', userId);

      if (status != null) {
        query.eq('status', status);
      }

      query.order('created_at', ascending: false);
      final response = await query;
      return response;
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDeliveries({
    required String userId,
    String? status,
  }) async {
    try {
      final query = client.from('deliveries').select('*, rentals(*, items(*))');

      query.eq('driver_id', userId);

      if (status != null) {
        query.eq('status', status);
      }

      query.order('created_at', ascending: false);
      final response = await query;
      return response;
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
