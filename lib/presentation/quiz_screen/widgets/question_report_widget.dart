import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/question_report_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/user_provider.dart';

class QuestionReportWidget extends StatefulWidget {
  final Question question;
  final VoidCallback? onReportSubmitted;

  const QuestionReportWidget({
    Key? key,
    required this.question,
    this.onReportSubmitted,
  }) : super(key: key);

  @override
  State<QuestionReportWidget> createState() => _QuestionReportWidgetState();
}

class _QuestionReportWidgetState extends State<QuestionReportWidget> {
  String? _selectedReportType;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  int _characterCount = 0;
  static const int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _characterCount = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_selectedReportType == null) {
      _showErrorSnackBar('Please select a report type');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userEmail = userProvider.userEmail;

      final report = QuestionReport(
        questionId: widget.question.id,
        reportType: _selectedReportType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        userEmail: userEmail,
        reportedAt: DateTime.now(),
      );

      final success = await SupabaseService.submitQuestionReport(report);

      if (success) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(
            'Report submitted successfully. Thank you for your feedback!');
        widget.onReportSubmitted?.call();
      } else {
        _showErrorSnackBar('Failed to submit report. Please try again.');
      }
    } catch (e) {
      print('Error submitting report: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF02732A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Limit the dialog height to make it more compact
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 70.h, // Limit maximum height to 70% of screen height
        ),
        child: SingleChildScrollView(
          child: Padding(
            // Further reduced padding to make dialog more compact
            padding: EdgeInsets.all(3.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.report_problem,
                        color: Theme.of(context).colorScheme.error,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Question',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          Text(
                            'Help us improve content quality',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 10.sp,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Further reduced spacing
                SizedBox(height: 1.5.h),

                // Question Preview
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w), // Further reduced padding
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.question.question,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12.sp,
                        ),
                        maxLines: 2, // Reduced from 3 to 2 lines
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Further reduced spacing
                SizedBox(height: 1.h),

                // Report Type Selection
                Text(
                  'What\'s the issue?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                ),
                SizedBox(height: 1.h), // Further reduced

                // Limit the number of report types shown to reduce height
                ...ReportTypes.all.take(4).map((type) => _buildReportTypeOption(type)),

                // Further reduced spacing
                SizedBox(height: 1.h),

                // Description Field
                Text(
                  'Additional details (optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Provide specific details to help us understand the issue better.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10.sp,
                      ),
                ),
                SizedBox(height: 1.h), // Further reduced

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 2, // Further reduced from 3 to 2 lines
                    maxLength: _maxCharacters,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      hintStyle: TextStyle(
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(2.w), // Further reduced padding
                      counterText: '$_characterCount/$_maxCharacters',
                      counterStyle: TextStyle(
                        color: _characterCount > _maxCharacters * 0.8
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10.sp,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.sp,
                    ),
                  ),
                ),

                SizedBox(height: 1.5.h), // Further reduced

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h), // Further reduced
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.sp,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(width: 1.5.w), // Further reduced
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h), // Further reduced
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 3.w,
                                    height: 3.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Submitting...',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Submit Report',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
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
    ),
  );
}

  Widget _buildReportTypeOption(String type) {
    final isSelected = _selectedReportType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReportType = type;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 1.h), // Further reduced
        padding: EdgeInsets.all(2.w), // Further reduced padding
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.error
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 2.5.w,
                    )
                  : null,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                type,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12.sp,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}