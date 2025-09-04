import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SignOutButtonWidget extends StatelessWidget {
  final VoidCallback onSignOut;

  const SignOutButtonWidget({
    Key? key,
    required this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SizedBox(
        width: double.infinity,
        height: 6.h,
        child: ElevatedButton(
          onPressed: () => _showSignOutConfirmation(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9463D), // Custom red #C9463D
            foregroundColor: Colors.white,
            elevation: 1,
            shadowColor: const Color(0xFFC9463D).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'logout',
                color: Colors.white,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Sign Out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
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
                  'Sign Out',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out? You will need to log in again to access your account.',
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
                onSignOut();
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
                'Sign Out',
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
