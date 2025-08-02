import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String? primaryRole;
  final List<String>? roles;
  final bool? enableNotifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.location,
    this.primaryRole,
    this.roles,
    this.enableNotifications,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      primaryRole: json['primary_role'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>(),
      enableNotifications: json['enable_notifications'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'primary_role': primaryRole,
      'roles': roles,
      'enable_notifications': enableNotifications,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    String? primaryRole,
    List<String>? roles,
    bool? enableNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      primaryRole: primaryRole ?? this.primaryRole,
      roles: roles ?? this.roles,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        avatarUrl,
        bio,
        location,
        primaryRole,
        roles,
        enableNotifications,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ProfileModel(id: $id, fullName: $fullName, email: $email)';
  }

  // Helper getters
  String get displayName => fullName ?? email.split('@').first;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  bool get isProfileComplete {
    return fullName != null &&
        fullName!.isNotEmpty &&
        primaryRole != null &&
        primaryRole!.isNotEmpty;
  }

  String get memberSinceFormatted {
    if (createdAt == null) return 'New member';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Member for $years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Member for $months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      return 'Member for ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else {
      return 'New member';
    }
  }

  List<String> get availableRoles => [
        'renter',
        'lender',
        'driver',
      ];

  bool hasRole(String role) {
    return roles?.contains(role) ?? false;
  }
}
