// Example implementation for enhanced quiz screen with smart ad placement

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/services/ad_service.dart';
import '../widgets/smart_ad_placement_widget.dart';

class EnhancedQuizScreenExample extends StatefulWidget {
  @override
  _EnhancedQuizScreenExampleState createState() =>
      _EnhancedQuizScreenExampleState();
}

class _EnhancedQuizScreenExampleState extends State<EnhancedQuizScreenExample> {
  int _currentQuestionIndex = 0;
  List<dynamic> _quizData = []; // Your quiz data
  bool _showTopBanner = false;

  @override
  void initState() {
    super.initState();
    _startTopBannerTimer();
  }

  // Show top banner after user is engaged (5 seconds)
  void _startTopBannerTimer() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTopBanner = true;
        });
      }
    });
  }

  // Smart interstitial placement
  void _onNextQuestion() {
    setState(() {
      _currentQuestionIndex++;
    });

    // Show interstitial every 7 questions for longer quizzes
    if (_currentQuestionIndex > 0 &&
        _currentQuestionIndex % 7 == 0 &&
        _quizData.length > 15) {
      _showSmartInterstitial();
    }
  }

  Future<void> _showSmartInterstitial() async {
    // Only show if user is engaged and not too frequently
    final adStatus = AdService.instance.getAdStatus();
    if (adStatus['can_show_interstitial'] == true) {
      await AdService.instance.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Smart top banner (appears after engagement)
            if (_showTopBanner)
              SmartAdPlacementWidget(
                placement: 'quiz',
                showImmediately: false,
                delayBeforeShow: Duration(milliseconds: 500),
              ),

            // Quiz header
            _buildQuizHeader(),

            // Question content
            Expanded(
              child: _buildQuestionContent(),
            ),

            // Bottom actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1}/${_quizData.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    // Your existing quiz content
    return Center(
      child: Text('Quiz question content here'),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: ElevatedButton(
        onPressed: _onNextQuestion,
        child: Text('Next Question'),
      ),
    );
  }
}

// Enhanced results screen with native ad integration
class EnhancedResultsScreenExample extends StatelessWidget {
  final Map<String, dynamic> quizResults;

  const EnhancedResultsScreenExample({
    Key? key,
    required this.quizResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              // Results header
              _buildResultsHeader(context),

              SizedBox(height: 3.h),

              // Quiz statistics
              _buildQuizStats(context),

              SizedBox(height: 3.h),

              // Smart ad placement - integrates naturally with results
              SmartAdPlacementWidget(
                placement: 'results',
                showImmediately: false,
                delayBeforeShow: Duration(seconds: 2),
              ),

              SizedBox(height: 3.h),

              // Action buttons
              _buildActionButtons(context),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            size: 12.w,
            color: Colors.white,
          ),
          SizedBox(height: 2.h),
          Text(
            'Quiz Completed!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStats(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Correct',
            '${quizResults['correct'] ?? 0}',
            Colors.green,
          ),
          _buildStatItem(
            context,
            'Wrong',
            '${quizResults['wrong'] ?? 0}',
            Colors.red,
          ),
          _buildStatItem(
            context,
            'Score',
            '${quizResults['percentage'] ?? 0}%',
            Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Retry with rewarded ad
              _showRewardedAdForRetry(context);
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry (Watch Ad)'),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.home),
            label: Text('Home'),
          ),
        ),
      ],
    );
  }

  void _showRewardedAdForRetry(BuildContext context) {
    AdService.instance.showRewardedAd(
      onUserEarnedReward: (reward) {
        // Grant retry capability
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('🎉 You earned a retry! You can now retake the quiz.'),
            backgroundColor: Colors.green,
          ),
        );
        // Implement retry logic
      },
    );
  }
}
