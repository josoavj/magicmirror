/// Service pour gérer la connectivité réseau
/// À implémenter avec connectivity_plus

abstract class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> onConnectivityChanged();
}

class ConnectivityServiceImpl implements ConnectivityService {
  @override
  Future<bool> isConnected() async {
    // À implémenter
    return true;
  }

  @override
  Stream<bool> onConnectivityChanged() {
    // À implémenter
    return Stream.value(true);
  }
}
