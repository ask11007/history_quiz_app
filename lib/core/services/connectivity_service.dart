import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectionTestTimer;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Stream controller for real-time connectivity updates
  final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  // Callback for connectivity changes (deprecated - use stream instead)
  Function(bool)? onConnectivityChanged;

  /// Initialize connectivity monitoring with real internet testing
  Future<void> initialize() async {
    print('🌐 Initializing ConnectivityService with real internet testing...');

    // Check initial connectivity status with real internet test
    await _checkConnectivityWithInternetTest();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        print('📡 Network adapter status changed: $results');
        _handleConnectivityChange(results);
      },
    );

    // Start periodic internet connectivity testing
    _startPeriodicConnectivityTest();
  }

  /// Handle connectivity changes with immediate internet testing
  Future<void> _handleConnectivityChange(
      List<ConnectivityResult> results) async {
    // Check if we have network adapter connectivity
    final hasNetworkAdapter = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (!hasNetworkAdapter) {
      // No network adapter - definitely offline
      print('❌ No network adapter detected - offline');
      _updateConnectivityStatus(false);
    } else {
      // Network adapter detected - test real internet connectivity
      print(
          '📶 Network adapter detected - testing real internet connectivity...');
      await _checkConnectivityWithInternetTest();
    }
  }

  /// Check connectivity with actual internet test
  Future<void> _checkConnectivityWithInternetTest() async {
    try {
      // First check network adapter status
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final hasNetworkAdapter = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (!hasNetworkAdapter) {
        print('❌ No network adapter - offline');
        _updateConnectivityStatus(false);
        return;
      }

      // Test actual internet connectivity
      print('🔍 Testing real internet connectivity...');
      final hasInternet = await _testInternetConnection();
      _updateConnectivityStatus(hasInternet);
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      _updateConnectivityStatus(false);
    }
  }

  /// Test actual internet connection by trying to reach a reliable server
  Future<bool> _testInternetConnection() async {
    try {
      // Test multiple reliable servers with short timeout
      final List<String> testHosts = [
        'google.com',
        'cloudflare.com',
        'github.com'
      ];

      for (String host in testHosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 3));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('✅ Internet connectivity confirmed via $host');
            return true;
          }
        } catch (e) {
          print('⚠️ Failed to reach $host: $e');
          continue;
        }
      }

      print('❌ No internet connectivity - all test hosts failed');
      return false;
    } catch (e) {
      print('❌ Internet test error: $e');
      return false;
    }
  }

  /// Start periodic connectivity testing (every 3 seconds when offline, every 30 seconds when online)
  void _startPeriodicConnectivityTest() {
    _connectionTestTimer?.cancel();
    _connectionTestTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isConnected) {
        print('🔄 Periodic connectivity test (offline mode)...');
        await _checkConnectivityWithInternetTest();
      } else {
        // Less frequent checks when online (every 30 seconds)
        if (timer.tick % 10 == 0) {
          // Every 30 seconds (3 * 10)
          print('🔄 Periodic connectivity test (online verification)...');
          await _checkConnectivityWithInternetTest();
        }
      }
    });
  }

  void _updateConnectivityStatus(bool isConnected) {
    final wasConnected = _isConnected;
    _isConnected = isConnected;

    print('🌐 Connectivity status: ${_isConnected ? "ONLINE" : "OFFLINE"}');

    // Notify listeners if connectivity status changed
    if (wasConnected != _isConnected) {
      print('📡 Connectivity changed: $wasConnected → $_isConnected');

      // Notify via stream (preferred)
      _connectivityStreamController.add(_isConnected);

      // Notify via callback (legacy support)
      if (onConnectivityChanged != null) {
        onConnectivityChanged!(_isConnected);
      }
    }
  }

  /// Check if device has internet connection (with real internet test)
  Future<bool> hasInternetConnection() async {
    try {
      // First check network adapter
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final hasNetworkAdapter = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (!hasNetworkAdapter) {
        return false;
      }

      // Test actual internet connectivity
      return await _testInternetConnection();
    } catch (e) {
      print('❌ Error checking internet connection: $e');
      return false;
    }
  }

  /// Force an immediate connectivity check (useful for manual retries)
  Future<void> forceConnectivityCheck() async {
    print('🔄 Force connectivity check requested...');
    await _checkConnectivityWithInternetTest();
  }

  /// Dispose resources
  void dispose() {
    print('🔄 Disposing ConnectivityService...');
    _connectivitySubscription?.cancel();
    _connectionTestTimer?.cancel();
    _connectivityStreamController.close();
  }
}
