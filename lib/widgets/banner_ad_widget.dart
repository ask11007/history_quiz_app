import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sizer/sizer.dart';

import '../core/services/ad_service.dart';

/// Reusable banner ad widget with adaptive sizing and auto-refresh
/// Ensures ads are always displayed with proper error handling
class BannerAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool enableAutoRefresh;
  final String refreshKey;
  final AdSize? customAdSize;
  final String? customAdUnitId;
  final double? maxHeight;

  const BannerAdWidget({
    Key? key,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.enableAutoRefresh = true,
    this.refreshKey = 'default',
    this.customAdSize,
    this.customAdUnitId,
    this.maxHeight,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.instance.isInitialized) {
      print('⚠️ AdService not initialized, retrying in 2 seconds...');
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) _loadAd();
      });
      return;
    }

    try {
      setState(() {
        _isAdLoaded = false;
        _isAdFailed = false;
        _errorMessage = '';
      });

      // Dispose existing ad
      _bannerAd?.dispose();

      // Create new banner ad with adaptive sizing
      _bannerAd = _createAdaptiveBannerAd();
      _bannerAd!.load();
    } catch (e) {
      print('❌ Error creating banner ad: $e');
      setState(() {
        _isAdFailed = true;
        _errorMessage = e.toString();
      });

      // Retry after delay
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) _loadAd();
      });
    }
  }

  BannerAd _createAdaptiveBannerAd() {
    final adSize = widget.customAdSize ?? _getOptimalAdSize();
    final adUnitId = widget.customAdUnitId ?? AdService.instance.bannerAdUnitId;

    return BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner ad loaded successfully: ${widget.refreshKey}');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdFailed = false;
            });

            // Setup auto-refresh if enabled
            if (widget.enableAutoRefresh) {
              _setupAutoRefresh();
            }
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load: $error');
          ad.dispose();

          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdFailed = true;
              _errorMessage = error.message;
            });

            // Aggressive retry - try again after short delay
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                print('🔄 Retrying banner ad load...');
                _loadAd();
              }
            });
          }
        },
        onAdOpened: (ad) {
          print('📱 Banner ad opened: ${widget.refreshKey}');
        },
        onAdClosed: (ad) {
          print('📱 Banner ad closed: ${widget.refreshKey}');
        },
        onAdImpression: (ad) {
          print('👁️ Banner ad impression: ${widget.refreshKey}');
        },
      ),
    );
  }

  AdSize _getOptimalAdSize() {
    try {
      // Get screen width
      final screenWidth = MediaQuery.of(context).size.width;

      if (screenWidth >= 728) {
        return AdSize.leaderboard; // 728x90
      } else if (screenWidth >= 468) {
        return AdSize.banner; // 320x50
      } else {
        // Try adaptive size for smaller screens
        final adaptiveSize = AdSize.getAnchoredAdaptiveBannerAdSize(
          Orientation.portrait,
          screenWidth.toInt(),
        );
        return adaptiveSize ?? AdSize.banner;
      }
    } catch (e) {
      print('⚠️ Error getting optimal ad size, using standard banner: $e');
      return AdSize.banner;
    }
  }

  void _setupAutoRefresh() {
    // Refresh ad every 2 minutes
    Future.delayed(Duration(minutes: 2), () {
      if (mounted && widget.enableAutoRefresh) {
        print('🔄 Auto-refreshing banner ad: ${widget.refreshKey}');
        _loadAd();
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always return a container, even if ad is not loaded
    return Container(
      margin:
          widget.margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: widget.padding,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    if (_isAdLoaded && _bannerAd != null) {
      // Ad loaded successfully
      final adHeight = widget.customAdSize?.height.toDouble() ??
          _bannerAd!.size.height.toDouble();
      final maxHeight = widget.maxHeight ?? adHeight;

      return Container(
        height: maxHeight,
        child: AdWidget(ad: _bannerAd!),
      );
    } else if (_isAdFailed) {
      // Ad failed to load - show placeholder with retry
      return Container(
        height: 60.0, // Standard banner height
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                'Loading ad...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Ad is loading - show loading indicator
      return Container(
        height: 60.0, // Standard banner height
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Loading ad...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Medium rectangle ad widget for quiz results
class MediumRectangleAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool enableAutoRefresh;

  const MediumRectangleAdWidget({
    Key? key,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.enableAutoRefresh = true,
  }) : super(key: key);

  @override
  State<MediumRectangleAdWidget> createState() =>
      _MediumRectangleAdWidgetState();
}

class _MediumRectangleAdWidgetState extends State<MediumRectangleAdWidget> {
  BannerAd? _mediumRectangleAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.instance.isInitialized) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) _loadAd();
      });
      return;
    }

    try {
      setState(() {
        _isAdLoaded = false;
        _isAdFailed = false;
      });

      _mediumRectangleAd?.dispose();
      _mediumRectangleAd = AdService.instance.createMediumRectangleAd(
        enableAutoRefresh: widget.enableAutoRefresh,
      );

      // Add our own listener to update UI state
      _mediumRectangleAd!.listener = BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Medium rectangle ad loaded');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Medium rectangle ad failed: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdFailed = true;
            });

            // Retry
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) _loadAd();
            });
          }
        },
      );

      _mediumRectangleAd!.load();
    } catch (e) {
      print('❌ Error creating medium rectangle ad: $e');
      setState(() {
        _isAdFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _mediumRectangleAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.all(2.w),
      padding: widget.padding,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    if (_isAdLoaded && _mediumRectangleAd != null) {
      return Container(
        height: AdSize.mediumRectangle.height.toDouble(), // 300x250
        child: AdWidget(ad: _mediumRectangleAd!),
      );
    } else if (_isAdFailed) {
      return Container(
        height: AdSize.mediumRectangle.height.toDouble(),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 1.h),
              Text(
                'Loading ad...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        height: AdSize.mediumRectangle.height.toDouble(),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Loading ad...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
