import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuizHeaderWidget extends StatelessWidget {
  final String subTopicName; // Renamed to be more explicit
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onBackPressed;
  final VoidCallback? onReportPressed;

  const QuizHeaderWidget({
    Key? key,
    required this.subTopicName, // Renamed parameter
    required this.currentQuestion,
    required this.totalQuestions,
    this.onBackPressed,
    this.onReportPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showExitConfirmation(context),
                child: Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  subTopicName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: onReportPressed,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '⚠️',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
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
                Navigator.of(context).pop();
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.pushReplacementNamed(context, '/main-navigation');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9463D),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
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
    );
  }
}
