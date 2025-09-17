import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/banner_ad_widget.dart';
import './widgets/subject_card_widget.dart';
import './widgets/user_greeting_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dynamic subjects data from Supabase
  static List<Map<String, dynamic>> _cachedSubjectsData = [];
  static bool _hasLoadedOnce = false;
  List<Map<String, dynamic>> _subjectsData = [];
  bool _isLoadingSubjects = false;
  bool _hasConnectionError = false;
  StreamSubscription<bool>? _connectivitySubscription;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();

    // Use cached data if available, otherwise load
    if (_hasLoadedOnce && _cachedSubjectsData.isNotEmpty) {
      setState(() {
        _subjectsData = List.from(_cachedSubjectsData);
        _isLoadingSubjects = false;
      });
      print(
          'Using cached subjects data (${_cachedSubjectsData.length} subjects)');
    } else {
      // Initialize connectivity service
      _connectivityService.initialize();

      // Listen for real-time connectivity changes via stream
      _connectivitySubscription =
          _connectivityService.connectivityStream.listen(
        (bool isConnected) {
          print('📡 Real-time connectivity changed: $isConnected');
          if (mounted) {
            if (isConnected) {
              // Connection restored - reload subjects immediately
              print('✅ Connection restored - reloading subjects...');
              setState(() {
                _hasConnectionError = false;
              });
              // Add small delay to ensure connectivity is stable
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted && !_isLoadingSubjects) {
                  _loadSubjects();
                }
              });
            } else {
              // Connection lost - show error immediately
              print('❌ Connection lost - showing offline state...');
              setState(() {
                _subjectsData = [];
                _isLoadingSubjects =
                    false; // CRITICAL: Stop any ongoing loading
                _hasConnectionError = true;
              });
            }
          }
        },
        onError: (error) {
          print('❌ Connectivity stream error: $error');
          if (mounted) {
            setState(() {
              _isLoadingSubjects = false; // Reset loading state on stream error
              _hasConnectionError = true;
            });
          }
        },
      );

      // Load subjects based on connectivity
      _loadSubjects();
    }
  }

  @override
  void dispose() {
    // Clean up connectivity listener
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectsFromSupabase() async {
    try {
      print('💾 Loading subjects from Supabase database...');

      // Reduce timeout for faster feedback
      final tags = await SupabaseService.getAvailableTags().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Supabase request timed out after 5 seconds');
          throw TimeoutException(
              'Supabase request timed out', const Duration(seconds: 5));
        },
      );

      // Always ensure loading state is reset
      if (!mounted) return;

      if (tags.isNotEmpty) {
        // Create subject data based on available tags
        final subjects = tags.map((tag) {
          // Map database tags to display names
          final tagMapping = {
            'GK': 'General Knowledge',
            'Math': 'Mathematics',
            'Reasoning': 'Reasoning',
          };

          final displayName = tagMapping[tag] ?? tag;

          // Define different colors for different subjects
          final colors = {
            'Mathematics': Color(0xFF4F46E5), // Indigo
            'General Knowledge': Color(0xFF16A34A), // Green
            'Reasoning': Color(0xFF8B5CF6), // Purple
            'Science': Color(0xFFDC2626), // Red
            'History': Color(0xFFEA580C), // Orange
            'Geography': Color(0xFF059669), // Emerald
            'Literature': Color(0xFF7C3AED), // Violet
            'Computer Science': Color(0xFF0891B2), // Cyan
          };

          // Define icons for different subjects
          final icons = {
            'Mathematics': 'calculate',
            'General Knowledge': 'public',
            'Reasoning': 'psychology',
            'Science': 'science',
            'History': 'history_edu',
            'Geography': 'public',
            'Literature': 'book',
            'Computer Science': 'computer',
          };

          return {
            "id": tags.indexOf(tag) + 1,
            "name": displayName, // Use the mapped display name
            "originalTag": tag, // Keep the original tag for database queries
            "icon": icons[displayName] ?? 'quiz',
            "backgroundColor": colors[displayName] ?? Color(0xFF6B7280),
            "totalQuestions": 0, // Will be updated when questions are fetched
            "bestScore": 0.0, // Will be updated from user progress
            "completedQuizzes": 0, // Will be updated from user progress
          };
        }).toList();

        setState(() {
          _subjectsData = subjects;
          _isLoadingSubjects = false; // CRITICAL: Always reset loading state
          _hasConnectionError = false; // Clear any previous errors
        });

        // Cache the loaded data
        _cachedSubjectsData = List.from(subjects);
        _hasLoadedOnce = true;

        print(
            '✅ Successfully loaded ${subjects.length} subjects from Supabase:');
        for (var subject in subjects) {
          print('  - ${subject["name"]} (${subject["originalTag"]})');
        }
      } else {
        // No tags found in database - might be empty database
        print('⚠️ No tags found in Supabase database');
        setState(() {
          _subjectsData = [];
          _isLoadingSubjects = false; // CRITICAL: Reset loading state
          _hasConnectionError = true;
        });
      }
    } catch (e) {
      print('❌ Error loading subjects from Supabase: $e');
      // CRITICAL: Always reset loading state on error
      if (mounted) {
        setState(() {
          _subjectsData = [];
          _isLoadingSubjects = false; // CRITICAL: Reset loading state
          _hasConnectionError = true;
        });
      }
      // Re-throw to be handled by caller
      throw e;
    }
  }

  Future<void> _loadSubjects() async {
    if (_isLoadingSubjects) {
      print('🔄 Already loading subjects, skipping...');
      return; // Prevent multiple simultaneous loads
    }

    print('📶 Starting to load subjects...');
    setState(() {
      _isLoadingSubjects = true;
      _hasConnectionError = false;
    });

    try {
      // Double-check connectivity with real internet test
      print('🔍 Checking internet connectivity...');
      final hasInternet = await _connectivityService.hasInternetConnection();

      if (!hasInternet) {
        print('❌ No internet connection detected - showing offline state');
        setState(() {
          _subjectsData = [];
          _isLoadingSubjects = false;
          _hasConnectionError = true;
        });
        return;
      }

      print('✅ Internet connection confirmed - loading from Supabase...');
      // Try to load from Supabase
      await _loadSubjectsFromSupabase();
    } catch (e) {
      print('❌ Error in _loadSubjects: $e');
      // Ensure loading state is always reset on error
      if (mounted) {
        setState(() {
          _subjectsData = [];
          _isLoadingSubjects = false;
          _hasConnectionError = true;
        });
      }
    }
  }

  void _showNoConnectionMessage() {
    setState(() {
      _subjectsData = [];
      _isLoadingSubjects = false;
      _hasConnectionError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Row(
                        children: [
                          // App Logo
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape
                                  .circle, // Changed from borderRadius to circular shape
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(1.w),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 8.w,
                                height: 8.w,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape
                                          .circle, // Changed to circular shape
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'quiz',
                                      color: Colors.white,
                                      size: 6.w,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Polity 5000+',
                            style: GoogleFonts.cabin(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.fontSize,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // User greeting header
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return UserGreetingWidget(
                          userName: userProvider.userName,
                          userAvatar: userProvider.userAvatar,
                        );
                      },
                    ),

                    // Banner Ad below user greeting - ALWAYS VISIBLE
                    BannerAdWidget(
                      refreshKey: 'home_screen',
                      enableAutoRefresh: true,
                      margin:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    ),

                    SizedBox(height: 2.h),

                    // Welcome message
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Choose a Topic to start your Practice !!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ),

                    SizedBox(height: 3.h),
                  ],
                ),
              ),

              // Subjects grid
              if (_isLoadingSubjects)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Loading Topics...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_subjectsData.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 45.w, // Maximum width per card
                      crossAxisSpacing: 3.w, // Space between columns
                      mainAxisSpacing: 2.h, // Space between rows
                      childAspectRatio:
                          2.0, // Initial ratio, will be overridden by flexible height
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = _subjectsData[index];
                        return SubjectCardWidget(
                          subjectName: subject["name"] as String,
                          iconName: subject["icon"] as String,
                          backgroundColor: subject["backgroundColor"] as Color,
                          totalQuestions: subject["totalQuestions"] as int,
                          bestScore: subject["bestScore"] as double,
                          onTap: () => _navigateToQuiz(subject),
                        );
                      },
                      childCount: _subjectsData.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No Internet Connection',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Please check your internet connection\nand try again.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 3.h),
                          ElevatedButton.icon(
                            onPressed: _isLoadingSubjects
                                ? null
                                : () async {
                                    print('🔄 Manual retry requested...');

                                    // Force immediate connectivity check
                                    await _connectivityService
                                        .forceConnectivityCheck();

                                    // Load subjects with proper error handling
                                    await _loadSubjects();
                                  },
                            icon: CustomIconWidget(
                              iconName: 'refresh',
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              'Retry',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Add some bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 3.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(Map<String, dynamic> subject) async {
    HapticFeedback.lightImpact();

    // Navigate to sub-topic selection screen instead of directly to quiz
    print('Navigating to sub-topic selection with subject data:');
    print('  ID: ${subject["id"]}');
    print('  Name: ${subject["name"]}');
    print('  Original Tag: ${subject["originalTag"]}');

    Navigator.pushNamed(
      context,
      '/sub-topic-screen',
      arguments: {
        'subjectId': subject["id"],
        'subjectName': subject["name"],
        'subjectTag': subject["originalTag"], // Pass the original database tag
        'backgroundColor': subject["backgroundColor"],
        'icon': subject["icon"],
        'totalQuestions': subject["totalQuestions"],
      },
    );
  }

  Future<void> _refreshData() async {
    print('🔄 Manual refresh triggered...');

    // Prevent refresh if already loading
    if (_isLoadingSubjects) {
      print('⚠️ Already loading, skipping refresh...');
      return;
    }

    // Force reload subjects from Supabase with fresh connectivity check
    await _loadSubjects();

    // Show refresh feedback only if successful
    if (mounted && !_hasConnectionError && _subjectsData.isNotEmpty) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Topics refreshed successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
