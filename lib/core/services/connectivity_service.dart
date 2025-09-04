import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Callback for connectivity changes
  Function(bool)? onConnectivityChanged;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectivityStatus(results);
      },
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
    }
  }

  /// Update connectivity status based on results
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    
    print('Connectivity status updated: $_isConnected');
    
    // Notify listeners if connectivity status changed
    if (wasConnected != _isConnected && onConnectivityChanged != null) {
      onConnectivityChanged!(_isConnected);
    }
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      return results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      print('Error checking internet connection: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
