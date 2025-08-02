import 'package:rent_ease/features/rental/data/models/booking_model.dart';

class RentalBookingModel extends BookingModel {
  final String? itemName;
  final String? itemDescription;
  final List<String> itemImageUrls;
  final String? primaryImageUrl;
  final String? ownerName;
  final String? ownerAvatarUrl;

  const RentalBookingModel({
    required super.id,
    required super.itemId,
    required super.renterId,
    required super.ownerId,
    required super.startDate,
    required super.endDate,
    required super.totalAmount,
    required super.securityDeposit,
    required super.status,
    required super.needsDelivery,
    super.deliveryPartnerId,
    super.deliveryFee,
    required super.isItemReady,
    required super.createdAt,
    required super.updatedAt,
    super.cancelReason,
    super.metadata,
    super.customerRatedAt,
    super.ownerRatedAt,
    this.itemName,
    this.itemDescription,
    this.itemImageUrls = const [],
    this.primaryImageUrl,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  factory RentalBookingModel.fromJson(Map<String, dynamic> json) {
    // Extract item details
    final itemData = json['items'] as Map<String, dynamic>?;
    final ownerData = json['profiles'] as Map<String, dynamic>?;

    // Process item images
    List<String> imageUrls = [];
    String? primaryImage;

    if (itemData?['image_urls'] != null) {
      imageUrls = List<String>.from(itemData!['image_urls'] as List);
    }

    if (itemData?['primary_image_url'] != null &&
        itemData!['primary_image_url'].toString().isNotEmpty) {
      primaryImage = itemData['primary_image_url'] as String;
      if (!imageUrls.contains(primaryImage)) {
        imageUrls.insert(0, primaryImage);
      }
    }

    return RentalBookingModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      renterId: json['renter_id'] as String,
      ownerId: json['owner_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalAmount: (json['total_price'] as num).toDouble(),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      needsDelivery: json['delivery_required'] as bool? ?? false,
      deliveryPartnerId: json['delivery_partner_id'] as String?,
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      isItemReady: json['is_item_ready'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      customerRatedAt: json['customer_rated_at'] != null
          ? DateTime.parse(json['customer_rated_at'] as String)
          : null,
      ownerRatedAt: json['owner_rated_at'] != null
          ? DateTime.parse(json['owner_rated_at'] as String)
          : null,
      itemName: itemData?['name'] as String?,
      itemDescription: itemData?['description'] as String?,
      itemImageUrls: imageUrls,
      primaryImageUrl: primaryImage,
      ownerName: ownerData?['full_name'] as String?,
      ownerAvatarUrl: ownerData?['avatar_url'] as String?,
    );
  }

  // Helper to get the best image URL
  String get bestImageUrl {
    if (primaryImageUrl != null && primaryImageUrl!.isNotEmpty) {
      return primaryImageUrl!;
    }
    if (itemImageUrls.isNotEmpty) {
      return itemImageUrls.first;
    }
    return '';
  }

  // Helper to get display name for item
  String get displayItemName {
    return itemName ?? 'Unknown Item';
  }

  // Helper to get display name for owner
  String get displayOwnerName {
    return ownerName ?? 'Unknown Owner';
  }
}
