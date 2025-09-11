import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_icon_widget.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  // Use default cat avatar - no selection needed
  static const String _defaultCatAvatar =
      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=400&fit=crop&crop=face';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  Future<void> _completeProfileSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      print('Setting up profile with name: ${_nameController.text.trim()}');
      print('Using default cat avatar: $_defaultCatAvatar');

      final success = await userProvider.createUserProfile(
        _nameController.text.trim(),
        _defaultCatAvatar,
      );

      if (success && mounted) {
        Fluttertoast.showToast(
          msg: "Welcome to Quiz Master, ${_nameController.text.trim()}!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-navigation',
          (route) => false,
        );
      }
    } catch (e) {
      print('Profile setup error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Profile setup failed: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),

                // Title and Description
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: Colors.white,
                          size: 10.w,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Complete Your Profile',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Let\'s set up your profile to get started',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 6.h),

                // Profile Setup Form
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Profile Information',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Choose your avatar and enter your name',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),

                        SizedBox(height: 4.h),

                        // Avatar Display (Non-interactive during setup)
                        Container(
                          width: 25.w,
                          height: 25.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CustomImageWidget(
                              imageUrl: _defaultCatAvatar,
                              width: 25.w,
                              height: 25.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(height: 1.h),
                        Text(
                          'Default cat avatar\n(You can change this later)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 4.h),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 4.h),

                        // Complete Setup Button
                        SizedBox(
                          width: double.infinity,
                          height: 6.h,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _completeProfileSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 2.h,
                                    width: 2.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Start Quiz Journey',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
