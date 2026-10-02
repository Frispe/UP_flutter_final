import 'json.dart';

class Category {
  const Category({required this.id, required this.name, this.deletedAt});

  final int id;
  final String name;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: readInt(json['id']),
      name: readString(json['name']),
      deletedAt: readDate(json['deletedAt']),
    );
  }
}
