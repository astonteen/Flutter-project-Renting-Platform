import 'package:equatable/equatable.dart';

class UserStatisticsModel extends Equatable {
  final int rentalsCount;
  final int listingsCount;
  final int deliveriesCount;
  final double totalEarnings;
  final double averageRating;
  final DateTime? memberSince;

  const UserStatisticsModel({
    required this.rentalsCount,
    required this.listingsCount,
    required this.deliveriesCount,
    required this.totalEarnings,
    required this.averageRating,
    this.memberSince,
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      rentalsCount: json['rentals_count'] as int? ?? 0,
      listingsCount: json['listings_count'] as int? ?? 0,
      deliveriesCount: json['deliveries_count'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rentals_count': rentalsCount,
      'listings_count': listingsCount,
      'deliveries_count': deliveriesCount,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
      'member_since': memberSince?.toIso8601String(),
    };
  }

  UserStatisticsModel copyWith({
    int? rentalsCount,
    int? listingsCount,
    int? deliveriesCount,
    double? totalEarnings,
    double? averageRating,
    DateTime? memberSince,
  }) {
    return UserStatisticsModel(
      rentalsCount: rentalsCount ?? this.rentalsCount,
      listingsCount: listingsCount ?? this.listingsCount,
      deliveriesCount: deliveriesCount ?? this.deliveriesCount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      averageRating: averageRating ?? this.averageRating,
      memberSince: memberSince ?? this.memberSince,
    );
  }

  @override
  List<Object?> get props => [
        rentalsCount,
        listingsCount,
        deliveriesCount,
        totalEarnings,
        averageRating,
        memberSince,
      ];

  @override
  String toString() {
    return 'UserStatisticsModel(rentals: $rentalsCount, listings: $listingsCount, deliveries: $deliveriesCount, earnings: \$${totalEarnings.toStringAsFixed(2)})';
  }

  // Helper getters
  bool get hasActivity =>
      rentalsCount > 0 || listingsCount > 0 || deliveriesCount > 0;

  bool get hasEarnings => totalEarnings > 0;

  bool get hasRating => averageRating > 0;

  String get totalEarningsFormatted => '\$${totalEarnings.toStringAsFixed(2)}';

  String get averageRatingFormatted => averageRating > 0
      ? '${averageRating.toStringAsFixed(1)}/5.0'
      : 'No ratings yet';

  int get totalActivity => rentalsCount + listingsCount + deliveriesCount;

  String get activitySummary {
    if (!hasActivity) return 'No activity yet';

    final activities = <String>[];
    if (rentalsCount > 0) {
      activities.add('$rentalsCount rental${rentalsCount > 1 ? 's' : ''}');
    }
    if (listingsCount > 0) {
      activities.add('$listingsCount listing${listingsCount > 1 ? 's' : ''}');
    }
    if (deliveriesCount > 0) {
      activities
          .add('$deliveriesCount deliver${deliveriesCount > 1 ? 'ies' : 'y'}');
    }

    return activities.join(', ');
  }

  // Experience level based on total activity
  String get experienceLevel {
    final total = totalActivity;
    if (total == 0) return 'New User';
    if (total < 5) return 'Beginner';
    if (total < 15) return 'Intermediate';
    if (total < 50) return 'Advanced';
    return 'Expert';
  }

  // Engagement score (0-100)
  int get engagementScore {
    int score = 0;

    // Activity points
    score += (rentalsCount * 2).clamp(0, 30); // Max 30 for rentals
    score += (listingsCount * 3).clamp(0, 30); // Max 30 for listings
    score += (deliveriesCount * 2).clamp(0, 20); // Max 20 for deliveries

    // Rating bonus
    if (averageRating >= 4.5) {
      score += 10;
    } else if (averageRating >= 4.0) {
      score += 5;
    } else if (averageRating >= 3.5) {
      score += 2;
    }

    // Earnings bonus
    if (totalEarnings >= 1000) {
      score += 10;
    } else if (totalEarnings >= 500) {
      score += 5;
    } else if (totalEarnings >= 100) {
      score += 2;
    }

    return score.clamp(0, 100);
  }
}
