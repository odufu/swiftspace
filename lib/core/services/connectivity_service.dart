import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Returns true if there is an active internet connection (WiFi or Mobile)
  Future<bool> hasInternet() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Stream to listen for connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  /// Helper to check if any of the results indicate connectivity
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }
}
