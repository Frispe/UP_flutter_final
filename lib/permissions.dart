class AccessRules {
  static bool canOpen(String? role, String path) {
    if (role == 'admin') return true;
    if (role == 'manager') {
      return path != '/accounts' && path != '/statistics';
    }
    if (role != 'customer') return false;
    return path == '/' ||
        path == '/products' ||
        RegExp(r'^/products/\d+$').hasMatch(path) ||
        path == '/cart' ||
        path == '/orders' ||
        RegExp(r'^/orders/\d+$').hasMatch(path);
  }

  static bool canManageCatalog(String? role) =>
      role == 'manager' || role == 'admin';

  static bool canRestore(String? role) => role == 'admin';

  static bool canManageAccounts(String? role) => role == 'admin';
}
