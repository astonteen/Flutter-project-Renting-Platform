class RentalItemModel {
  final String id;
  final String title;
  final String? description;
  final double pricePerDay;
  final bool available;
  final String? location;
  final String category;
  final String ownerId;
  final String? ownerName;
  final List<String> imageUrls;
  final String? primaryImageUrl;
  final double? rating;
  final int? reviewCount;

  RentalItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.pricePerDay,
    required this.available,
    this.location,
    required this.category,
    required this.ownerId,
    this.ownerName,
    required this.imageUrls,
    this.primaryImageUrl,
    this.rating,
    this.reviewCount,
  });

  factory RentalItemModel.fromJson(Map<String, dynamic> json) {
    final images = (json['item_images'] as List? ?? [])
        .map((img) => img['image_url'] as String)
        .toList();
    final primaryImage = images.isNotEmpty ? images.first : null;
    final reviews = json['reviews'] as List? ?? [];
    final averageRating = reviews.isNotEmpty
        ? reviews.map((r) => r['rating'] as num).reduce((a, b) => a + b) /
            reviews.length
        : null;

    return RentalItemModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      available: json['available'] as bool,
      location: json['location'] as String?,
      category: (json['categories']?['name'] as String?) ?? '',
      ownerId: json['owner_id'] as String,
      ownerName: json['profiles']?['full_name'] as String?,
      imageUrls: images,
      primaryImageUrl: primaryImage,
      rating: averageRating,
      reviewCount: reviews.length,
    );
  }
}
