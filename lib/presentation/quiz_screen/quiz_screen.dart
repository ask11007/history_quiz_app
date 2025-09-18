import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/models/question_model.dart';
import '../../core/models/quiz_state_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ad_service.dart';
import './widgets/explanation_widget.dart';
import './widgets/option_card_widget.dart';
import './widgets/question_card_widget.dart';
import './widgets/quiz_header_widget.dart';
import './widgets/quiz_progress_indicator_widget.dart';
import './widgets/question_report_widget.dart';
import '../../widgets/banner_ad_widget.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false; // Start with false, check connectivity first
  bool _hasDataLoadError = false;
  String _errorMessage = '';

  DateTime? _quizStartTime;
  bool _hasLoadedData = false; // Add flag to prevent multiple loads

  // Quiz state management
  final QuizStateManager _quizStateManager = QuizStateManager();

  // Dynamic quiz data from Supabase
  List<Question> _quizData = [];
  String _subjectName = '';
  String _subjectTag = '';
  String _subTopicName = ''; // Added for storing sub-topic name
  final ConnectivityService _connectivityService = ConnectivityService();

  final List<String> _optionLabels = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    // Remove _loadQuizData() from here - it will be called in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load quiz data here after the widget is fully initialized
    if (!_hasLoadedData) {
      // Ensure context and arguments are available before loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeQuizData();
          _hasLoadedData = true;
        }
      });
    }
  }

  Future<void> _initializeQuizData() async {
    // First check connectivity without showing loading until we know we need to fetch data
    final hasInternet = await _connectivityService.hasInternetConnection();

    if (!hasInternet) {
      print('❌ No internet connection detected during initialization');
      setState(() {
        _hasDataLoadError = true;
        _errorMessage = 'No internet connection available';
      });
      return;
    }

    // Only show loading state when we're actually going to fetch data
    setState(() {
      _isLoading = true;
    });

    await _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      // Get subject information from navigation arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        print('📥 Received navigation arguments: $args');

        _subjectName = args['subjectName'] ?? '';

        // Multiple fallback strategies for subjectTag
        _subjectTag = args['subjectTag'] ??
            args['originalTag'] ??
            args['tag'] ??
            args['subjectName'] ??
            '';

        // Get sub-topic information
        final subjectSubTag = args['subjectSubTag'] as String?;
        _subTopicName = args['subTopicName'] ?? '';

        print('📊 Extracted data:');
        print('   subjectName: "$_subjectName"');
        print('   subjectTag: "$_subjectTag"');
        print('   subjectSubTag: "$subjectSubTag"');
        print('   subTopicName: "$_subTopicName"');

        // Validate that we have essential data
        if (_subjectTag.isEmpty) {
          print(
              '❌ CRITICAL: subjectTag is empty! Trying alternative approaches...');

          // Try to use subjectName as tag if available
          if (_subjectName.isNotEmpty) {
            _subjectTag = _subjectName;
            print('🔄 Using subjectName as fallback tag: "$_subjectTag"');
          } else {
            print('❌ No usable tag found, showing error');
            setState(() {
              _quizData = [];
              _isLoading = false;
              _hasDataLoadError = true;
              _errorMessage = 'Invalid topic selected - no tag information';
            });
            return;
          }
        }

        print(
            'Loading quiz data for subject: $_subjectName, tag: $_subjectTag, sub_tag: $subjectSubTag');
        print('✅ Internet connection confirmed - loading quiz questions...');

        List<Question> questions;

        if (subjectSubTag != null && subjectSubTag.isNotEmpty) {
          // Fetch questions by both tag and sub_tag
          print('🔍 Fetching questions by tag AND sub_tag...');
          questions = await SupabaseService.getQuestionsByTagAndSubTag(
              _subjectTag, subjectSubTag);
        } else {
          // Fetch questions by tag only (original behavior)
          print('🔍 Fetching questions by tag only...');
          questions = await SupabaseService.getQuestionsByTag(_subjectTag);
        }

        if (questions.isNotEmpty) {
          setState(() {
            _quizData = questions;
            _isLoading = false;
            _hasDataLoadError = false;
            _errorMessage = '';
          });
          print(
              '✅ Successfully loaded ${questions.length} questions from Supabase for tag: $_subjectTag${subjectSubTag != null ? ", sub_tag: $subjectSubTag" : ""}');
        } else {
          print(
              '⚠️ No questions found for tag: $_subjectTag${subjectSubTag != null ? ", sub_tag: $subjectSubTag" : ""}');
          setState(() {
            _quizData = [];
            _isLoading = false;
            _hasDataLoadError = true;
            _errorMessage =
                'No questions available for this topic. The topic may not be set up yet.';
          });
        }
      } else {
        print('❌ No navigation arguments found');
        setState(() {
          _quizData = [];
          _isLoading = false;
          _hasDataLoadError = true;
          _errorMessage = 'Navigation error - no topic data found';
        });
      }
    } catch (e) {
      print('❌ Error loading quiz data: $e');
      setState(() {
        _quizData = [];
        _isLoading = false;
        _hasDataLoadError = true;
        _errorMessage =
            'Failed to load questions. Please check your connection.';
      });
    }
  }

  Question get _currentQuestion => _quizData[_currentQuestionIndex];

  bool get _isLastQuestion => _currentQuestionIndex == _quizData.length - 1;

  // Get current question state
  QuestionState get _currentQuestionState =>
      _quizStateManager.getQuestionState(_currentQuestionIndex);

  // Convenience getters for current question state
  int? get _selectedOptionIndex => _currentQuestionState.selectedOptionIndex;
  bool get _hasSubmittedAnswer => _currentQuestionState.hasSubmittedAnswer;
  bool get _showExplanation => _currentQuestionState.showExplanation;

  void _selectOption(int index) {
    if (_hasSubmittedAnswer) return;

    // Auto-submit the answer immediately
    _submitAnswerInstantly(index);

    HapticFeedback.selectionClick();
  }

  Future<void> _submitAnswerInstantly(int selectedIndex) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    _quizStateManager.selectAndSubmitOption(
        _currentQuestionIndex, selectedIndex);

    setState(() {
      _isLoading = false;
    });

    // Provide haptic feedback
    if (selectedIndex == _currentQuestion.correctAnswer) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizData.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        // State will be automatically restored from QuizStateManager
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        // State will be automatically restored from QuizStateManager
      });
    }
  }

  void _navigateToQuestion(int questionIndex) {
    if (questionIndex >= 0 && questionIndex < _quizData.length) {
      setState(() {
        _currentQuestionIndex = questionIndex;
        // State will be automatically restored from QuizStateManager
      });
    }
  }

  void _finishQuiz() {
    // Show interstitial ad before results
    AdService.instance.forceShowInterstitialAd().then((adShown) {
      if (adShown) {
        print('✅ Interstitial ad shown before quiz results');
        // Add small delay to ensure ad is properly closed
        Future.delayed(Duration(milliseconds: 500), () {
          _showQuizResults();
        });
      } else {
        print('⚠️ Interstitial ad not shown, showing results immediately');
        _showQuizResults();
      }
    });
  }

  void _showQuizResults() {
    // Calculate simple quiz summary
    final summary = _quizStateManager.getQuizSummary(_quizData);

    // Show simple popup dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Quiz Completed!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subject name
              Text(
                _subTopicName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),

              // Statistics in a compact grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Correct', '${summary['correct']}',
                      const Color(0xFF02732A)),
                  _buildStatItem(
                      'Wrong', '${summary['wrong']}', const Color(0xFFC9463D)),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Attempted', '${summary['attempted']}',
                      const Color(0xFF1976D2)),
                  _buildStatItem('Unattempted', '${summary['unattempted']}',
                      const Color(0xFFFF9800)),
                ],
              ),

              // Custom Rectangle Ad below results
              SizedBox(height: 2.h),
              MediumRectangleAdWidget(
                enableAutoRefresh: true,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog only
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '❌ Cancel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to subtopic screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '🏠 Home',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuestionReportWidget(
          question: _currentQuestion,
          onReportSubmitted: () {
            // Optional: Add any additional logic after report submission
            print('Question ${_currentQuestion.id} reported successfully');
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: Theme.of(context).colorScheme.error,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Flexible(
                    child: Text(
                      'Exit Quiz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to exit? Your progress will be lost.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    elevation: 2,
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    Navigator.pop(context); // Go back to sub-topic screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9463D),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Exit Quiz',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  OptionState _getOptionState(int index) {
    if (!_hasSubmittedAnswer) {
      return _selectedOptionIndex == index
          ? OptionState.selected
          : OptionState.unselected;
    }

    final correctIndex = _currentQuestion.correctAnswer;
    if (index == correctIndex) {
      return OptionState.correct;
    } else if (index == _selectedOptionIndex) {
      return OptionState.incorrect;
    }

    return OptionState.unselected;
  }

  @override
  Widget build(BuildContext context) {
    // Debug information
    print(
        'QuizScreen build - isLoading: $_isLoading, quizData length: ${_quizData.length}, subjectTag: $_subjectTag');

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Loading questions...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Sub Topic: $_subTopicName\nTopic: $_subjectName',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_quizData.isEmpty && !_isLoading && _hasDataLoadError) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 1.h),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Please check your internet connection\nand try again to load questions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_subjectName.isNotEmpty || _subTopicName.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    'Topic: $_subjectName\nSub-topic: $_subTopicName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    label: Text(
                      'Go Back',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  ElevatedButton.icon(
                    onPressed: () async {
                      print('🔄 Manual quiz retry requested...');
                      setState(() {
                        _hasLoadedData = false;
                        _hasDataLoadError = false;
                        _errorMessage = '';
                      });

                      // Force immediate connectivity check
                      await _connectivityService.forceConnectivityCheck();

                      // Add small delay to show loading state
                      await Future.delayed(Duration(milliseconds: 200));
                      _loadQuizData();
                    },
                    icon: CustomIconWidget(
                      iconName: 'refresh',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: null,
        body: Column(
          children: [
            QuizHeaderWidget(
              subTopicName: _subTopicName,
              currentQuestion: _currentQuestionIndex + 1,
              totalQuestions: _quizData.length,
              onBackPressed: () => Navigator.pop(context),
              onReportPressed: _showReportDialog,
            ),
            QuizProgressIndicatorWidget(
              totalQuestions: _quizData.length,
              currentQuestionIndex: _currentQuestionIndex,
              quizStateManager: _quizStateManager,
              questions: _quizData,
              onQuestionTap: _navigateToQuestion,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    QuestionCardWidget(
                      questionText: _currentQuestion.question,
                      questionNumber: _currentQuestionIndex + 1,
                    ),
                    SizedBox(height: 2.h),
                    ...List.generate(
                      _currentQuestion.options.length,
                      (index) => OptionCardWidget(
                        optionText: _currentQuestion.options[index],
                        optionLabel: _optionLabels[index],
                        state: _getOptionState(index),
                        onTap: () => _selectOption(index),
                        isEnabled: !_hasSubmittedAnswer,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ExplanationWidget(
                      explanation: _currentQuestion.explanation,
                      isVisible: _showExplanation,
                    ),
                  ],
                ),
              ),
            ),
            // Navigation - Always show if there are multiple questions
            if (_quizData.length > 1)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    child: Row(
                      children: [
                        // Previous Button
                        if (_quizStateManager
                            .canNavigateToPrevious(_currentQuestionIndex))
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousQuestion,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'arrow_back',
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Previous',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Spacing between buttons
                        if (_quizStateManager
                                .canNavigateToPrevious(_currentQuestionIndex) &&
                            (_quizStateManager.canNavigateToNext(
                                    _currentQuestionIndex, _quizData.length) ||
                                _isLastQuestion))
                          SizedBox(width: 4.w),

                        // Next Button or Finish Button
                        if (_quizStateManager.canNavigateToNext(
                            _currentQuestionIndex, _quizData.length))
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(double.infinity, 6.h),
                                maximumSize: Size(double.infinity, 6.h),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(width: 2.w),
                                  CustomIconWidget(
                                    iconName: 'arrow_forward',
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_isLastQuestion)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _finishQuiz,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(double.infinity, 6.h),
                                maximumSize: Size(double.infinity, 6.h),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Finish',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(width: 2.w),
                                  CustomIconWidget(
                                    iconName: 'check',
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
