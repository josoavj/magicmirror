import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> onConnectivityChanged();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<bool> onConnectivityChanged() {
    // BUG FIX #8: Implémenter correctement le Stream au lieu de Stream.value()
    // Map stream de ConnectivityResult vers bool (connecté ou pas)
    return _connectivity.onConnectivityChanged
        .map((List<ConnectivityResult> result) {
          return result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi);
        })
        .distinct() // Évite les doublons
        .asBroadcastStream(); // Permet multi-listeners
  }
}
