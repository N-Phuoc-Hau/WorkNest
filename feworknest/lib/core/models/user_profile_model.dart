class UserProfileModel {
  final int id;
  final String userId;
  final String? position;
  final String? experience;
  final String? education;
  final String? skills;
  final String? bio;
  final String? address;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.userId,
    this.position,
    this.experience,
    this.education,
    this.skills,
    this.bio,
    this.address,
    this.dateOfBirth,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      userId: json['userId'] as String,
      position: json['position'] as String?,
      experience: json['experience'] as String?,
      education: json['education'] as String?,
      skills: json['skills'] as String?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'position': position,
      'experience': experience,
      'education': education,
      'skills': skills,
      'bio': bio,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    int? id,
    String? userId,
    String? position,
    String? experience,
    String? education,
    String? skills,
    String? bio,
    String? address,
    DateTime? dateOfBirth,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      position: position ?? this.position,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CreateUserProfileModel {
  final String? position;
  final String? experience;
  final String? education;
  final String? skills;
  final String? bio;
  final String? address;
  final DateTime? dateOfBirth;
  final String? phoneNumber;

  const CreateUserProfileModel({
    this.position,
    this.experience,
    this.education,
    this.skills,
    this.bio,
    this.address,
    this.dateOfBirth,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (position != null) 'position': position,
      if (experience != null) 'experience': experience,
      if (education != null) 'education': education,
      if (skills != null) 'skills': skills,
      if (bio != null) 'bio': bio,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}

class UpdateUserProfileModel {
  final String? position;
  final String? experience;
  final String? education;
  final String? skills;
  final String? bio;
  final String? address;
  final DateTime? dateOfBirth;
  final String? phoneNumber;

  const UpdateUserProfileModel({
    this.position,
    this.experience,
    this.education,
    this.skills,
    this.bio,
    this.address,
    this.dateOfBirth,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (position != null) 'position': position,
      if (experience != null) 'experience': experience,
      if (education != null) 'education': education,
      if (skills != null) 'skills': skills,
      if (bio != null) 'bio': bio,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
} 