import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../theme/theme_provider.dart';
import '../providers/user_provider.dart';
import '../core/services/supabase_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/ad_service.dart';
import '../presentation/auth/auth_screen.dart';
import '../presentation/auth/profile_setup_screen.dart';
import '../presentation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob first for Indian market
  print('🚀 Initializing AdMob for Indian market...');
  await AdService.instance.initialize();

  // Start Supabase initialization in parallel (don't wait for it)
  SupabaseService.initialize().catchError((e) {
    print('Supabase initialization failed: $e');
  });

  // Initialize connectivity service
  ConnectivityService().initialize();

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Sizer(builder: (context, orientation, screenType) {
          return MaterialApp(
            title: 'Polity 5000+',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
            // 🚨 END CRITICAL SECTION
            debugShowCheckedModeBanner: false,
            home: AuthWrapper(),
            routes: AppRoutes.routes,
          );
        });
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Debug logging for authentication state
        print('=== AuthWrapper Decision ===');
        print('Is loading: ${userProvider.isLoading}');
        print('Is authenticated: ${userProvider.isAuthenticated}');
        print('Current user: ${userProvider.currentUser?.id}');
        print('User name: ${userProvider.userName}');
        print('Needs profile setup: ${userProvider.needsProfileSetup}');
        print('==============================');

        // Show loading screen while checking authentication
        if (userProvider.isLoading) {
          print('AuthWrapper: Showing loading screen');
          return _buildLoadingScreen(context);
        }

        // Route based on authentication status
        if (userProvider.isAuthenticated) {
          // Check if user needs profile setup
          if (userProvider.needsProfileSetup) {
            print('AuthWrapper: Routing to ProfileSetupScreen');
            return ProfileSetupScreen();
          }
          print('AuthWrapper: Routing to MainNavigationScreen');
          return MainNavigationScreen();
        } else {
          print('AuthWrapper: Routing to AuthScreen');
          return AuthScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // Changed to circular shape
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('App icon failed to load in main.dart: $error');
                    // Fallback to colored container with quiz icon
                    return Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle, // Changed to circular shape
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(2.w),
                        child: CustomIconWidget(
                          iconName: 'quiz',
                          color: Colors.white,
                          size: 10.w,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Polity 5000+',
              style: GoogleFonts.cabin(
                fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
            SizedBox(height: 2.h),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading your quizzes...',
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
