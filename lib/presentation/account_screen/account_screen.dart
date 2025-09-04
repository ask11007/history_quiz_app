import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../theme/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/sign_out_button_widget.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
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

  void _showEditNameDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController nameController =
        TextEditingController(text: userProvider.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              userProvider.updateUserName(nameController.text.trim());
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Name updated successfully!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProfilePictureOptions() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Pre-defined avatar options
    final List<String> avatars = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&crop=face',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Your Avatar'),
        content: Container(
          width: 80.w,
          height: 40.h,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];

              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await userProvider.updateUserAvatar(avatar);
                  Fluttertoast.showToast(
                    msg: "Profile picture updated!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: avatar,
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode(bool value) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();

    Fluttertoast.showToast(
      msg: value ? "Dark mode enabled" : "Light mode enabled",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleSignOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Show loading state
      Fluttertoast.showToast(
        msg: "Signing out...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      await userProvider.signOut();

      if (mounted) {
        // Navigate to login screen immediately after sign out
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/phone-auth',
          (route) => false, // Remove all previous routes
        );

        Fluttertoast.showToast(
          msg: "Signed out successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error signing out: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
            child: Column(
              children: [
                // Custom Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      // App Logo
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.w),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 8.w,
                            height: 8.w,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'quiz',
                                  color: Colors.white,
                                  size: 6.w,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Account',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return ProfileHeaderWidget(
                      userName: userProvider.userName,
                      userEmail: userProvider.userEmail,
                      avatarUrl: userProvider.userAvatar,
                      onAvatarTap: _showProfilePictureOptions,
                      onEditProfile: _showEditNameDialog,
                    );
                  },
                ),
                SizedBox(height: 2.h),
                SettingsSectionWidget(
                  title: 'Account Management',
                  items: [
                    SettingsItem(
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      iconName: 'person',
                      onTap: _showEditNameDialog,
                    ),
                    SettingsItem(
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      iconName: 'lock',
                      onTap: () {
                        Fluttertoast.showToast(
                          msg: "Change password feature coming soon!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                    ),
                    SettingsItem(
                      title: 'Privacy Settings',
                      subtitle: 'Manage your privacy preferences',
                      iconName: 'privacy_tip',
                      onTap: () {
                        Fluttertoast.showToast(
                          msg: "Privacy settings feature coming soon!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SettingsSectionWidget(
                      title: 'App Preferences',
                      items: [
                        SettingsItem(
                          title: 'Dark Mode',
                          subtitle: themeProvider.isDarkMode
                              ? 'Dark theme enabled'
                              : 'Light theme enabled',
                          iconName: themeProvider.isDarkMode
                              ? 'dark_mode'
                              : 'light_mode',
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: _toggleDarkMode,
                            activeThumbColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () =>
                              _toggleDarkMode(!themeProvider.isDarkMode),
                        ),
                        SettingsItem(
                          title: 'App Version',
                          subtitle: '1.0.0',
                          iconName: 'info',
                          onTap: () {
                            Fluttertoast.showToast(
                              msg: "Quiz Master v1.0.0",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 3.h),
                SignOutButtonWidget(
                  onSignOut: _handleSignOut,
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
