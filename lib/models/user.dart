import 'json.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.nickname = '',
    this.deletedAt,
  });

  final int id;
  final String name;
  final String email;
  final String nickname;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  User copyWith({
    String? name,
    String? email,
    String? nickname,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'nickname': nickname,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: readInt(json['id']),
      name: readString(json['name']),
      email: readString(json['email']),
      nickname: readString(json['nickname']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
