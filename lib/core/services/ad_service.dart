import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob service for Indian market with aggressive ad display
/// Ensures ads are shown every time with proper refresh cycles
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static AdService get instance => _instance;

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Test mode configuration - set to false for production
  static const bool _useTestAds = true; // 🔴 CHANGE TO FALSE FOR PRODUCTION

  // Retry attempt tracking
  static int _bannerRetryCount = 0;
  static const int _maxRetryAttempts = 3;

  // Rate limiting protection
  static DateTime? _lastFailedRequest;
  static const Duration _rateLimitCooldown = Duration(minutes: 5);

  // Test Ad Unit IDs (Google's test IDs for development)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testMediumRectangleAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Production Ad Unit IDs - Replace with your actual AdMob unit IDs
  static const String _prodBannerAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodMediumRectangleAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Current ad unit IDs based on test/production mode
  String get bannerAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get mediumRectangleAdUnitId =>
      _useTestAds ? _testMediumRectangleAdUnitId : _prodMediumRectangleAdUnitId;

  // Ad refresh configuration - Optimized for production
  static const Duration _bannerRefreshInterval = Duration(minutes: 3);
  static const Duration _interstitialCooldown = Duration(minutes: 2);
  static const Duration _retryDelay =
      Duration(seconds: 30); // Increased retry delay

  // Interstitial ad management
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  DateTime? _lastInterstitialShow;

  // Banner ad refresh timers
  final Map<String, Timer?> _bannerRefreshTimers = {};

  /// Initialize AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ AdMob already initialized');
      return;
    }

    try {
      print('🚀 Initializing AdMob for Indian market...');

      await MobileAds.instance.initialize();

      // Configure for Indian audience
      await _configureForIndianMarket();

      _isInitialized = true;
      print('✅ AdMob initialized successfully');

      // Preload interstitial ad
      _loadInterstitialAd();
    } catch (e) {
      print('❌ Failed to initialize AdMob: $e');
      _isInitialized = false;
    }
  }

  /// Configure AdMob settings for Indian market
  Future<void> _configureForIndianMarket() async {
    try {
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        testDeviceIds: _useTestAds ? ['TEST_DEVICE_ID'] : null,
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      print('🇮🇳 Configured AdMob for Indian market');
    } catch (e) {
      print('⚠️ Failed to configure AdMob settings: $e');
    }
  }

  /// Reset retry counter on successful ad load
  void _resetRetryCounter() {
    _bannerRetryCount = 0;
    _lastFailedRequest = null;
  }

  /// Increment retry counter on ad failure
  void _incrementRetryCounter() {
    _bannerRetryCount++;
    _lastFailedRequest = DateTime.now();
  }

  /// Check if we should attempt to load ads (rate limiting protection)
  bool _shouldAttemptAdLoad() {
    if (_lastFailedRequest != null) {
      final timeSinceLastFailure =
          DateTime.now().difference(_lastFailedRequest!);
      if (timeSinceLastFailure < _rateLimitCooldown) {
        print(
            '⏰ Rate limit cooldown active. Time remaining: ${_rateLimitCooldown.inMinutes - timeSinceLastFailure.inMinutes} minutes');
        return false;
      }
    }
    return _bannerRetryCount < _maxRetryAttempts;
  }

  /// Create banner ad with adaptive sizing and auto-refresh
  BannerAd createBannerAd({
    String? customAdUnitId,
    AdSize? customSize,
    bool enableAutoRefresh = true,
    String refreshKey = 'default',
  }) {
    if (!_isInitialized) {
      throw Exception('AdService not initialized. Call initialize() first.');
    }

    final adUnitId = customAdUnitId ?? bannerAdUnitId;
    final adSize = customSize ?? AdSize.banner;

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner ad loaded: $refreshKey');
          _resetRetryCounter(); // Reset retry counter on success

          // Setup auto-refresh if enabled
          if (enableAutoRefresh) {
            _setupBannerRefresh(
                ad as BannerAd, refreshKey, customAdUnitId, customSize);
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load: $error');
          ad.dispose();

          // Smart retry logic based on error code
          Duration retryDelay;
          if (error.code == 1) {
            // Rate limiting - wait longer
            retryDelay = Duration(minutes: 2);
            print('🕒 Rate limited, waiting 2 minutes before retry');
          } else if (error.code == 3) {
            // No fill - normal, retry with standard delay
            retryDelay = _retryDelay;
            print('📭 No fill available, retrying in 30 seconds');
          } else {
            // Other errors - standard retry
            retryDelay = Duration(seconds: 15);
          }

          // Retry loading after appropriate delay
          Timer(retryDelay, () {
            if (_isInitialized) {
              print(
                  '🔄 Retrying banner ad load after ${retryDelay.inSeconds}s delay...');
              final retryAd = createBannerAd(
                customAdUnitId: customAdUnitId,
                customSize: customSize,
                enableAutoRefresh: enableAutoRefresh,
                refreshKey: refreshKey,
              );
              retryAd.load();
            }
          });
        },
        onAdOpened: (ad) => print('📱 Banner ad opened'),
        onAdClosed: (ad) => print('📱 Banner ad closed'),
        onAdImpression: (ad) => print('👁️ Banner ad impression recorded'),
      ),
    );

    return bannerAd;
  }

  /// Setup automatic banner refresh
  void _setupBannerRefresh(BannerAd bannerAd, String refreshKey,
      String? customAdUnitId, AdSize? customSize) {
    // Cancel existing timer for this refresh key
    _bannerRefreshTimers[refreshKey]?.cancel();

    // Setup new refresh timer
    _bannerRefreshTimers[refreshKey] = Timer(_bannerRefreshInterval, () {
      if (_isInitialized && bannerAd != null) {
        print('🔄 Refreshing banner ad: $refreshKey');

        // Dispose current ad
        bannerAd.dispose();

        // Create and load new ad
        final newAd = createBannerAd(
          customAdUnitId: customAdUnitId,
          customSize: customSize,
          enableAutoRefresh: true,
          refreshKey: refreshKey,
        );
        newAd.load();
      }
    });
  }

  /// Create medium rectangle ad for quiz results
  BannerAd createMediumRectangleAd({bool enableAutoRefresh = true}) {
    return createBannerAd(
      customAdUnitId: mediumRectangleAdUnitId,
      customSize: AdSize.mediumRectangle,
      enableAutoRefresh: enableAutoRefresh,
      refreshKey: 'medium_rectangle',
    );
  }

  /// Create adaptive banner ad based on screen width
  BannerAd createAdaptiveBannerAd({
    required double screenWidth,
    bool enableAutoRefresh = true,
    String refreshKey = 'adaptive',
  }) {
    AdSize adSize;

    try {
      if (screenWidth >= 728) {
        adSize = AdSize.leaderboard; // 728x90
      } else if (screenWidth >= 468) {
        adSize = AdSize.banner; // 320x50
      } else {
        // For smaller screens, use standard banner (adaptive requires async)
        adSize = AdSize.banner;
      }
    } catch (e) {
      print('⚠️ Error creating adaptive ad size, using standard banner: $e');
      adSize = AdSize.banner;
    }

    return createBannerAd(
      customSize: adSize,
      enableAutoRefresh: enableAutoRefresh,
      refreshKey: refreshKey,
    );
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('✅ Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialReady = true;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                print('📱 Interstitial ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                print('📱 Interstitial ad dismissed');
                _isInterstitialReady = false;
                ad.dispose();
                _interstitialAd = null;

                // Load next interstitial ad
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Interstitial ad failed to show: $error');
                _isInterstitialReady = false;
                ad.dispose();
                _interstitialAd = null;

                // Load next interstitial ad
                _loadInterstitialAd();
              },
              onAdImpression: (ad) => print('👁️ Interstitial ad impression'),
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ Interstitial ad failed to load: $error');
            _isInterstitialReady = false;
            _interstitialAd = null;

            // Retry loading after delay
            Timer(Duration(seconds: 15), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('❌ Error loading interstitial ad: $e');
    }
  }

  /// Show interstitial ad if available and cooldown period has passed
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialReady || _interstitialAd == null) {
      print('⚠️ Interstitial ad not ready');
      return false;
    }

    // Check cooldown period
    if (_lastInterstitialShow != null) {
      final timeSinceLastShow =
          DateTime.now().difference(_lastInterstitialShow!);
      if (timeSinceLastShow < _interstitialCooldown) {
        print('⏰ Interstitial ad on cooldown');
        return false;
      }
    }

    try {
      await _interstitialAd!.show();
      _lastInterstitialShow = DateTime.now();
      print('✅ Interstitial ad shown successfully');
      return true;
    } catch (e) {
      print('❌ Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Force show interstitial (ignores cooldown) - for finish button
  Future<bool> forceShowInterstitialAd() async {
    if (!_isInitialized || !_isInterstitialReady || _interstitialAd == null) {
      print('⚠️ Interstitial ad not ready for force show');
      // Load new ad immediately
      _loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      _lastInterstitialShow = DateTime.now();
      print('✅ Interstitial ad force shown successfully');
      return true;
    } catch (e) {
      print('❌ Error force showing interstitial ad: $e');
      return false;
    }
  }

  /// Check if interstitial ad is ready
  bool get isInterstitialReady => _isInterstitialReady;

  /// Dispose all resources
  void dispose() {
    // Cancel all refresh timers
    _bannerRefreshTimers.values.forEach((timer) => timer?.cancel());
    _bannerRefreshTimers.clear();

    // Dispose interstitial ad
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;

    print('🧹 AdService disposed');
  }

  /// Get ad status for debugging
  Map<String, dynamic> getAdStatus() {
    return {
      'initialized': _isInitialized,
      'interstitial_ready': _isInterstitialReady,
      'active_banner_timers': _bannerRefreshTimers.length,
      'last_interstitial_show': _lastInterstitialShow?.toIso8601String(),
      'test_mode': _useTestAds,
    };
  }
}
