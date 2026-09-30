class Brand {
  const Brand({required this.id, required this.name, this.deletedAt});

  final int id;
  final String name;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Brand copyWith({
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
