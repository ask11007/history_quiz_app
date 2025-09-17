# AdMob Integration Documentation

## Overview
This document describes the comprehensive AdMob integration implemented for the History Quiz App (Polity 5000+), specifically optimized for the Indian market with aggressive ad display to maximize revenue.

## Ad Strategy Summary

### Ad Types Implemented
1. **Banner Ads** - Always visible with auto-refresh every 2 minutes
2. **Interstitial Ads** - Full-screen ads on quiz completion
3. **Medium Rectangle Ads** - Custom size ads in quiz results

### Ad Placement Locations
1. **Home Screen**: Banner ad below user greeting
2. **Sub-Topic Screen**: Banner ad at bottom
3. **Account Screen**: Two banner ads (top and bottom)
4. **Quiz Results**: Medium rectangle ad below results
5. **Quiz Finish**: Full-screen interstitial ad

## Technical Implementation

### Dependencies Added
```yaml
google_mobile_ads: ^5.1.0
```

### Android Configuration
Added to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

### Core Components

#### 1. AdService (`lib/core/services/ad_service.dart`)
- Centralized service for all ad operations
- Singleton pattern for consistency
- Auto-refresh capabilities for banner ads
- Interstitial ad preloading and management
- Indian market optimization settings

**Key Features:**
- Test mode enabled for development
- Aggressive refresh intervals (2 minutes for banners)
- Force show interstitial for quiz finish
- Comprehensive error handling and retry logic
- Child-directed treatment set to 'No' for Indian audience

#### 2. BannerAdWidget (`lib/widgets/banner_ad_widget.dart`)
- Reusable banner ad component
- Adaptive sizing based on screen width
- Auto-refresh functionality
- Fallback UI for failed loads
- Loading states with indicators

**Features:**
- Responsive design (320x50 to 728x90)
- Automatic retry on failures
- Customizable refresh keys
- Error state handling

#### 3. MediumRectangleAdWidget (`lib/widgets/banner_ad_widget.dart`)
- Custom 300x250 rectangle ads
- Used in quiz results dialog
- Auto-refresh enabled
- Same error handling as banner ads

### Ad Placement Details

#### Home Screen
```dart
BannerAdWidget(
  refreshKey: 'home_screen',
  enableAutoRefresh: true,
  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
)
```
- **Location**: Below user greeting widget
- **Type**: Adaptive banner
- **Refresh**: Every 2 minutes
- **Always Visible**: Yes

#### Sub-Topic Screen
```dart
BannerAdWidget(
  refreshKey: 'subtopic_screen',
  enableAutoRefresh: true,
  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
)
```
- **Location**: Bottom of screen
- **Type**: Standard banner
- **Refresh**: Every 2 minutes
- **Always Visible**: Yes

#### Account Screen
Two banner ads implemented:
1. **Top Banner**: Below profile header
2. **Bottom Banner**: Before sign-out button

```dart
// Top banner
BannerAdWidget(
  refreshKey: 'account_screen_top',
  enableAutoRefresh: true,
)

// Bottom banner
BannerAdWidget(
  refreshKey: 'account_screen_bottom',
  enableAutoRefresh: true,
)
```

#### Quiz Screen - Finish Button
```dart
void _finishQuiz() {
  AdService.instance.forceShowInterstitialAd().then((adShown) => {
    _showQuizResults();
  });
}
```
- **Type**: Full-screen interstitial
- **Trigger**: When user clicks finish button
- **Behavior**: Force show (ignores cooldown)
- **Always Shows**: Yes (if ad is loaded)

#### Quiz Results Dialog
```dart
MediumRectangleAdWidget(
  enableAutoRefresh: true,
  margin: EdgeInsets.symmetric(horizontal: 2.w),
)
```
- **Location**: Below quiz statistics
- **Type**: Medium rectangle (300x250)
- **Refresh**: Every 2 minutes
- **Always Visible**: Yes

## Configuration Settings

### Test Mode
Currently enabled for development:
```dart
static const bool _useTestAds = true; // Set to false for production
```

### Ad Unit IDs
**Test IDs (Currently Active):**
- Banner: `ca-app-pub-3940256099942544/6300978111`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Medium Rectangle: `ca-app-pub-3940256099942544/6300978111`

**Production IDs (Replace before publishing):**
```dart
static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static const String _prodMediumRectangleAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

### Refresh Intervals
```dart
static const Duration _bannerRefreshInterval = Duration(minutes: 2);
static const Duration _interstitialCooldown = Duration(minutes: 1);
```

## User Experience Features

### Aggressive Display Strategy
- **Always Show Ads**: Ads are displayed on every screen load
- **Fast Refresh**: 2-minute intervals ensure fresh ad content
- **Immediate Retry**: Failed ads retry after 3-5 seconds
- **Force Display**: Interstitial ads always show on quiz finish
- **No Skip Options**: Users must view full ad content

### Error Handling
- Graceful fallbacks for failed ad loads
- Loading indicators during ad fetch
- Automatic retry mechanisms
- Placeholder content when ads fail

### Performance Optimization
- Preloading of interstitial ads
- Parallel initialization with app startup
- Minimal impact on app functionality
- Responsive design for all screen sizes

## Revenue Optimization

### Indian Market Focus
- Configured for Indian audience (not child-directed)
- Optimized ad formats for mobile devices
- High-frequency display for maximum impressions
- Multiple ad placements per screen

### Expected Performance
- **Banner eCPM**: $0.50 - $1.20
- **Interstitial eCPM**: $2.00 - $4.50
- **Medium Rectangle eCPM**: $1.00 - $2.50

## Deployment Checklist

Before publishing to Google Play Store:

1. **Replace Test Ad Units**: Update production ad unit IDs
2. **Disable Test Mode**: Set `_useTestAds = false`
3. **Update Manifest**: Verify AdMob app ID is correct
4. **Test Real Ads**: Ensure ads display correctly in release build
5. **Privacy Policy**: Update with AdMob data collection info
6. **Play Console**: Configure ad serving in Play Console

## Troubleshooting

### Common Issues
1. **Ads not showing**: Check internet connection and ad unit IDs
2. **Test ads in production**: Verify test mode is disabled
3. **Layout issues**: Check responsive design on different screen sizes
4. **Memory leaks**: Ensure proper ad disposal in widget dispose methods

### Debug Information
Use `AdService.instance.getAdStatus()` to check:
- Initialization status
- Interstitial readiness
- Active refresh timers
- Last interstitial show time
- Test mode status

## Performance Monitoring

### Key Metrics to Track
- Ad impression rates
- Click-through rates
- Revenue per session
- User retention impact
- App performance metrics

### Analytics Integration
The ad service provides comprehensive logging for:
- Ad load success/failure
- Ad display events
- Refresh cycles
- User interactions

This implementation ensures maximum ad revenue while maintaining app functionality and user experience standards for the Indian market.