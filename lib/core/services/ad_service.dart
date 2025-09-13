import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Ad unit IDs - Replace these with your actual AdMob unit IDs
  static const String _testAppId = 'ca-app-pub-3940256099942544~3347511713';

  // Test ad unit IDs for development
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production ad unit IDs - Replace with your actual IDs when ready
  static const String _prodBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Replace with actual
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Replace with actual
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Replace with actual

  // Current ad unit IDs (switch between test and production)
  static const bool _useTestAds = true; // Set to false for production

  String get bannerAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get rewardedAdUnitId =>
      _useTestAds ? _testRewardedAdUnitId : _prodRewardedAdUnitId;

  // Ad frequency control
  int _interstitialAdCounter = 0;
  DateTime? _lastInterstitialTime;
  static const int _interstitialFrequency = 3; // Show every 3 actions
  static const int _interstitialCooldown = 300; // 5 minutes in seconds

  // Ad instances
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  /// Initialize the Google Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      // Set request configuration for better ad targeting
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          testDeviceIds: kDebugMode
              ? ['YOUR_TEST_DEVICE_ID']
              : [], // Add your test device ID
        ),
      );

      _isInitialized = true;
      print('✅ AdMob initialized successfully');

      // Pre-load interstitial and rewarded ads
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      print('❌ Failed to initialize AdMob: $e');
      _isInitialized = false;
    }
  }

  /// Create a banner ad widget
  Widget createBannerAd({
    AdSize adSize = AdSize.banner,
    Function(Ad)? onAdLoaded,
    Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    if (!_isInitialized) {
      print('AdMob not initialized, showing empty container');
      return SizedBox.shrink();
    }

    return AdWidget(
      ad: BannerAd(
        adUnitId: bannerAdUnitId,
        size: adSize,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('✅ Banner ad loaded');
            onAdLoaded?.call(ad);
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Banner ad failed to load: $error');
            onAdFailedToLoad?.call(ad, error);
            ad.dispose();
          },
          onAdOpened: (ad) => print('🔥 Banner ad opened'),
          onAdClosed: (ad) => print('📭 Banner ad closed'),
        ),
      )..load(),
    );
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    if (!_isInitialized) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial ad loaded');
          _interstitialAd = ad;
          _setInterstitialAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setInterstitialAdCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => print('🔥 Interstitial ad showed'),
      onAdDismissedFullScreenContent: (ad) {
        print('📭 Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Load next ad
      },
    );
  }

  /// Show interstitial ad with frequency control
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || _interstitialAd == null) {
      print('⚠️ Interstitial ad not ready');
      return false;
    }

    // Check frequency control
    if (!_shouldShowInterstitial()) {
      print('⏰ Interstitial ad skipped due to frequency control');
      return false;
    }

    try {
      await _interstitialAd!.show();
      _interstitialAdCounter++;
      _lastInterstitialTime = DateTime.now();
      return true;
    } catch (e) {
      print('❌ Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Show interstitial ad without frequency control (for quiz completion)
  Future<bool> showInterstitialAdForced() async {
    if (!_isInitialized || _interstitialAd == null) {
      print('⚠️ Interstitial ad not ready');
      return false;
    }

    try {
      await _interstitialAd!.show();
      // Don't update counter or time for forced ads - allows repeated display
      return true;
    } catch (e) {
      print('❌ Error showing forced interstitial ad: $e');
      return false;
    }
  }

  bool _shouldShowInterstitial() {
    // Check frequency
    if (_interstitialAdCounter % _interstitialFrequency != 0) return false;

    // Check cooldown
    if (_lastInterstitialTime != null) {
      final timeDiff =
          DateTime.now().difference(_lastInterstitialTime!).inSeconds;
      if (timeDiff < _interstitialCooldown) return false;
    }

    return true;
  }

  /// Load rewarded ad
  void _loadRewardedAd() {
    if (!_isInitialized) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Rewarded ad loaded');
          _rewardedAd = ad;
          _setRewardedAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _setRewardedAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => print('🔥 Rewarded ad showed'),
      onAdDismissedFullScreenContent: (ad) {
        print('📭 Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Load next ad
      },
    );
  }

  /// Show rewarded ad
  Future<bool> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
  }) async {
    if (!_isInitialized || _rewardedAd == null) {
      print('⚠️ Rewarded ad not ready');
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onUserEarnedReward(reward);
        },
      );
      return true;
    } catch (e) {
      print('❌ Error showing rewarded ad: $e');
      return false;
    }
  }

  /// Check if rewarded ad is available
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Increment action counter for interstitial frequency
  void incrementActionCounter() {
    _interstitialAdCounter++;
  }

  /// Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
