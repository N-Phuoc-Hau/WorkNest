class CompanyModel {
  final int id;
  final String name;
  final String? taxCode;
  final String description;
  final String location;
  final bool isVerified;
  final bool isActive;
  final List<String> images;
  final String? website;
  final String? phone;
  final String? email;
  final String? industry;
  final String? size;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  CompanyModel({
    required this.id,
    required this.name,
    this.taxCode,
    required this.description,
    required this.location,
    required this.isVerified,
    required this.isActive,
    required this.images,
    this.website,
    this.phone,
    this.email,
    this.industry,
    this.size,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'],
      taxCode: json['taxCode'],
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      images: List<String>.from(json['images'] ?? []),
      website: json['website'],
      phone: json['phone'],
      email: json['email'],
      industry: json['industry'],
      size: json['size'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      userId: json['userId'],
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
      'isActive': isActive,
      'images': images,
      'website': website,
      'phone': phone,
      'email': email,
      'industry': industry,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  CompanyModel copyWith({
    int? id,
    String? name,
    String? taxCode,
    String? description,
    String? location,
    bool? isVerified,
    bool? isActive,
    List<String>? images,
    String? website,
    String? phone,
    String? email,
    String? industry,
    String? size,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      taxCode: taxCode ?? this.taxCode,
      description: description ?? this.description,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}

class UpdateCompanyModel {
  final String? name;
  final String? taxCode;
  final String? description;
  final String? location;
  final String? website;
  final String? phone;
  final String? email;
  final String? industry;
  final String? size;

  UpdateCompanyModel({
    this.name,
    this.taxCode,
    this.description,
    this.location,
    this.website,
    this.phone,
    this.email,
    this.industry,
    this.size,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (taxCode != null) data['taxCode'] = taxCode;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (website != null) data['website'] = website;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (industry != null) data['industry'] = industry;
    if (size != null) data['size'] = size;
    
    return data;
  }
}

class CreateCompanyModel {
  final String name;
  final String? taxCode;
  final String description;
  final String location;
  final String? website;
  final String? phone;
  final String? email;
  final String? industry;
  final String? size;

  CreateCompanyModel({
    required this.name,
    this.taxCode,
    required this.description,
    required this.location,
    this.website,
    this.phone,
    this.email,
    this.industry,
    this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'taxCode': taxCode,
      'description': description,
      'location': location,
      'website': website,
      'phone': phone,
      'email': email,
      'industry': industry,
      'size': size,
    };
  }
} 