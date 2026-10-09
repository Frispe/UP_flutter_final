class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    this.customerId,
  });

  final int id;
  final String username;
  final String name;
  final String email;
  final String role;
  final int? customerId;

  bool get isCustomer => role == 'customer';
  bool get isManager => role == 'manager';
  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    username: json['username'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'customer',
    customerId: json['customerId'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'email': email,
    'role': role,
    'customerId': customerId,
  };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.startedAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime startedAt;
  final AuthUser user;

  bool get accessExpired => DateTime.now().isAfter(expiresAt);

  factory AuthSession.fromResponse(
    Map<String, dynamic> json, {
    DateTime? startedAt,
  }) {
    final seconds = json['expiresIn'] as int? ?? 0;
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
      startedAt: startedAt ?? DateTime.now(),
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    startedAt: json['startedAt'] is String
        ? DateTime.parse(json['startedAt'] as String)
        : DateTime.now(),
    user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'startedAt': startedAt.toIso8601String(),
    'user': user.toJson(),
  };
}
