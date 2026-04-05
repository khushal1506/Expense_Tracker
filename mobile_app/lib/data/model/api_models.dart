class AuthResponse {
  final String token;
  final String type;
  final int expiresIn;
  final UserData user;

  AuthResponse({
    required this.token,
    required this.type,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      type: json['type'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 604800,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserData {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJson(json['data']) : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class SyncPushResponse {
  final int successCount;
  final List<String> skippedIds;

  SyncPushResponse({required this.successCount, required this.skippedIds});

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    return SyncPushResponse(
      successCount: json['successCount'] as int,
      skippedIds: List<String>.from(json['skippedIds'] as List? ?? []),
    );
  }
}

class SyncPullResponse {
  final List<dynamic> transactions;
  final List<dynamic> goals;
  final DateTime serverTime;

  SyncPullResponse({
    required this.transactions,
    required this.goals,
    required this.serverTime,
  });

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    return SyncPullResponse(
      transactions: json['transactions'] as List? ?? [],
      goals: json['goals'] as List? ?? [],
      serverTime: DateTime.parse(json['serverTime'] as String),
    );
  }
}
