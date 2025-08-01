class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'candidate' hoặc 'recruiter'
  final String? avatar;
  final DateTime createdAt;
  final CompanyModel? company; // Chỉ có khi role = 'recruiter'

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatar,
    required this.createdAt,
    this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      company: json['company'] != null
          ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'company': company?.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? avatar,
    DateTime? createdAt,
    CompanyModel? company,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      company: company ?? this.company,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isRecruiter => role == 'recruiter';
  bool get isCandidate => role == 'candidate';
}

class CompanyModel {
  final int id;
  final String name;
  final String? taxCode;
  final String? description;
  final String? location;
  final bool isVerified;
  final List<String> images;

  const CompanyModel({
    required this.id,
    required this.name,
    this.taxCode,
    this.description,
    this.location,
    this.isVerified = false,
    this.images = const [],
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as int,
      name: json['name'] as String,
      taxCode: json['taxCode'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'taxCode': taxCode,
      'description': description,
      'location': location,
      'isVerified': isVerified,
      'images': images,
    };
  }

  CompanyModel copyWith({
    int? id,
    String? name,
    String? taxCode,
    String? description,
    String? location,
    bool? isVerified,
    List<String>? images,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      taxCode: taxCode ?? this.taxCode,
      description: description ?? this.description,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      images: images ?? this.images,
    );
  }
}

class AuthState {
  final UserModel? user;
  final String? accessToken;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.accessToken,
    this.isAuthenticated = false,
    this.isLoading = true, // Default to true for initial loading
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    String? accessToken,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Clear error method
  AuthState clearError() {
    return copyWith(error: null);
  }

  // Clear all auth data (logout)
  AuthState clear() {
    return const AuthState();
  }
}

enum UserRole { candidate, recruiter }
