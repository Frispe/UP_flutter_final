import 'package:flutter/foundation.dart';

class StorageState extends ChangeNotifier {
  StorageState(this.message);

  String? message;

  void dismiss() {
    message = null;
    notifyListeners();
  }
}
