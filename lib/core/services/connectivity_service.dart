import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of network status. Emits true if online, false if offline.
  Stream<bool> get isOnlineStream => _connectivity.onConnectivityChanged.map(
        (results) => _hasConnection(results),
      );

  /// Get current network status.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // Returns true if there is any active connection (WiFi, Mobile, Ethernet, VPN, etc.)
    return results.any((result) => result != ConnectivityResult.none);
  }
}
