import 'package:equatable/equatable.dart';

class RentalItemModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? categoryId;
  final String? categoryName;
  final double pricePerDay;
  final double? pricePerWeek;
  final double? pricePerMonth;
  final double? securityDeposit;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? condition;
  final bool available;
  final bool featured;
  final List<String> imageUrls;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentalItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.ownerName,
    this.ownerAvatarUrl,
    this.categoryId,
    this.categoryName,
    required this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
    this.securityDeposit,
    this.location,
    this.latitude,
    this.longitude,
    this.condition,
    required this.available,
    required this.featured,
    required this.imageUrls,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentalItemModel.fromJson(Map<String, dynamic> json) {
    // Handle image URLs from items table
    List<String> images = [];
    if (json['image_urls'] != null) {
      images = List<String>.from(json['image_urls'] as List);
    }

    // If primary_image_url exists and not in images list, add it first
    if (json['primary_image_url'] != null &&
        json['primary_image_url'].toString().isNotEmpty) {
      final primaryUrl = json['primary_image_url'] as String;
      if (!images.contains(primaryUrl)) {
        images.insert(0, primaryUrl);
      }
    }

    return RentalItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      ownerName: json['owner_name'] as String?,
      ownerAvatarUrl: json['owner_avatar_url'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      pricePerWeek: json['price_per_week'] != null
          ? (json['price_per_week'] as num).toDouble()
          : null,
      pricePerMonth: json['price_per_month'] != null
          ? (json['price_per_month'] as num).toDouble()
          : null,
      securityDeposit: json['security_deposit'] != null
          ? (json['security_deposit'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      condition: json['condition'] as String?,
      available: json['available'] as bool? ?? true,
      featured: json['featured'] as bool? ?? false,
      imageUrls: images,
      rating: json['avg_rating'] != null
          ? (json['avg_rating'] as num).toDouble()
          : null,
      reviewCount: json['review_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'category_id': categoryId,
      'price_per_day': pricePerDay,
      'price_per_week': pricePerWeek,
      'price_per_month': pricePerMonth,
      'security_deposit': securityDeposit,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'condition': condition,
      'available': available,
      'featured': featured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get primary image URL
  String get primaryImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : '';
  }

  // Helper method to format price display
  String get formattedPricePerDay {
    return '\$${pricePerDay.toStringAsFixed(0)}/day';
  }

  // Helper method to get rating display
  String get ratingDisplay {
    if (rating != null) {
      return rating!.toStringAsFixed(1);
    }
    return 'No rating';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ownerId,
        ownerName,
        ownerAvatarUrl,
        categoryId,
        categoryName,
        pricePerDay,
        pricePerWeek,
        pricePerMonth,
        securityDeposit,
        location,
        latitude,
        longitude,
        condition,
        available,
        featured,
        imageUrls,
        rating,
        reviewCount,
        createdAt,
        updatedAt,
      ];
}
