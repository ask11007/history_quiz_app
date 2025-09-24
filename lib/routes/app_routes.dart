import 'package:flutter/material.dart';
import '../presentation/auth/auth_screen.dart';
import '../presentation/auth/profile_setup_screen.dart';
import '../presentation/main_navigation_screen.dart';
import '../presentation/quiz_screen/quiz_screen.dart';
// SubTopicScreen removed since sub_tag column is no longer used

class AppRoutes {
  static const String initial = '/auth';
  static const String auth = '/auth';
  static const String profileSetup = '/profile-setup';
  static const String main = '/main-navigation';
  // subTopic route removed since sub_tag column is no longer used
  static const String quiz = '/quiz-screen';

  static Map<String, WidgetBuilder> routes = {
    auth: (context) => const AuthScreen(),
    profileSetup: (context) => const ProfileSetupScreen(),
    main: (context) => const MainNavigationScreen(),
    // subTopic route removed since sub_tag column is no longer used
    quiz: (context) => const QuizScreen(),
  };
}