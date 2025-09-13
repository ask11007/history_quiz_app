import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/models/question_model.dart';
import '../../core/models/quiz_state_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ad_service.dart';
import '../../widgets/banner_ad_widget.dart';
import './widgets/explanation_widget.dart';
import './widgets/option_card_widget.dart';
import './widgets/question_card_widget.dart';
import './widgets/quiz_header_widget.dart';
import './widgets/quiz_progress_indicator_widget.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
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
      // Add a small delay to ensure navigation arguments are available
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _loadQuizData();
          _hasLoadedData = true;
        }
      });
    }
  }

  Future<void> _loadQuizData() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      // Get subject information from navigation arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _subjectName = args['subjectName'] ?? '';
        _subjectTag = args['subjectTag'] ??
            args['subjectName'] ??
            ''; // Use subjectTag if available, fallback to subjectName

        // Get sub-topic information
        final subjectSubTag = args['subjectSubTag'] as String?;
        _subTopicName =
            args['subTopicName'] ?? ''; // Only use sub-topic name, no fallback

        print(
            'Loading quiz data for subject: $_subjectName, tag: $_subjectTag, sub_tag: $subjectSubTag');

        // Check connectivity with real internet test before attempting to load questions
        final hasInternet = await _connectivityService.hasInternetConnection();
        if (!hasInternet) {
          print('❌ No internet connection detected for quiz loading');
          setState(() {
            _quizData = [];
            _isLoading = false;
            _hasDataLoadError = true;
            _errorMessage = 'No internet connection available';
          });
          return;
        }

        print('✅ Internet connection confirmed - loading quiz questions...');

        if (_subjectTag.isNotEmpty) {
          List<Question> questions;

          if (subjectSubTag != null && subjectSubTag.isNotEmpty) {
            // Fetch questions by both tag and sub_tag
            questions = await SupabaseService.getQuestionsByTagAndSubTag(
                _subjectTag, subjectSubTag);
          } else {
            // Fetch questions by tag only (original behavior)
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
                'Successfully loaded ${questions.length} questions from Supabase for tag: $_subjectTag${subjectSubTag != null ? ", sub_tag: $subjectSubTag" : ""}');
          } else {
            print(
                'No questions found for tag: $_subjectTag${subjectSubTag != null ? ", sub_tag: $subjectSubTag" : ""}');
            setState(() {
              _quizData = [];
              _isLoading = false;
              _hasDataLoadError = true;
              _errorMessage = 'No questions available for this topic';
            });
          }
        } else {
          print('Subject tag is empty');
          setState(() {
            _quizData = [];
            _isLoading = false;
            _hasDataLoadError = true;
            _errorMessage = 'Invalid topic selected';
          });
        }
      } else {
        print('No navigation arguments found');
        setState(() {
          _quizData = [];
          _isLoading = false;
          _hasDataLoadError = true;
          _errorMessage = 'Navigation error - no topic data found';
        });
      }
    } catch (e) {
      print('Error loading quiz data: $e');
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
    // Show forced interstitial ad for quiz completion
    AdService.instance.showInterstitialAdForced().then((adShown) {
      if (adShown) {
        print('🎆 Forced interstitial ad shown after quiz completion');
      }

      // Show results screen (with slight delay if ad was shown)
      Future.delayed(
        Duration(milliseconds: adShown ? 1000 : 0),
        () => _showQuizResultsScreen(),
      );
    });
  }

  void _showQuizResultsScreen() {
    // Calculate quiz summary
    final summary = _quizStateManager.getQuizSummary(_quizData);

    // Navigate to a full results screen instead of dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Results content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      SizedBox(height: 4.h),

                      // Completion Icon
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: Colors.white,
                          size: 10.w,
                        ),
                      ),

                      SizedBox(height: 3.h),

                      Text(
                        'Quiz Completed!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 1.h),

                      Text(
                        _subTopicName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      // Statistics Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultCard('Correct', '${summary['correct']}',
                              const Color(0xFF02732A), Icons.check_circle),
                          _buildResultCard('Wrong', '${summary['wrong']}',
                              const Color(0xFFC9463D), Icons.cancel),
                        ],
                      ),

                      SizedBox(height: 3.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultCard(
                              'Attempted',
                              '${summary['attempted']}',
                              const Color(0xFF1976D2),
                              Icons.assignment_turned_in),
                          _buildResultCard(
                              'Skipped',
                              '${summary['unattempted']}',
                              const Color(0xFFFF9800),
                              Icons.skip_next),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Action Buttons
                      if (AdService.instance.isRewardedAdReady) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRewardedAdForRetry(),
                            icon: Icon(Icons.play_circle_fill,
                                color: Colors.white),
                            label: Text(
                              'Watch Ad & Retry Wrong Answers',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close results
                              },
                              icon: Icon(Icons.quiz,
                                  color: Theme.of(context).colorScheme.primary),
                              label: Text(
                                'Continue Quiz',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close results
                                Navigator.pop(
                                    context); // Go back to subtopic screen
                              },
                              icon: Icon(Icons.home, color: Colors.white),
                              label: Text(
                                'Home',
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
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Banner Ad at bottom
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: BannerAdWidget(
                  margin: EdgeInsets.all(2.w),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
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
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdForRetry() {
    AdService.instance.showRewardedAd(
      onUserEarnedReward: (reward) {
        // User earned reward - allow retry of wrong answers
        print('🎁 User earned reward: ${reward.amount} ${reward.type}');

        Navigator.pop(context); // Close results dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Reward earned! You can now retry wrong answers.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Implement retry logic here
        _retryWrongAnswers();
      },
    );
  }

  void _retryWrongAnswers() {
    // Reset quiz state for wrong answers only
    final wrongQuestions = <int>[];
    for (int i = 0; i < _quizData.length; i++) {
      final state = _quizStateManager.getQuestionState(i);
      if (state.hasSubmittedAnswer &&
          state.selectedOptionIndex != _quizData[i].correctAnswer) {
        wrongQuestions.add(i);
      }
    }

    if (wrongQuestions.isNotEmpty) {
      // Reset states for wrong answers
      for (int index in wrongQuestions) {
        _quizStateManager.resetQuestionState(index);
      }

      // Navigate to first wrong question
      setState(() {
        _currentQuestionIndex = wrongQuestions.first;
      });

      // Show helpful message
      Future.delayed(Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Now retry the ${wrongQuestions.length} questions you got wrong!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
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
                    Navigator.pushReplacementNamed(context, '/main-navigation');
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

    if (_quizData.isEmpty && !_isLoading) {
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
