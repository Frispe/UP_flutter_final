class FormGuard {
  static final Map<String, Future<bool> Function()> _checks = {};

  static void register(String path, Future<bool> Function() check) {
    _checks[path] = check;
  }

  static void unregister(String path, Future<bool> Function() check) {
    if (_checks[path] == check) {
      _checks.remove(path);
    }
  }

  static Future<bool> allow(String path) async {
    final check = _checks[path];
    return check == null ? true : await check();
  }
}
