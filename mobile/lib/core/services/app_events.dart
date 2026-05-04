import 'package:flutter/foundation.dart';

/// Farklı navigator scope'larından birbirini tetikleyemeyen widget'lar
/// arasında iletişim için GetIt singleton event bus.
class AppEvents extends ChangeNotifier {
  void transactionAdded() => notifyListeners();
}
