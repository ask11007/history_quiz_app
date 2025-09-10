import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExplanationWidget extends StatefulWidget {
  final String explanation;
  final bool isVisible;

  const ExplanationWidget({
    Key? key,
    required this.explanation,
    required this.isVisible,
  }) : super(key: key);

  @override
  State<ExplanationWidget> createState() => _ExplanationWidgetState();
}

class _ExplanationWidgetState extends State<ExplanationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleExpansion,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'lightbulb',
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Explanation',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Theme.of(context).colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.explanation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
