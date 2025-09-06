import 'package:flutter/material.dart';
import '../presentation/auth/phone_auth_screen.dart';
import '../presentation/auth/profile_setup_screen.dart';
import '../presentation/main_navigation_screen.dart';
import '../presentation/quiz_screen/quiz_screen.dart';
import '../presentation/sub_topic_screen/sub_topic_screen.dart';

class AppRoutes {
  static const String initial = '/phone-auth';
  static const String phoneAuth = '/phone-auth';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String main = '/main-navigation';
  static const String subTopic = '/sub-topic-screen';
  static const String quiz = '/quiz-screen';

  static Map<String, WidgetBuilder> routes = {
    phoneAuth: (context) => const PhoneAuthScreen(),
    profileSetup: (context) => const ProfileSetupScreen(),
    main: (context) => const MainNavigationScreen(),
    '/main-navigation': (context) => const MainNavigationScreen(),
    subTopic: (context) => const SubTopicScreen(),
    '/sub-topic-screen': (context) => const SubTopicScreen(),
    quiz: (context) => const QuizScreen(),
  };
}
