import 'package:flutter_test/flutter_test.dart';

import 'package:digital_shop/permissions.dart';

void main() {
  group('доступ покупателя', () {
    test('открывает каталог и карточку товара', () {
      expect(AccessRules.canOpen('customer', '/products'), isTrue);
      expect(AccessRules.canOpen('customer', '/products/12'), isTrue);
    });

    test('открывает только свою корзину и заказы', () {
      expect(AccessRules.canOpen('customer', '/cart'), isTrue);
      expect(AccessRules.canOpen('customer', '/orders'), isTrue);
      expect(AccessRules.canOpen('customer', '/orders/3'), isTrue);
    });

    test('не открывает создание и изменение товара', () {
      expect(AccessRules.canOpen('customer', '/products/new'), isFalse);
      expect(AccessRules.canOpen('customer', '/products/2/edit'), isFalse);
    });

    test('не открывает пользователей и справочники', () {
      expect(AccessRules.canOpen('customer', '/users'), isFalse);
      expect(AccessRules.canOpen('customer', '/brands'), isFalse);
      expect(AccessRules.canOpen('customer', '/categories'), isFalse);
    });

    test('не получает административные возможности', () {
      expect(AccessRules.canManageCatalog('customer'), isFalse);
      expect(AccessRules.canRestore('customer'), isFalse);
      expect(AccessRules.canManageAccounts('customer'), isFalse);
    });
  });

  group('доступ менеджера', () {
    test('управляет каталогом и пользователями', () {
      expect(AccessRules.canOpen('manager', '/products/new'), isTrue);
      expect(AccessRules.canOpen('manager', '/users'), isTrue);
      expect(AccessRules.canManageCatalog('manager'), isTrue);
    });

    test('не управляет аккаунтами и восстановлением', () {
      expect(AccessRules.canOpen('manager', '/accounts'), isFalse);
      expect(AccessRules.canOpen('manager', '/statistics'), isFalse);
      expect(AccessRules.canRestore('manager'), isFalse);
    });
  });

  group('доступ администратора', () {
    test('открывает управление аккаунтами и статистику', () {
      expect(AccessRules.canOpen('admin', '/accounts'), isTrue);
      expect(AccessRules.canOpen('admin', '/statistics'), isTrue);
      expect(AccessRules.canManageAccounts('admin'), isTrue);
    });

    test('может управлять каталогом и восстановлением', () {
      expect(AccessRules.canManageCatalog('admin'), isTrue);
      expect(AccessRules.canRestore('admin'), isTrue);
    });
  });

  test('неизвестная роль не получает доступ', () {
    expect(AccessRules.canOpen('owner', '/products'), isFalse);
    expect(AccessRules.canOpen(null, '/products'), isFalse);
  });
}
