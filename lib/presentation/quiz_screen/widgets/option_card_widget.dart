import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

enum OptionState { unselected, selected, correct, incorrect }

class OptionCardWidget extends StatelessWidget {
  final String optionText;
  final String optionLabel;
  final OptionState state;
  final VoidCallback onTap;
  final bool isEnabled;

  const OptionCardWidget({
    Key? key,
    required this.optionText,
    required this.optionLabel,
    required this.state,
    required this.onTap,
    this.isEnabled = true,
  }) : super(key: key);

  Color _getBackgroundColor(BuildContext context) {
    switch (state) {
      case OptionState.selected:
        return Color(0xFF02732A); // Bright green before submission
      case OptionState.correct:
        return Color(0xFF02732A); // Same bright green as selection for correct answer
      case OptionState.incorrect:
        return Color(0xFF8B0000); // Dark red for incorrect answer (matte/frosted)
      case OptionState.unselected:
        return Theme.of(context).colorScheme.surface;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (state) {
      case OptionState.selected:
        return Colors.white; // White text on bright green background
      case OptionState.correct:
        return Colors.white; // Theme color text on light background
      case OptionState.incorrect:
        return Colors.white;
      case OptionState.unselected:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _getRadioIcon() {
    switch (state) {
      case OptionState.selected:
      case OptionState.correct:
      case OptionState.incorrect:
        return Icons.radio_button_checked;
      case OptionState.unselected:
      return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(
          //   color: _getBorderColor(context),
          //   width: 2,
          // ),
          boxShadow: state != OptionState.unselected
              ? [
                  BoxShadow(
                    color: _getBackgroundColor(context).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: state == OptionState.unselected
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: _getRadioIcon() == Icons.radio_button_checked
                    ? 'radio_button_checked'
                    : 'radio_button_unchecked',
                color: state == OptionState.unselected
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.white, // White for all selected states (selected, correct, incorrect)
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: state == OptionState.unselected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.white.withValues(alpha: 0.2), // Same faded white for both correct and incorrect
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  optionLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: state == OptionState.unselected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Colors.white, // White for all selected states (selected, correct, incorrect)
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                optionText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getTextColor(context),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
