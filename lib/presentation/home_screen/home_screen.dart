import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_icon_widget.dart';
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

      // Listen for connectivity changes
      _connectivityService.onConnectivityChanged = (bool isConnected) {
        print('Connectivity changed: $isConnected');
        if (isConnected) {
          // Reload subjects when connection is restored
          _loadSubjects();
        } else {
          // Show basic subjects when offline
          _loadBasicSubjects();
        }
      };

      // Load subjects based on connectivity
      _loadSubjects();
    }
  }

  @override
  void dispose() {
    // Clean up connectivity listener
    _connectivityService.onConnectivityChanged = null;
    super.dispose();
  }

  Future<void> _loadSubjectsFromSupabase() async {
    try {
      // Add timeout to prevent infinite loading
      final tags = await SupabaseService.getAvailableTags().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Supabase request timed out');
          return <String>[];
        },
      );

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
          _isLoadingSubjects = false; // Fix: Also set the main loading flag
        });

        // Cache the loaded data
        _cachedSubjectsData = List.from(subjects);
        _hasLoadedOnce = true;

        // Debug logging
        print('Loaded ${subjects.length} subjects from Supabase:');
        for (var subject in subjects) {
          print('  ${subject["name"]} (${subject["originalTag"]})');
        }
      } else {
        // No tags found, fallback to basic subjects
        print('No tags found in Supabase, using basic subjects');
        _loadBasicSubjects();
      }
    } catch (e) {
      print('Error loading subjects from Supabase: $e');
      setState(() {
        _isLoadingSubjects = false; // Fix: Also set the main loading flag
      });
      // Fallback to basic subjects if Supabase fails
      _loadBasicSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    if (_isLoadingSubjects) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      // TEMP FIX: Skip connectivity check and try Supabase directly
      print('Loading subjects (skipping connectivity check)...');

      // Try to load from Supabase
      await _loadSubjectsFromSupabase();
    } catch (e) {
      print('Error in _loadSubjects: $e');
      // Fallback to basic subjects on any error
      _loadBasicSubjects();
    }
  }

  void _loadBasicSubjects() {
    final basicSubjects = [
      {
        "id": 1,
        "name": "Mathematics",
        "originalTag": "Math",
        "icon": "calculate",
        "backgroundColor": Color(0xFF4F46E5), // Indigo
        "totalQuestions": 0, // No hardcoded data
        "bestScore": 0.0, // No hardcoded data
        "completedQuizzes": 0,
      },
      {
        "id": 2,
        "name": "General Knowledge",
        "originalTag": "GK",
        "icon": "public",
        "backgroundColor": Color(0xFF16A34A), // Green
        "totalQuestions": 0, // No hardcoded data
        "bestScore": 0.0, // No hardcoded data
        "completedQuizzes": 0,
      },
      {
        "id": 3,
        "name": "Reasoning",
        "originalTag": "Reasoning",
        "icon": "psychology",
        "backgroundColor": Color(0xFF8B5CF6), // Purple
        "totalQuestions": 0, // No hardcoded data
        "bestScore": 0.0, // No hardcoded data
        "completedQuizzes": 0,
      },
    ];

    setState(() {
      _subjectsData = basicSubjects;
      _isLoadingSubjects = false;
    });

    // Cache basic subjects too
    if (!_hasLoadedOnce) {
      _cachedSubjectsData = List.from(basicSubjects);
      _hasLoadedOnce = true;
    }
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
                              borderRadius: BorderRadius.circular(12),
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
                                'assets/images/app_icon.png',
                                width: 8.w,
                                height: 8.w,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
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
                            'Quiz Master',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
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

              // Subjects list
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
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  sliver: SliverList(
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
                            Icons.quiz_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No Topics available',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Please check your connection.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
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
    setState(() {
      _isLoadingSubjects = true;
    });

    // Force reload subjects from Supabase
    await _loadSubjectsFromSupabase();

    // Show refresh feedback
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              'Topics refreshed successfully',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
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
