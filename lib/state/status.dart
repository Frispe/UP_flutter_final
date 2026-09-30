enum LoadStatus { idle, loading, success, empty, error }

String errorText(Object error) {
  if (error is ArgumentError) return error.message?.toString() ?? 'Некорректные данные';
  if (error is StateError) return error.message;
  return 'Не удалось выполнить действие. Попробуйте ещё раз.';
}
