import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/services/ad_service.dart';
import 'banner_ad_widget.dart';

/// Smart ad placement widget that adapts to different screen sizes and contexts
class SmartAdPlacementWidget extends StatefulWidget {
  final String placement; // 'home', 'quiz', 'results', 'account'
  final EdgeInsets? margin;
  final bool showImmediately;
  final Duration? delayBeforeShow;

  const SmartAdPlacementWidget({
    Key? key,
    required this.placement,
    this.margin,
    this.showImmediately = true,
    this.delayBeforeShow,
  }) : super(key: key);

  @override
  State<SmartAdPlacementWidget> createState() => _SmartAdPlacementWidgetState();
}

class _SmartAdPlacementWidgetState extends State<SmartAdPlacementWidget>
    with SingleTickerProviderStateMixin {
  bool _shouldShowAd = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _handleAdVisibility();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleAdVisibility() {
    if (widget.showImmediately) {
      setState(() {
        _shouldShowAd = true;
      });
      _animationController.forward();
    } else if (widget.delayBeforeShow != null) {
      Future.delayed(widget.delayBeforeShow!, () {
        if (mounted) {
          setState(() {
            _shouldShowAd = true;
          });
          _animationController.forward();
        }
      });
    }
  }

  /// Get optimal ad configuration based on placement and screen size
  Map<String, dynamic> _getAdConfig() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    switch (widget.placement) {
      case 'home':
        return {
          'adaptiveSize': true,
          'maxWidth': screenWidth * 0.9,
          'margin': EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          'backgroundColor':
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
        };

      case 'quiz':
        return {
          'adaptiveSize': true,
          'maxWidth': screenWidth * 0.95,
          'margin': EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          'backgroundColor': Colors.transparent,
        };

      case 'results':
        return {
          'adaptiveSize': true,
          'maxWidth': screenWidth * 0.85,
          'margin': EdgeInsets.all(3.w),
          'backgroundColor':
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        };

      case 'account':
        return {
          'adaptiveSize': true,
          'maxWidth': screenWidth * 0.9,
          'margin': EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          'backgroundColor': Theme.of(context).colorScheme.surface,
        };

      default:
        return {
          'adaptiveSize': true,
          'maxWidth': screenWidth * 0.9,
          'margin': EdgeInsets.all(2.w),
          'backgroundColor': Colors.transparent,
        };
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowAd || !AdService.instance.isInitialized) {
      return SizedBox.shrink();
    }

    final adConfig = _getAdConfig();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: widget.margin ?? adConfig['margin'],
        decoration: BoxDecoration(
          color: adConfig['backgroundColor'],
          borderRadius: BorderRadius.circular(8),
          boxShadow: widget.placement == 'results'
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: BannerAdWidget(
          adaptiveSize: adConfig['adaptiveSize'],
          maxWidth: adConfig['maxWidth'],
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// Floating ad widget for non-intrusive placements
class FloatingAdWidget extends StatefulWidget {
  final Widget child;
  final String placement;
  final Duration showAfter;

  const FloatingAdWidget({
    Key? key,
    required this.child,
    required this.placement,
    this.showAfter = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<FloatingAdWidget> createState() => _FloatingAdWidgetState();
}

class _FloatingAdWidgetState extends State<FloatingAdWidget>
    with TickerProviderStateMixin {
  bool _showFloatingAd = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startFloatingAdTimer();
  }

  void _initializeAnimation() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startFloatingAdTimer() {
    Future.delayed(widget.showAfter, () {
      if (mounted && AdService.instance.isInitialized) {
        setState(() {
          _showFloatingAd = true;
        });
        _slideController.forward();
      }
    });
  }

  void _hideFloatingAd() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showFloatingAd = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showFloatingAd)
          Positioned(
            bottom: 10.h,
            left: 4.w,
            right: 4.w,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _hideFloatingAd,
                          icon: Icon(
                            Icons.close,
                            size: 4.w,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    BannerAdWidget(
                      adaptiveSize: true,
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                      margin: EdgeInsets.only(bottom: 1.h),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
