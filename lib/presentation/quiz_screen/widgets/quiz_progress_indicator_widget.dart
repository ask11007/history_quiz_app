import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/models/question_model.dart';

class QuizProgressIndicatorWidget extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestionIndex;
  final QuizStateManager quizStateManager;
  final List<Question> questions;
  final Function(int)? onQuestionTap;

  const QuizProgressIndicatorWidget({
    Key? key,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.quizStateManager,
    required this.questions,
    this.onQuestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${quizStateManager.getTotalAnsweredCount()}/$totalQuestions answered',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalQuestions,
              itemBuilder: (context, index) {
                final questionState = quizStateManager.getQuestionState(index);
                final isCurrentQuestion = index == currentQuestionIndex;
                final isAnswered = questionState.hasSubmittedAnswer;
                final isSelected = questionState.hasSelection;
                final isCorrect =
                    quizStateManager.isQuestionCorrect(index, questions);

                return GestureDetector(
                  onTap: onQuestionTap != null
                      ? () => onQuestionTap!(index)
                      : null,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.only(right: 2.w),
                    decoration: BoxDecoration(
                      color: _getQuestionIndicatorColor(
                        context,
                        isCurrentQuestion,
                        isAnswered,
                        isSelected,
                        isCorrect,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      border: isCurrentQuestion
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getQuestionIndicatorTextColor(
                            context,
                            isCurrentQuestion,
                            isAnswered,
                            isSelected,
                            isCorrect,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestionIndicatorColor(
    BuildContext context,
    bool isCurrentQuestion,
    bool isAnswered,
    bool isSelected,
    bool isCorrect,
  ) {
    if (isAnswered) {
      // Answered questions - green for correct, red for incorrect
      return isCorrect ? Color(0xFF02732A) : Color(0xFFD32F2F);
    } else if (isSelected) {
      // Selected but not submitted - orange
      return Color(0xFFFF8C00);
    } else if (isCurrentQuestion) {
      // Current question - light primary
      return Theme.of(context).colorScheme.primaryContainer;
    } else {
      // Unanswered questions - gray
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    }
  }

  Color _getQuestionIndicatorTextColor(
    BuildContext context,
    bool isCurrentQuestion,
    bool isAnswered,
    bool isSelected,
    bool isCorrect,
  ) {
    if (isAnswered || isSelected) {
      return Colors.white;
    } else if (isCurrentQuestion) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
