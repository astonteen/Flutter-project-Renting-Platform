import 'package:equatable/equatable.dart';

enum ReviewType {
  item,
  user,
  delivery,
  experience,
}

enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
}

class ReviewDimension extends Equatable {
  final String id;
  final String name;
  final String description;
  final double rating;
  final double maxRating;
  final String? comment;

  const ReviewDimension({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    this.maxRating = 5.0,
    this.comment,
  });

  @override
  List<Object?> get props =>
      [id, name, description, rating, maxRating, comment];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rating': rating,
      'max_rating': maxRating,
      'comment': comment,
    };
  }

  factory ReviewDimension.fromJson(Map<String, dynamic> json) {
    return ReviewDimension(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rating: json['rating'].toDouble(),
      maxRating: json['max_rating']?.toDouble() ?? 5.0,
      comment: json['comment'],
    );
  }

  ReviewDimension copyWith({
    String? id,
    String? name,
    String? description,
    double? rating,
    double? maxRating,
    String? comment,
  }) {
    return ReviewDimension(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      maxRating: maxRating ?? this.maxRating,
      comment: comment ?? this.comment,
    );
  }
}

class ReviewPhoto extends Equatable {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime uploadedAt;
  final Map<String, dynamic>? metadata;

  const ReviewPhoto({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    required this.uploadedAt,
    this.metadata,
  });

  @override
  List<Object?> get props =>
      [id, url, thumbnailUrl, caption, uploadedAt, metadata];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'uploaded_at': uploadedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ReviewPhoto.fromJson(Map<String, dynamic> json) {
    return ReviewPhoto(
      id: json['id'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      metadata: json['metadata'],
    );
  }
}

class TrustBadge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String color;
  final DateTime earnedAt;
  final Map<String, dynamic>? criteria;

  const TrustBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.color,
    required this.earnedAt,
    this.criteria,
  });

  @override
  List<Object?> get props =>
      [id, name, description, iconUrl, color, earnedAt, criteria];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
      'earned_at': earnedAt.toIso8601String(),
      'criteria': criteria,
    };
  }

  factory TrustBadge.fromJson(Map<String, dynamic> json) {
    return TrustBadge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      color: json['color'],
      earnedAt: DateTime.parse(json['earned_at']),
      criteria: json['criteria'],
    );
  }
}

class ReviewResponse extends Equatable {
  final String id;
  final String reviewId;
  final String responderId;
  final String responderName;
  final String? responderAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isOwnerResponse;

  const ReviewResponse({
    required this.id,
    required this.reviewId,
    required this.responderId,
    required this.responderName,
    this.responderAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isOwnerResponse = false,
  });

  @override
  List<Object?> get props => [
        id,
        reviewId,
        responderId,
        responderName,
        responderAvatar,
        content,
        createdAt,
        updatedAt,
        isOwnerResponse,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'responder_id': responderId,
      'responder_name': responderName,
      'responder_avatar': responderAvatar,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_owner_response': isOwnerResponse,
    };
  }

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'],
      reviewId: json['review_id'],
      responderId: json['responder_id'],
      responderName: json['responder_name'],
      responderAvatar: json['responder_avatar'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isOwnerResponse: json['is_owner_response'] ?? false,
    );
  }
}

class ReviewModel extends Equatable {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final String targetId; // Item ID, User ID, etc.
  final String targetName;
  final ReviewType type;
  final ReviewStatus status;
  final double overallRating;
  final String? title;
  final String? content;
  final List<ReviewDimension> dimensions;
  final List<ReviewPhoto> photos;
  final List<TrustBadge> reviewerBadges;
  final List<ReviewResponse> responses;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerifiedPurchase;
  final bool isRecommended;
  final int helpfulCount;
  final int reportCount;
  final Map<String, dynamic>? metadata;
  final List<String> tags;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.targetId,
    required this.targetName,
    required this.type,
    required this.status,
    required this.overallRating,
    this.title,
    this.content,
    this.dimensions = const [],
    this.photos = const [],
    this.reviewerBadges = const [],
    this.responses = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = false,
    this.isRecommended = false,
    this.helpfulCount = 0,
    this.reportCount = 0,
    this.metadata,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        id,
        reviewerId,
        reviewerName,
        reviewerAvatar,
        targetId,
        targetName,
        type,
        status,
        overallRating,
        title,
        content,
        dimensions,
        photos,
        reviewerBadges,
        responses,
        createdAt,
        updatedAt,
        isVerifiedPurchase,
        isRecommended,
        helpfulCount,
        reportCount,
        metadata,
        tags,
      ];

  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    String? targetId,
    String? targetName,
    ReviewType? type,
    ReviewStatus? status,
    double? overallRating,
    String? title,
    String? content,
    List<ReviewDimension>? dimensions,
    List<ReviewPhoto>? photos,
    List<TrustBadge>? reviewerBadges,
    List<ReviewResponse>? responses,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedPurchase,
    bool? isRecommended,
    int? helpfulCount,
    int? reportCount,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      type: type ?? this.type,
      status: status ?? this.status,
      overallRating: overallRating ?? this.overallRating,
      title: title ?? this.title,
      content: content ?? this.content,
      dimensions: dimensions ?? this.dimensions,
      photos: photos ?? this.photos,
      reviewerBadges: reviewerBadges ?? this.reviewerBadges,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isRecommended: isRecommended ?? this.isRecommended,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_avatar': reviewerAvatar,
      'target_id': targetId,
      'target_name': targetName,
      'type': type.name,
      'status': status.name,
      'overall_rating': overallRating,
      'title': title,
      'content': content,
      'dimensions': dimensions.map((d) => d.toJson()).toList(),
      'photos': photos.map((p) => p.toJson()).toList(),
      'reviewer_badges': reviewerBadges.map((b) => b.toJson()).toList(),
      'responses': responses.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified_purchase': isVerifiedPurchase,
      'is_recommended': isRecommended,
      'helpful_count': helpfulCount,
      'report_count': reportCount,
      'metadata': metadata,
      'tags': tags,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      reviewerId: json['reviewer_id'],
      reviewerName: json['reviewer_name'],
      reviewerAvatar: json['reviewer_avatar'],
      targetId: json['target_id'],
      targetName: json['target_name'],
      type: ReviewType.values.firstWhere((e) => e.name == json['type']),
      status: ReviewStatus.values.firstWhere((e) => e.name == json['status']),
      overallRating: json['overall_rating'].toDouble(),
      title: json['title'],
      content: json['content'],
      dimensions: (json['dimensions'] as List<dynamic>?)
              ?.map((d) => ReviewDimension.fromJson(d))
              .toList() ??
          [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((p) => ReviewPhoto.fromJson(p))
              .toList() ??
          [],
      reviewerBadges: (json['reviewer_badges'] as List<dynamic>?)
              ?.map((b) => TrustBadge.fromJson(b))
              .toList() ??
          [],
      responses: (json['responses'] as List<dynamic>?)
              ?.map((r) => ReviewResponse.fromJson(r))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      isRecommended: json['is_recommended'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      reportCount: json['report_count'] ?? 0,
      metadata: json['metadata'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Helper methods
  bool get hasPhotos => photos.isNotEmpty;
  bool get hasMultipleDimensions => dimensions.length > 1;
  bool get hasResponses => responses.isNotEmpty;
  bool get hasOwnerResponse => responses.any((r) => r.isOwnerResponse);
  bool get isHighRating => overallRating >= 4.0;
  bool get isLowRating => overallRating <= 2.0;
  bool get isPopular => helpfulCount > 10;
  bool get isFlagged => reportCount > 0;
  bool get isApproved => status == ReviewStatus.approved;

  double get averageDimensionRating {
    if (dimensions.isEmpty) return overallRating;
    return dimensions.map((d) => d.rating).reduce((a, b) => a + b) /
        dimensions.length;
  }

  List<ReviewDimension> get topDimensions {
    final sorted = List<ReviewDimension>.from(dimensions)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(3).toList();
  }

  List<ReviewDimension> get lowDimensions {
    final sorted = List<ReviewDimension>.from(dimensions)
      ..sort((a, b) => a.rating.compareTo(b.rating));
    return sorted.take(3).toList();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get ratingText {
    if (overallRating >= 4.5) return 'Excellent';
    if (overallRating >= 4.0) return 'Very Good';
    if (overallRating >= 3.5) return 'Good';
    if (overallRating >= 3.0) return 'Fair';
    if (overallRating >= 2.0) return 'Poor';
    return 'Very Poor';
  }

  List<String> get positiveAspects {
    return dimensions.where((d) => d.rating >= 4.0).map((d) => d.name).toList();
  }

  List<String> get negativeAspects {
    return dimensions.where((d) => d.rating <= 2.0).map((d) => d.name).toList();
  }

  // Add missing getter properties
  String get comment => content ?? '';
  bool get isVerifiedRental => isVerifiedPurchase;
  String get ratingDisplayText => overallRating.toStringAsFixed(1);
  bool get hasDetailedRatings => dimensions.isNotEmpty;

  double? get conditionAccuracyRating => dimensions
      .where((d) => d.name == 'Condition Accuracy')
      .map((d) => d.rating)
      .firstOrNull;

  double? get communicationRating => dimensions
      .where((d) => d.name == 'Communication')
      .map((d) => d.rating)
      .firstOrNull;

  double? get deliveryExperienceRating => dimensions
      .where((d) => d.name == 'Delivery Experience')
      .map((d) => d.rating)
      .firstOrNull;

  List<String> get photoUrls => photos.map((p) => p.url).toList();
  int get helpfulVotes => responses.where((r) => r.isOwnerResponse).length;

  DateTime? get ownerResponseDate => responses
      .where((r) => r.isOwnerResponse)
      .map((r) => r.createdAt)
      .firstOrNull;

  String? get ownerResponse => responses
      .where((r) => r.isOwnerResponse)
      .map((r) => r.content)
      .firstOrNull;
}

class TrustScore {
  final double score;
  final int reviewCount;
  final int verifiedReviews;
  final double responseRate;
  final String level;

  TrustScore({
    required this.score,
    required this.reviewCount,
    required this.verifiedReviews,
    required this.responseRate,
    required this.level,
  });

  factory TrustScore.calculate({
    required int totalReviews,
    required double averageRating,
    required int verifiedRentals,
    required bool hasVerifiedIdentity,
    required double responseRate,
  }) {
    // Calculate trust score based on various factors
    double score = 0.0;

    // Base score from average rating (40% weight)
    score += (averageRating / 5.0) * 40;

    // Review count factor (20% weight)
    double reviewFactor = totalReviews > 0
        ? (totalReviews > 50 ? 20 : (totalReviews / 50.0) * 20)
        : 0;
    score += reviewFactor;

    // Verified rentals factor (20% weight)
    double verifiedFactor =
        totalReviews > 0 ? (verifiedRentals / totalReviews) * 20 : 0;
    score += verifiedFactor;

    // Response rate factor (10% weight)
    score += (responseRate / 100.0) * 10;

    // Identity verification bonus (10% weight)
    if (hasVerifiedIdentity) {
      score += 10;
    }

    // Determine trust level
    String level;
    if (score >= 85) {
      level = 'Excellent';
    } else if (score >= 70) {
      level = 'Very Good';
    } else if (score >= 55) {
      level = 'Good';
    } else if (score >= 40) {
      level = 'Fair';
    } else {
      level = 'Needs Improvement';
    }

    return TrustScore(
      score: score,
      reviewCount: totalReviews,
      verifiedReviews: verifiedRentals,
      responseRate: responseRate,
      level: level,
    );
  }

  factory TrustScore.fromJson(Map<String, dynamic> json) {
    return TrustScore(
      score: (json['score'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      verifiedReviews: json['verified_reviews'] as int,
      responseRate: (json['response_rate'] as num).toDouble(),
      level: json['level'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'review_count': reviewCount,
      'verified_reviews': verifiedReviews,
      'response_rate': responseRate,
      'level': level,
    };
  }
}
