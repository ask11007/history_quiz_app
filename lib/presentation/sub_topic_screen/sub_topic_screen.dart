import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../home_screen/widgets/subject_card_widget.dart';

class SubTopicScreen extends StatefulWidget {
  const SubTopicScreen({Key? key}) : super(key: key);

  @override
  State<SubTopicScreen> createState() => _SubTopicScreenState();
}

class _SubTopicScreenState extends State<SubTopicScreen> {
  List<Map<String, dynamic>> _subTopicsData = [];
  bool _isLoadingSubTopics = false;
  String _subjectName = '';
  String _subjectTag = '';
  Color _subjectColor = const Color(0xFF6B7280);
  String _subjectIcon = 'quiz';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubTopics();
    });
  }

  void _loadSubTopics() {
    // Get subject information from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _subjectName = args['subjectName'] ?? '';
        _subjectTag = args['subjectTag'] ?? '';
        _subjectColor = args['backgroundColor'] ?? const Color(0xFF6B7280);
        _subjectIcon = args['icon'] ?? 'quiz';
      });

      _fetchSubTopicsFromDatabase();
    }
  }

  Future<void> _fetchSubTopicsFromDatabase() async {
    setState(() {
      _isLoadingSubTopics = true;
    });

    try {
      print('Fetching sub-topics for subject tag: $_subjectTag');

      final subTags = await SupabaseService.getAvailableSubTags(_subjectTag);

      if (subTags.isNotEmpty) {
        // Create sub-topic data based on available sub_tags
        final subTopics = subTags.asMap().entries.map((entry) {
          final index = entry.key;
          final subTag = entry.value;

          // Generate colors for sub-topics (variations of the main subject color)
          final baseHSL = HSLColor.fromColor(_subjectColor);
          final subTopicColor = baseHSL
              .withLightness(
                  (baseHSL.lightness + (index * 0.1)).clamp(0.3, 0.8))
              .toColor();

          return {
            "id": index + 1,
            "name": _formatSubTopicName(subTag),
            "subTag": subTag, // Original sub_tag for database queries
            "tag": _subjectTag, // Parent subject tag
            "icon": _getSubTopicIcon(subTag),
            "backgroundColor": subTopicColor,
            "totalQuestions": 0, // Will be updated when questions are fetched
          };
        }).toList();

        setState(() {
          _subTopicsData = subTopics;
          _isLoadingSubTopics = false;
        });

        print('Loaded ${subTopics.length} sub-topics:');
        for (var subTopic in subTopics) {
          print('  ${subTopic["name"]} (${subTopic["subTag"]})');
        }
      } else {
        print('No sub-topics found for tag: $_subjectTag');
        setState(() {
          _subTopicsData = [];
          _isLoadingSubTopics = false;
        });
      }
    } catch (e) {
      print('Error loading sub-topics: $e');
      setState(() {
        _subTopicsData = [];
        _isLoadingSubTopics = false;
      });
    }
  }

  String _formatSubTopicName(String subTag) {
    // Convert database sub_tag to display name
    // Example: "algebra" -> "Algebra", "geometry" -> "Geometry"
    return subTag
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _getSubTopicIcon(String subTag) {
    // Map sub-topics to appropriate icons
    final iconMap = {
      'algebra': 'functions',
      'geometry': 'square',
      'calculus': 'trending_up',
      'statistics': 'bar_chart',
      'probability': 'casino',
      'sports': 'sports_soccer',
      'history': 'history',
      'geography': 'public',
      'science': 'science',
      'politics': 'account_balance',
      'logical': 'psychology',
      'analytical': 'analytics',
      'verbal': 'record_voice_over',
      'numerical': 'calculate',
    };

    return iconMap[subTag.toLowerCase()] ?? 'quiz';
  }

  void _navigateToQuiz(Map<String, dynamic> subTopic) {
    HapticFeedback.lightImpact();

    print('Navigating to quiz with sub-topic data:');
    print('  Subject: $_subjectName');
    print('  Sub-topic: ${subTopic["name"]}');
    print('  Tag: ${subTopic["tag"]}');
    print('  Sub Tag: ${subTopic["subTag"]}');

    Navigator.pushNamed(
      context,
      '/quiz-screen',
      arguments: {
        'subjectId': subTopic["id"],
        'subjectName': _subjectName,
        'subjectTag': subTopic["tag"], // Main subject tag
        'subjectSubTag': subTopic["subTag"], // Sub-topic tag
        'subTopicName': subTopic["name"], // Pass only sub-topic name for header
        'totalQuestions': subTopic["totalQuestions"],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      _subjectName,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoadingSubTopics
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Loading Sub-Topics...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : _subTopicsData.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 2.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                'Choose a Sub-Topic to start your Practice !!',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2.w),
                                child: ListView.builder(
                                  itemCount: _subTopicsData.length,
                                  itemBuilder: (context, index) {
                                    final subTopic = _subTopicsData[index];
                                    return SubjectCardWidget(
                                      subjectName: subTopic["name"] as String,
                                      iconName: subTopic["icon"] as String,
                                      backgroundColor:
                                          subTopic["backgroundColor"] as Color,
                                      totalQuestions:
                                          subTopic["totalQuestions"] as int,
                                      bestScore: 0.0,
                                      onTap: () => _navigateToQuiz(subTopic),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.topic_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No Sub-Topics available',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'This subject doesn\'t have sub-topics yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
