import 'package:equatable/equatable.dart';
import 'delivery_job_model.dart';

class DriverProfileModel extends Equatable {
  final String id;
  final String userId;
  final VehicleType vehicleType;
  final String? vehicleModel;
  final String? licensePlate;
  final bool isActive;
  final bool isAvailable;
  final String? currentLocation;
  final int totalDeliveries;
  final double averageRating;
  final double totalEarnings;
  final String? bankAccountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related user info
  final String? userName;
  final String? userPhone;
  final String? userEmail;

  const DriverProfileModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehicleModel,
    this.licensePlate,
    required this.isActive,
    required this.isAvailable,
    this.currentLocation,
    required this.totalDeliveries,
    required this.averageRating,
    required this.totalEarnings,
    this.bankAccountNumber,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhone,
    this.userEmail,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleType: _parseVehicleType(json['vehicle_type'] as String),
      vehicleModel: json['vehicle_model'] as String?,
      licensePlate: json['license_plate'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isAvailable: json['is_available'] as bool? ?? false,
      currentLocation: json['current_location'] as String?,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      bankAccountNumber: json['bank_account_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      userEmail: json['user_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'vehicle_type': _vehicleTypeToString(vehicleType),
      'vehicle_model': vehicleModel,
      'license_plate': licensePlate,
      'is_active': isActive,
      'is_available': isAvailable,
      'current_location': currentLocation,
      'total_deliveries': totalDeliveries,
      'average_rating': averageRating,
      'total_earnings': totalEarnings,
      'bank_account_number': bankAccountNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  // Helper methods
  String get vehicleTypeDisplayText {
    switch (vehicleType) {
      case VehicleType.bike:
        return 'Bicycle';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
    }
  }

  String get availabilityStatus {
    if (!isActive) return 'Inactive';
    return isAvailable ? 'Available' : 'Offline';
  }

  String get formattedTotalEarnings => '\$${totalEarnings.toStringAsFixed(2)}';
  String get formattedAverageRating => averageRating.toStringAsFixed(1);

  // Performance metrics
  String get performanceLevel {
    if (averageRating >= 4.8) return 'Excellent';
    if (averageRating >= 4.5) return 'Great';
    if (averageRating >= 4.0) return 'Good';
    if (averageRating >= 3.5) return 'Fair';
    return 'Needs Improvement';
  }

  bool get isEligibleForPremiumDeliveries {
    return averageRating >= 4.5 && totalDeliveries >= 20;
  }

  DriverProfileModel copyWith({
    String? id,
    String? userId,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    bool? isActive,
    bool? isAvailable,
    String? currentLocation,
    int? totalDeliveries,
    double? averageRating,
    double? totalEarnings,
    String? bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userPhone,
    String? userEmail,
  }) {
    return DriverProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      averageRating: averageRating ?? this.averageRating,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        vehicleType,
        vehicleModel,
        licensePlate,
        isActive,
        isAvailable,
        currentLocation,
        totalDeliveries,
        averageRating,
        totalEarnings,
        bankAccountNumber,
        createdAt,
        updatedAt,
        userName,
        userPhone,
        userEmail,
      ];

  @override
  String toString() {
    return 'DriverProfileModel(id: $id, userName: $userName, vehicleType: $vehicleTypeDisplayText, status: $availabilityStatus)';
  }

  // Private helper methods
  static VehicleType _parseVehicleType(String type) {
    switch (type) {
      case 'bike':
        return VehicleType.bike;
      case 'motorcycle':
        return VehicleType.motorcycle;
      case 'car':
        return VehicleType.car;
      case 'van':
        return VehicleType.van;
      default:
        return VehicleType.car;
    }
  }

  static String _vehicleTypeToString(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return 'bike';
      case VehicleType.motorcycle:
        return 'motorcycle';
      case VehicleType.car:
        return 'car';
      case VehicleType.van:
        return 'van';
    }
  }
}
