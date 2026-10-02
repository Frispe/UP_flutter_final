String readString(Object? value) {
  return value is String ? value : '';
}

int? readNullableInt(Object? value) {
  if (value is int) {
    return value.abs() <= 9007199254740991 ? value : null;
  }
  if (value is num &&
      value.isFinite &&
      value.abs() <= 9007199254740991 &&
      value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (value is String) {
    final number = int.tryParse(value.trim());
    if (number != null && number.abs() <= 9007199254740991) {
      return number;
    }
  }
  return null;
}

int readInt(Object? value) => readNullableInt(value) ?? 0;

DateTime? readDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

List<int> readIds(Object? value) {
  if (value is! List) {
    return const [];
  }
  final ids = <int>{};
  for (final item in value) {
    final id = readNullableInt(item);
    if (id != null && id > 0) {
      ids.add(id);
    }
  }
  return List<int>.unmodifiable(ids);
}
