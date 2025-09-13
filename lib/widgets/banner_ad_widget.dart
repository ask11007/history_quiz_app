import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sizer/sizer.dart';

import '../core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool isPersistent; // New flag for persistent display

  const BannerAdWidget({
    Key? key,
    this.adSize = AdSize.banner,
    this.margin,
    this.backgroundColor,
    this.isPersistent = true, // Default to persistent
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasAdError = false;

  @override
  bool get wantKeepAlive => widget.isPersistent; // Keep alive if persistent

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (!AdService.instance.isInitialized) {
      print('AdService not initialized, cannot load banner ad');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: widget.adSize,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _hasAdError = false;
            });
          }
          print('✅ Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _hasAdError = true;
            });
          }
          print('❌ Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
        onAdOpened: (ad) => print('🔥 Banner ad opened'),
        onAdClosed: (ad) => print('📭 Banner ad closed'),
        onAdClicked: (ad) => print('👆 Banner ad clicked'),
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Don't show anything if ad service is not initialized
    if (!AdService.instance.isInitialized) {
      return SizedBox.shrink();
    }

    // Show loading state while ad is loading
    if (!_isAdLoaded && !_hasAdError) {
      return Container(
        height: widget.adSize.height.toDouble(),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
              SizedBox(
                width: 4.w,
                height: 4.w,
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

    // Don't show anything if ad failed to load
    if (_hasAdError || _bannerAd == null) {
      return SizedBox.shrink();
    }

    // Show the actual ad
    return Container(
      height: widget.adSize.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
