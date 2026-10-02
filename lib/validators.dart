class Validators {
  static String? text(
    String? value, {
    int min = 1,
    int max = 100,
    bool required = true,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? 'Заполните поле' : null;
    }
    if (text.length < min || text.length > max) {
      return 'Допустимая длина: от $min до $max символов';
    }
    return null;
  }

  static String? email(String? value) {
    final error = text(value, max: 254);
    if (error != null) {
      return error;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
      return 'Введите почту в формате name@example.com';
    }
    return null;
  }

  static String? integer(String? value, {int min = 1, int max = 999}) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Введите целое число';
    }
    if (number < min || number > max) {
      return 'Введите число от $min до $max';
    }
    return null;
  }

  static int? priceValue(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }
    final parts = text.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Укажите цену';
    }
    if (priceValue(value) == null) {
      return 'Введите неотрицательную цену: до 9 цифр и 2 знаков после запятой';
    }
    return null;
  }

  static String? choice(int? value) {
    return value == null || value <= 0 ? 'Выберите значение' : null;
  }

  static String? choices(List<int>? values) {
    return values == null || values.isEmpty || values.any((id) => id <= 0)
        ? 'Выберите хотя бы одно значение'
        : null;
  }

  static String? unique(
    String? value,
    Iterable<String> existing, {
    String message = 'Такое значение уже существует',
  }) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return existing.any((item) => item.trim().toLowerCase() == text)
        ? message
        : null;
  }
}
