import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Provides the raw stream of connectivity results
  Stream<ConnectivityResult> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  // Checks the current connectivity status
  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  // Helper to determine if online
  bool isOnline(ConnectivityResult result) {
     return result != ConnectivityResult.none;
  }
}