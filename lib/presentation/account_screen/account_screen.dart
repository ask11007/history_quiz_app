import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Change Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 2.h),
              _buildImageSourceOption(
                context,
                'Camera',
                'camera_alt',
                () async {
                  Navigator.pop(context);
                  final success =
                      await userProvider.pickAndUploadProfilePicture(
                    source: ImageSource.camera,
                  );
                  if (success) {
                    Fluttertoast.showToast(
                      msg: "Profile picture updated!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: "Failed to update profile picture",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                    );
                  }
                },
              ),
              _buildImageSourceOption(
                context,
                'Gallery',
                'photo_library',
                () async {
                  Navigator.pop(context);
                  final success =
                      await userProvider.pickAndUploadProfilePicture(
                    source: ImageSource.gallery,
                  );
                  if (success) {
                    Fluttertoast.showToast(
                      msg: "Profile picture updated!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: "Failed to update profile picture",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                    );
                  }
                },
              ),
              _buildImageSourceOption(
                context,
                'Remove Picture',
                'delete',
                () async {
                  Navigator.pop(context);
                  await userProvider.removeProfilePicture();
                  Fluttertoast.showToast(
                    msg: "Profile picture removed",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: iconName,
          color: Theme.of(context).colorScheme.primary,
          size: 6.w,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 6.w),
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
          '/auth',
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

  void _showAppFolderInfo() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final folderInfo = await userProvider.getAppFolderInfo();

      // Close loading dialog
      Navigator.pop(context);

      // Show folder info dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 2.w),
              Text('App Folder Info'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (folderInfo['exists'] == true) ...[
                Text('📍 Location:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(folderInfo['path'], style: TextStyle(fontSize: 12)),
                SizedBox(height: 2.h),
                Text('📊 Statistics:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Folders: ${folderInfo['folder_count']}'),
                Text('• Files: ${folderInfo['file_count']}'),
                Text('• Size: ${_formatBytes(folderInfo['total_size'])}'),
                SizedBox(height: 2.h),
                Text('📁 Contains:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Profile Pictures'),
                Text('• Quiz Data'),
                Text('• Backups'),
                Text('• Media Files'),
              ] else ...[
                Text('App folder not created yet.'),
                SizedBox(height: 1.h),
                Text('The folder will be created when you:'),
                Text('• Update your profile picture'),
                Text('• Export app data'),
                Text('• Grant storage permissions'),
              ],
            ],
          ),
          actions: [
            if (folderInfo['exists'] == true)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await userProvider.exportUserDataToAppFolder();
                  Fluttertoast.showToast(
                    msg: "Data exported to app folder!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
                child: Text('Export Data'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      Fluttertoast.showToast(
        msg: "Error getting folder info: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                          shape: BoxShape.circle, // Changed to circular shape
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
                                  shape: BoxShape
                                      .circle, // Changed to circular shape
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
                      title: 'App Folder',
                      subtitle: 'View app data folder info',
                      iconName: 'folder',
                      onTap: _showAppFolderInfo,
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
                              msg: "Polity 5000+ v1.0.0",
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
