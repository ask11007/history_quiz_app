# AdMob Integration Guide for Polity 5000+

## 📱 Overview
This guide covers the complete Google AdMob integration implemented in your Polity 5000+ quiz app, including setup, configuration, and monetization strategy.

## 🎯 Ad Placement Strategy

### **1. Banner Ads**
- **Home Screen**: Below user greeting, above subject selection
- **Account Screen**: Below profile header, above settings
- **Size**: 320x50 standard banner
- **Revenue**: Continuous passive income

### **2. Interstitial Ads** 
- **Quiz Completion**: After user finishes a quiz (highest converting moment)
- **Subject Navigation**: Before entering sub-topic selection (every 3rd navigation)
- **Frequency Control**: Maximum 1 every 5 minutes, every 3 user actions
- **Revenue**: High-impact, premium placement

### **3. Rewarded Video Ads**
- **Quiz Retry Feature**: Allow users to retry wrong answers after watching ad
- **Value Exchange**: Clear benefit to user (second chance at questions)
- **Revenue**: Highest CPM, voluntary engagement

## 🔧 Technical Implementation

### **Files Created/Modified**

#### New Files:
1. **`lib/core/services/ad_service.dart`** - Main AdMob service
2. **`lib/widgets/banner_ad_widget.dart`** - Reusable banner ad component

#### Modified Files:
1. **`pubspec.yaml`** - Added `google_mobile_ads: ^5.1.0`
2. **`android/app/src/main/AndroidManifest.xml`** - Added AdMob App ID and permissions
3. **`lib/main.dart`** - Initialize AdMob on app startup
4. **`lib/presentation/home_screen/home_screen.dart`** - Banner ad + interstitial logic
5. **`lib/presentation/account_screen/account_screen.dart`** - Banner ad
6. **`lib/presentation/quiz_screen/quiz_screen.dart`** - Interstitial + rewarded ads
7. **`lib/core/models/quiz_state_model.dart`** - Added reset functionality for retry feature

## 🚀 Setup Instructions

### **1. Google AdMob Account Setup**

1. **Create AdMob Account**:
   - Go to [https://admob.google.com](https://admob.google.com)
   - Sign in with Google account
   - Create new app for "Polity 5000+"

2. **Get Your App ID**:
   - Replace test App ID in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="YOUR_ACTUAL_APP_ID"/>
   ```

3. **Create Ad Units**:
   - **Banner Ad Unit**: For home/account screens
   - **Interstitial Ad Unit**: For quiz completion/navigation
   - **Rewarded Ad Unit**: For quiz retry feature

### **2. Update Ad Unit IDs**

In `lib/core/services/ad_service.dart`, replace test IDs:

```dart
// Replace these with your actual AdMob unit IDs
static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';

// Switch to production
static const bool _useTestAds = false; // Change to false for production
```

### **3. Testing Setup**

For testing, current configuration uses test ad units:
- Test ads will show "Test Ad" label
- No real revenue is generated
- Safe for development and testing

## 📊 Revenue Optimization

### **Current Settings**
- **Interstitial Frequency**: Every 3 user actions
- **Interstitial Cooldown**: 5 minutes minimum
- **Banner Refresh**: Every 60 seconds
- **Rewarded Ads**: On-demand (user initiated)

### **Expected Performance** (Based on quiz app benchmarks)
- **Daily Active Users**: 1000
- **Banner Ads**: $0.50-2.00 CPM → $30-120/month
- **Interstitials**: $2.00-8.00 CPM → $100-400/month  
- **Rewarded Video**: $10.00-25.00 CPM → $50-200/month
- **Total Estimated**: $180-720/month

### **Optimization Tips**
1. **A/B Testing**: Test different ad frequencies
2. **User Segmentation**: Show more ads to engaged users
3. **Seasonal Adjustments**: Increase frequency during peak usage
4. **Ad Mediation**: Consider adding Facebook Audience Network later

## 🎮 User Experience Features

### **Smart Frequency Control**
- Ads don't interrupt active quiz taking
- Respect user engagement patterns
- Cooldown periods prevent ad fatigue

### **Rewarded Value Exchange**
- Clear benefit: retry wrong quiz answers
- Voluntary engagement increases user satisfaction
- Higher completion rates = better revenue

### **Loading States**
- Smooth loading animations for banner ads
- Graceful fallbacks if ads fail to load
- No impact on app functionality if ads unavailable

## 🔍 Monitoring & Analytics

### **Key Metrics to Track**
1. **Ad Impressions**: Total ads shown
2. **Click-Through Rate (CTR)**: User engagement with ads
3. **eCPM**: Effective cost per mille (revenue efficiency)
4. **Fill Rate**: Percentage of ad requests fulfilled
5. **User Retention**: Impact of ads on user experience

### **AdMob Console**
- Monitor performance at [https://admob.google.com](https://admob.google.com)
- Set up automated reports
- Track revenue trends

## 🚨 Important Notes

### **Compliance**
- **COPPA Compliance**: Set `TagForChildDirectedTreatment.no` (current setup)
- **GDPR Compliance**: May need additional consent management for EU users
- **Play Store Policy**: Ensure ad content meets Google Play policies

### **Testing Checklist**
- [ ] Test ads load properly on different devices
- [ ] Verify interstitial frequency works correctly
- [ ] Test rewarded ad retry functionality
- [ ] Check app performance with ads enabled
- [ ] Validate ad revenue in AdMob console

### **Production Deployment**
1. Switch `_useTestAds` to `false`
2. Replace all test ad unit IDs with production IDs
3. Update AdMob App ID in manifest
4. Test thoroughly on release build
5. Monitor initial performance closely

## 🎯 Next Steps

1. **Immediate**: Test current implementation with test ads
2. **Week 1**: Create AdMob account and get production ad unit IDs
3. **Week 2**: Deploy to production and monitor performance
4. **Month 1**: Optimize based on performance data
5. **Future**: Consider additional ad formats (native ads, video ads)

## 💡 Advanced Features (Future)

### **Native Ads**
- Integrate into subject card grid
- Match app's glassmorphism design
- Higher user engagement

### **Ad Mediation**
- Facebook Audience Network
- Unity Ads  
- AppLovin
- Increase fill rates and revenue

### **Dynamic Ad Frequency**
- AI-powered frequency optimization
- User behavior analysis
- Personalized ad experience

---

**Ready to monetize your quiz app! 🚀**

The implementation is complete and ready for testing. Switch to production ad units when ready to start earning revenue.