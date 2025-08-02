import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static const String _listingImagesBucket = 'listing-images';
  static const String _profileImagesBucket = 'profile-images';

  /// Upload an image file to Supabase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String bucket,
    String? fileName,
    String? folder,
  }) async {
    try {
      if (!SupabaseService.isInitialized) {
        debugPrint('Supabase not initialized');
        return null;
      }

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('User not authenticated');
        return null;
      }

      // Generate unique filename if not provided
      final fileExtension = path.extension(imageFile.path);
      final uniqueFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}$fileExtension';

      // Create full path with optional folder
      final fullPath =
          folder != null ? '$folder/$uniqueFileName' : uniqueFileName;

      debugPrint('Uploading image to: $bucket/$fullPath');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      final response = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(fullPath, bytes);

      debugPrint('Upload response: $response');

      // Get public URL
      final publicUrl =
          SupabaseService.client.storage.from(bucket).getPublicUrl(fullPath);

      debugPrint('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image to $bucket: $e');

      // Enhanced error logging
      if (e.toString().contains('row-level security policy')) {
        debugPrint(
            'RLS Policy Error: Check that user ID matches folder structure');
        debugPrint('Expected path: userId/subfolder/file.jpg');
        final currentUserId = SupabaseService.currentUser?.id;
        debugPrint('Current user ID: $currentUserId');
      } else if (e.toString().contains('bucket')) {
        debugPrint(
            'Bucket Error: Check that bucket "$bucket" exists and is accessible');
      }

      return null;
    }
  }

  /// Upload image from bytes (for web compatibility)
  static Future<String?> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String bucket,
    required String fileName,
    String? folder,
  }) async {
    try {
      if (!SupabaseService.isInitialized) {
        debugPrint('Supabase not initialized');
        return null;
      }

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('User not authenticated');
        return null;
      }

      // Create full path with optional folder
      final fullPath = folder != null ? '$folder/$fileName' : fileName;

      debugPrint('Uploading image bytes to: $bucket/$fullPath');

      // Upload to Supabase Storage
      final response = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(fullPath, imageBytes);

      debugPrint('Upload response: $response');

      // Get public URL
      final publicUrl =
          SupabaseService.client.storage.from(bucket).getPublicUrl(fullPath);

      debugPrint('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image from bytes: $e');
      return null;
    }
  }

  /// Upload listing image
  static Future<String?> uploadListingImage({
    required File imageFile,
    required String listingId,
    String? fileName,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    // Use userId as root folder to match RLS policy: userId/listingId/fileName
    return uploadImage(
      imageFile: imageFile,
      bucket: _listingImagesBucket,
      fileName: fileName,
      folder: '$userId/$listingId',
    );
  }

  /// Upload profile image
  static Future<String?> uploadProfileImage({
    required File imageFile,
    String? fileName,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    return uploadImage(
      imageFile: imageFile,
      bucket: _profileImagesBucket,
      fileName: fileName ?? 'profile_$userId.jpg',
      folder: userId,
    );
  }

  /// Delete an image from storage
  static Future<bool> deleteImage({
    required String bucket,
    required String filePath,
  }) async {
    try {
      if (!SupabaseService.isInitialized) {
        debugPrint('Supabase not initialized');
        return false;
      }

      debugPrint('Deleting image: $bucket/$filePath');

      final response =
          await SupabaseService.client.storage.from(bucket).remove([filePath]);

      debugPrint('Delete response: $response');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Delete listing image
  static Future<bool> deleteListingImage({
    required String listingId,
    required String fileName,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    // Use userId as root folder to match RLS policy: userId/listingId/fileName
    return deleteImage(
      bucket: _listingImagesBucket,
      filePath: '$userId/$listingId/$fileName',
    );
  }

  /// Delete profile image
  static Future<bool> deleteProfileImage({
    required String fileName,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    return deleteImage(
      bucket: _profileImagesBucket,
      filePath: '$userId/$fileName',
    );
  }

  /// Get optimized image URL with transformations
  static String getOptimizedImageUrl({
    required String originalUrl,
    int? width,
    int? height,
    int? quality,
  }) {
    // For now, return original URL
    // In the future, we can add Supabase image transformations
    return originalUrl;
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Check if file size is within limit (default 5MB)
  static Future<bool> isFileSizeValid(File file,
      {double maxSizeMB = 5.0}) async {
    final sizeMB = await getFileSizeInMB(file);
    return sizeMB <= maxSizeMB;
  }

  /// Create storage buckets (call this during app initialization)
  static Future<void> initializeStorageBuckets() async {
    try {
      if (!SupabaseService.isInitialized) {
        debugPrint('Supabase not initialized - skipping bucket creation');
        return;
      }

      // Create listing images bucket
      await _createBucketIfNotExists(_listingImagesBucket);

      // Create profile images bucket
      await _createBucketIfNotExists(_profileImagesBucket);

      debugPrint('Storage buckets initialized successfully');
    } catch (e) {
      debugPrint('Error initializing storage buckets: $e');
    }
  }

  static Future<void> _createBucketIfNotExists(String bucketName) async {
    try {
      // Try to get bucket info (this will throw if bucket doesn't exist)
      await SupabaseService.client.storage.getBucket(bucketName);
      debugPrint('Bucket $bucketName already exists');
    } catch (e) {
      // Bucket doesn't exist, create it
      try {
        await SupabaseService.client.storage.createBucket(
          bucketName,
          const BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB',
          ),
        );
        debugPrint('Created bucket: $bucketName');
      } catch (createError) {
        debugPrint('Error creating bucket $bucketName: $createError');
      }
    }
  }
}
