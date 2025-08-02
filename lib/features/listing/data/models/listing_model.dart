class ListingModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String categoryId;
  final String? categoryName;
  final double pricePerDay;
  final double pricePerWeek;
  final double pricePerMonth;
  final double securityDeposit;
  final List<String> imageUrls;
  final String primaryImageUrl;
  final String condition; // excellent, good, fair, poor
  final bool isAvailable;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> features;
  final Map<String, dynamic>? specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final double? rating;
  final int reviewCount;
  final bool requiresDelivery;
  final double? deliveryFee;
  final String? deliveryInstructions;
  final int quantity;
  final int blockingDays;
  final String? blockingReason;

  const ListingModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.pricePerMonth,
    required this.securityDeposit,
    required this.imageUrls,
    required this.primaryImageUrl,
    required this.condition,
    required this.isAvailable,
    required this.location,
    this.latitude,
    this.longitude,
    required this.features,
    this.specifications,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.rating,
    this.reviewCount = 0,
    this.requiresDelivery = false,
    this.deliveryFee,
    this.deliveryInstructions,
    this.quantity = 1,
    this.blockingDays = 2,
    this.blockingReason,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['categories'] != null
          ? json['categories']['name'] as String?
          : json['category_name'] as String?,
      pricePerDay: json['price_per_day'] != null
          ? (json['price_per_day'] as num).toDouble()
          : 0.0,
      pricePerWeek: json['price_per_week'] != null
          ? (json['price_per_week'] as num).toDouble()
          : 0.0,
      pricePerMonth: json['price_per_month'] != null
          ? (json['price_per_month'] as num).toDouble()
          : 0.0,
      securityDeposit: json['security_deposit'] != null
          ? (json['security_deposit'] as num).toDouble()
          : 0.0,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : <String>[],
      primaryImageUrl: json['primary_image_url'] as String? ?? '',
      condition: json['condition'] as String? ?? 'good',
      isAvailable: json['available'] as bool? ?? true,
      location: json['location'] as String? ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : <String>[],
      specifications: json['specifications'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      viewCount: json['view_count'] as int? ?? 0,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int? ?? 0,
      requiresDelivery: json['requires_delivery'] as bool? ?? false,
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      deliveryInstructions: json['delivery_instructions'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      blockingDays: json['blocking_days'] as int? ?? 2,
      blockingReason: json['blocking_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'price_per_day': pricePerDay,
      'price_per_week': pricePerWeek,
      'price_per_month': pricePerMonth,
      'security_deposit': securityDeposit,
      'image_urls': imageUrls,
      'primary_image_url': primaryImageUrl,
      'condition': condition,
      'available': isAvailable,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'features': features,
      'specifications': specifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'view_count': viewCount,
      'rating': rating,
      'review_count': reviewCount,
      'requires_delivery': requiresDelivery,
      'delivery_fee': deliveryFee,
      'delivery_instructions': deliveryInstructions,
      'quantity': quantity,
      'blocking_days': blockingDays,
      'blocking_reason': blockingReason,
    };
  }

  // Helper methods
  String get formattedPricePerDay => '\$${pricePerDay.toStringAsFixed(2)}/day';
  String get formattedPricePerWeek =>
      '\$${pricePerWeek.toStringAsFixed(2)}/week';
  String get formattedPricePerMonth =>
      '\$${pricePerMonth.toStringAsFixed(2)}/month';
  String get formattedSecurityDeposit =>
      '\$${securityDeposit.toStringAsFixed(2)}';

  String get conditionDisplayText {
    switch (condition) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return 'Unknown';
    }
  }

  String get ratingDisplay {
    if (rating == null) return 'No ratings';
    return '${rating!.toStringAsFixed(1)} ($reviewCount reviews)';
  }

  String get availabilityStatus => isAvailable ? 'Available' : 'Not Available';

  String get quantityDisplay {
    if (quantity == 1) return '1 unit available';
    return '$quantity units available';
  }

  String get blockingDisplay {
    if (blockingDays == 0) return 'No maintenance period';
    if (blockingDays == 1) return '1 day maintenance period';
    return '$blockingDays days maintenance period';
  }

  ListingModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    double? pricePerDay,
    double? pricePerWeek,
    double? pricePerMonth,
    double? securityDeposit,
    List<String>? imageUrls,
    String? primaryImageUrl,
    String? condition,
    bool? isAvailable,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? features,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    double? rating,
    int? reviewCount,
    bool? requiresDelivery,
    double? deliveryFee,
    String? deliveryInstructions,
    int? quantity,
    int? blockingDays,
    String? blockingReason,
  }) {
    return ListingModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerWeek: pricePerWeek ?? this.pricePerWeek,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      imageUrls: imageUrls ?? this.imageUrls,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      condition: condition ?? this.condition,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      features: features ?? this.features,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      requiresDelivery: requiresDelivery ?? this.requiresDelivery,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      quantity: quantity ?? this.quantity,
      blockingDays: blockingDays ?? this.blockingDays,
      blockingReason: blockingReason ?? this.blockingReason,
    );
  }
}
