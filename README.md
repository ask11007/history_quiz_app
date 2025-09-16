# Polity 5000+

A comprehensive political science quiz application featuring 5000+ questions, user authentication, interactive quizzes, and personalized user profiles.

## 📋 Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

## 📁 Project Structure

```
history_quiz_app/
├── android/                    # Android-specific configuration
├── assets/                     # Static assets (images, fonts, etc.)
├── lib/
│   ├── core/                   # Core utilities and services
│   │   ├── config/             # App configuration
│   │   ├── models/             # Data models
│   │   ├── services/           # Backend services
│   │   └── app_export.dart     # Core exports
│   ├── presentation/           # UI screens and widgets
│   │   ├── auth/               # Authentication screens
│   │   ├── home_screen/        # Home screen and widgets
│   │   ├── quiz_screen/        # Quiz interface
│   │   ├── account_screen/     # User account management
│   │   ├── sub_topic_screen/   # Topic selection
│   │   └── main_navigation_screen.dart
│   ├── providers/              # State management
│   ├── routes/                 # Application routing
│   ├── theme/                  # Theme configuration
│   ├── widgets/                # Reusable UI components
│   └── main.dart               # Application entry point
├── pubspec.yaml                # Project dependencies
├── README.md                   # Project documentation
└── SUPABASE_SETUP.md          # Backend setup guide
```

## 🚀 Features

- **User Authentication**: Google Sign-In with Supabase
- **Interactive Quizzes**: History-focused questions with multiple choice answers
- **User Profiles**: Customizable profiles with profile pictures
- **Progress Tracking**: Track quiz performance and statistics
- **Responsive Design**: Optimized for various mobile device sizes
- **Theme Support**: Light and dark mode themes
- **Local Storage**: Profile pictures and app data stored locally

## 🔧 Backend Setup

This app uses Supabase as the backend service. For detailed setup instructions, see [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

### Quick Setup:
1. Create a Supabase project
2. Update `lib/core/config/supabase_config.dart` with your credentials
3. Set up the required database tables (see SUPABASE_SETUP.md)
4. Configure Google OAuth for authentication

## 🎨 Tech Stack

- **Framework**: Flutter 3.29.2
- **Language**: Dart
- **Backend**: Supabase (PostgreSQL database, Authentication, Storage)
- **State Management**: Provider pattern
- **UI**: Material Design with custom theming
- **Authentication**: Google Sign-In + Supabase Auth
- **Responsive Design**: Sizer package
- **Image Handling**: Image picker for profile pictures
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
