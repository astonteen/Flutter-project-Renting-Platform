class DeliveryRatingModel {
  final String deliveryId;
  final String raterId; // ID of the person giving the rating
  final String ratedId; // ID of the person being rated (driver)
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime ratedAt;
  final String ratingType; // 'customer_to_driver', 'driver_to_customer'

  const DeliveryRatingModel({
    required this.deliveryId,
    required this.raterId,
    required this.ratedId,
    required this.rating,
    this.comment,
    required this.ratedAt,
    required this.ratingType,
  });

  factory DeliveryRatingModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRatingModel(
      deliveryId: json['delivery_id'] as String,
      raterId: json['rater_id'] as String,
      ratedId: json['rated_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      ratedAt: DateTime.parse(json['rated_at'] as String),
      ratingType: json['rating_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_id': deliveryId,
      'rater_id': raterId,
      'rated_id': ratedId,
      'rating': rating,
      'comment': comment,
      'rated_at': ratedAt.toIso8601String(),
      'rating_type': ratingType,
    };
  }

  // Factory constructor for creating customer rating for driver
  factory DeliveryRatingModel.customerToDriver({
    required String deliveryId,
    required String customerId,
    required String driverId,
    required int rating,
    String? comment,
  }) {
    return DeliveryRatingModel(
      deliveryId: deliveryId,
      raterId: customerId,
      ratedId: driverId,
      rating: rating,
      comment: comment,
      ratedAt: DateTime.now(),
      ratingType: 'customer_to_driver',
    );
  }

  // Factory constructor for creating driver rating for customer
  factory DeliveryRatingModel.driverToCustomer({
    required String deliveryId,
    required String driverId,
    required String customerId,
    required int rating,
    String? comment,
  }) {
    return DeliveryRatingModel(
      deliveryId: deliveryId,
      raterId: driverId,
      ratedId: customerId,
      rating: rating,
      comment: comment,
      ratedAt: DateTime.now(),
      ratingType: 'driver_to_customer',
    );
  }

  @override
  String toString() {
    return 'DeliveryRatingModel(deliveryId: $deliveryId, rating: $rating, ratingType: $ratingType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryRatingModel &&
        other.deliveryId == deliveryId &&
        other.raterId == raterId &&
        other.ratedId == ratedId &&
        other.rating == rating &&
        other.comment == comment &&
        other.ratedAt == ratedAt &&
        other.ratingType == ratingType;
  }

  @override
  int get hashCode {
    return Object.hash(
      deliveryId,
      raterId,
      ratedId,
      rating,
      comment,
      ratedAt,
      ratingType,
    );
  }
}
