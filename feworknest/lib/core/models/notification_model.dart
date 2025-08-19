class NotificationModel {
  final int id;
  final String? userId;
  final String title;
  final String message;
  final String? type;
  final String? relatedEntityId;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.userId,
    this.type,
    this.relatedEntityId,
    this.actionUrl,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['userId'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      actionUrl: json['actionUrl'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedEntityId': relatedEntityId,
      'actionUrl': actionUrl,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedEntityId,
    String? actionUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DeviceTokenModel {
  final String fcmToken;
  final String deviceType;
  final String? deviceName;

  const DeviceTokenModel({
    required this.fcmToken,
    required this.deviceType,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'fcmToken': fcmToken,
      'deviceType': deviceType,
      if (deviceName != null) 'deviceName': deviceName,
    };
  }
}

class UserDeviceModel {
  final int id;
  final String userId;
  final String fcmToken;
  final String deviceType;
  final String? deviceName;
  final bool isActive;
  final DateTime lastUsed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserDeviceModel({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.deviceType,
    required this.isActive,
    required this.lastUsed,
    required this.createdAt,
    this.deviceName,
    this.updatedAt,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      id: json['id'] as int,
      userId: json['userId'] as String,
      fcmToken: json['fcmToken'] as String,
      deviceType: json['deviceType'] as String,
      deviceName: json['deviceName'] as String?,
      isActive: json['isActive'] as bool,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fcmToken': fcmToken,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'isActive': isActive,
      'lastUsed': lastUsed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final List<UserDeviceModel> devices;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    List<UserDeviceModel>? devices,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
