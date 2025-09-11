import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../core/services/supabase_service.dart';
import '../core/services/connectivity_service.dart';
import 'dart:math';

class UserProvider extends ChangeNotifier {
  // Default cat avatar URL
  static const String _defaultCatAvatar =
      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=400&fit=crop&crop=face';

  Map<String, dynamic> _userData = {
    "id": null,
    "name": "Guest User",
    "email": "guest@example.com",
    "avatar": _defaultCatAvatar,
    "totalQuizTime": "0h 0m",
    "achievementBadges": 0,
    "joinedDate": DateTime.now().toIso8601String(),
    "lastActive": DateTime.now().toIso8601String(),
    "preferences": {
      "darkMode": false,
      "notifications": true,
      "language": "English"
    }
  };

  bool _isLoading = false;
  bool _isAuthenticated = false;
  User? _currentUser;

  UserProvider() {
    _initializeAuth();
  }

  Map<String, dynamic> get userData => Map.from(_userData);
  String get userName => _userData["name"] as String;
  String get userEmail => _userData["email"] as String;
  String get userAvatar => _userData["avatar"] as String;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;

  // Check if user needs to complete profile setup
  bool get needsProfileSetup {
    if (!_isAuthenticated) return false;

    // Guest users don't need profile setup
    if (_userData["id"]?.toString().startsWith("guest_") == true) return false;

    // Only Supabase users need profile setup
    if (_currentUser == null) return false;

    return _userData["name"] == "Guest User" || _userData["name"] == "User";
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First, try to restore authentication state from local storage
      await _loadUserData();

      // Check if user is already logged in with Supabase
      _currentUser = SupabaseService.client.auth.currentUser;

      if (_currentUser != null) {
        _isAuthenticated = true;
        await _loadUserProfile();
      }

      // Listen to auth state changes
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _currentUser = session.user;
          _isAuthenticated = true;
          _loadUserProfile();
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          _isAuthenticated = false;
          _clearUserData();
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google - Simple Direct Storage Approach
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('📱 === STARTING GOOGLE SIGN-IN (DIRECT STORAGE) ===');
      print('Package name: com.quiz_master.app');

      // Initialize Google Sign-In for Android
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out any existing session to ensure clean state
      await googleSignIn.signOut();

      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ User cancelled Google sign-in');
        return false;
      }

      print('✅ Google sign-in successful!');
      print('User: ${googleUser.displayName} (${googleUser.email})');
      print('Avatar: ${googleUser.photoUrl}');

      // Check if user already exists in our database
      var existingUser = await SupabaseService.getUserByEmail(googleUser.email);

      if (existingUser != null) {
        // User exists, load their data
        print('🔄 Existing user found, loading profile...');
        await _loadDirectUserProfile(existingUser);
      } else {
        // New user, create record in database
        print('🆕 New user, creating profile...');
        await _createDirectUserProfile(googleUser);
      }

      _isAuthenticated = true;
      _currentUser = null; // No Supabase auth user needed

      // Save to local storage
      await _saveUserData();

      print('✅ Google authentication and user data storage completed!');
      print('User ID: ${_userData['id']}');
      print('User Name: ${_userData['name']}');

      return true;
    } catch (e) {
      print('❌ Google sign-in error: $e');

      // Enhanced error handling for common Android Google Sign-In issues
      if (e.toString().contains('ApiException: 10')) {
        throw Exception('Google Sign-In configuration error.\n'
            'Please ensure:\n'
            '• Android OAuth client is configured in Google Cloud Console\n'
            '• Package name: com.quiz_master.app\n'
            '• SHA-1 fingerprint is correct\n'
            '• google-services.json is in android/app/ directory');
      } else if (e.toString().contains('ApiException: 7')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else if (e.toString().contains('ApiException: 12500')) {
        throw Exception('Google Play Services not available or outdated.');
      }

      throw Exception('Failed to sign in with Google: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Only sign out from Supabase if it's not a guest user
      if (_currentUser != null) {
        await SupabaseService.client.auth.signOut();
      }

      _currentUser = null;
      _isAuthenticated = false;
      await _clearUserData();

      print('✅ Sign out completed successfully');
    } catch (e) {
      print('Sign out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Continue as guest - for testing purposes
  Future<bool> continueAsGuest() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Setting up guest user session...');

      // Set guest user data
      _userData = {
        "id": "guest_${DateTime.now().millisecondsSinceEpoch}",
        "name": "Guest User",
        "email": "guest@example.com",
        "avatar": _defaultCatAvatar,
        "totalQuizTime": "0h 0m",
        "achievementBadges": 0,
        "joinedDate": DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };

      // Set authentication state for guest (for UI consistency)
      _isAuthenticated =
          true; // Guest is considered "authenticated" for UI purposes
      _currentUser = null; // But no actual Supabase user

      await _saveGuestData();

      print('✅ Guest session established successfully');
      return true;
    } catch (e) {
      print('❌ Guest login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create user profile directly in database from Google data
  Future<void> _createDirectUserProfile(GoogleSignInAccount googleUser) async {
    try {
      print('=== CREATING DIRECT USER PROFILE ===');

      final userRecord = await SupabaseService.createDirectUser(
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        avatarUrl: googleUser.photoUrl,
      );

      if (userRecord != null) {
        // Successfully created in database
        _userData = {
          "id": userRecord['id'],
          "name": userRecord['name'],
          "email": userRecord['email'],
          "avatar": googleUser.photoUrl ?? _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": userRecord['created_at'],
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };

        print('✅ User profile created and stored in database!');
        print('Database ID: ${userRecord['id']}');
      } else {
        // Database creation failed, create local-only profile
        print('⚠️ Database storage failed, creating local profile only');
        _userData = {
          "id": 'local_${DateTime.now().millisecondsSinceEpoch}',
          "name": googleUser.displayName ?? 'Google User',
          "email": googleUser.email,
          "avatar": googleUser.photoUrl ?? _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": DateTime.now().toIso8601String(),
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };
      }
    } catch (e) {
      print('❌ Error creating direct user profile: $e');
      // Fallback to local profile
      _userData = {
        "id": 'local_${DateTime.now().millisecondsSinceEpoch}',
        "name": googleUser.displayName ?? 'Google User',
        "email": googleUser.email,
        "avatar": googleUser.photoUrl ?? _defaultCatAvatar,
        "totalQuizTime": '0h 0m',
        "achievementBadges": 0,
        "joinedDate": DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };
    }
  }

  // Load existing user profile from database
  Future<void> _loadDirectUserProfile(Map<String, dynamic> userRecord) async {
    try {
      print('=== LOADING EXISTING USER PROFILE ===');
      print('User: ${userRecord['name']} (${userRecord['email']})');

      _userData = {
        "id": userRecord['id'],
        "name": userRecord['name'],
        "email": userRecord['email'],
        "avatar": _defaultCatAvatar, // Default avatar for now
        "totalQuizTime": '0h 0m',
        "achievementBadges": 0,
        "joinedDate":
            userRecord['created_at'] ?? DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };

      print('✅ Existing user profile loaded successfully!');
      print('User ID: ${userRecord['id']}');
      print('Member since: ${userRecord['created_at']}');
    } catch (e) {
      print('❌ Error loading user profile: $e');
      // Create fallback profile
      _userData = {
        "id": userRecord['id'] ??
            'fallback_${DateTime.now().millisecondsSinceEpoch}',
        "name": userRecord['name'] ?? 'User',
        "email": userRecord['email'] ?? 'user@example.com',
        "avatar": _defaultCatAvatar,
        "totalQuizTime": '0h 0m',
        "achievementBadges": 0,
        "joinedDate": DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };
    }
  }

  // Save guest data to SharedPreferences
  Future<void> _saveGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userData['name']);
      await prefs.setString('user_email', _userData['email']);
      await prefs.setString('user_avatar', _userData['avatar']);

      // Save authentication state
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('user_id', _userData['id'] ?? '');
      await prefs.setString('auth_type', 'guest');

      print('Guest data saved to local storage');
    } catch (e) {
      print('Error saving guest data: $e');
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(String name) async {
    print('=== CREATING USER PROFILE ===');
    print('User ID: ${_currentUser?.id}');
    print('User Name: $name');
    print('User Email: ${_currentUser?.email}');

    try {
      if (_currentUser != null) {
        print('Attempting to insert profile into user_profiles table...');

        final insertData = {
          'id': _currentUser!.id,
          'name': name.trim(),
          'avatar_url': null,
          'total_quiz_time': null,
          'achievement_badges': 0,
        };

        print('Insert data: $insertData');

        final response = await SupabaseService.client
            .from('user_profiles')
            .insert(insertData)
            .select();

        print('Insert response: $response');
        print('✅ User profile created successfully for: ${_currentUser!.id}');
      } else {
        print('❌ Current user is null, cannot create profile');
      }
    } catch (e) {
      print('❌ Error creating user profile: $e');
      print('Error type: ${e.runtimeType}');

      // If profile creation fails, still set user data from auth
      if (_currentUser != null) {
        print('Setting fallback user data from auth info...');
        _userData = {
          "id": _currentUser!.id,
          "name": name.trim(),
          "email": _currentUser!.email ?? '',
          "avatar": _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": DateTime.now().toIso8601String(),
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };
        await _saveUserData();
        print('✅ Fallback user data set successfully');
      }
      throw e; // Re-throw to handle in signUp method
    }
  }

  // Create user profile after authentication (called from profile setup screen)
  Future<bool> createUserProfile(String name, String? avatarUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentUser != null) {
        await _createUserProfile(name);

        // Set user data
        _userData = {
          "id": _currentUser!.id,
          "name": name.trim(),
          "email": _currentUser!.email ?? '',
          "avatar": avatarUrl ?? _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": DateTime.now().toIso8601String(),
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };
        await _saveUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('Profile creation error: $e');
      throw Exception('Failed to create profile');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      if (_currentUser != null) {
        final response = await SupabaseService.client
            .from('user_profiles')
            .select()
            .eq('id', _currentUser!.id)
            .single();

        _userData = {
          "id": _currentUser!.id,
          "name": response['name'] ?? 'User',
          "email": _currentUser!.email ?? '',
          "avatar": response['avatar_url'] ?? _defaultCatAvatar,
          "totalQuizTime": _formatInterval(response['total_quiz_time']),
          "achievementBadges": response['achievement_badges'] ?? 0,
          "joinedDate":
              response['created_at'] ?? DateTime.now().toIso8601String(),
          "lastActive":
              response['updated_at'] ?? DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };
        await _saveUserData();
        print('User profile loaded successfully: ${_userData["name"]}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // If profile doesn't exist, create default user data from auth
      if (_currentUser != null) {
        print('Creating fallback user data from auth info');
        final authName = _currentUser!.userMetadata?['name'] ??
            _currentUser!.email?.split('@')[0] ??
            'User';

        _userData = {
          "id": _currentUser!.id,
          "name": authName,
          "email": _currentUser!.email ?? '',
          "avatar": _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": DateTime.now().toIso8601String(),
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };
        await _saveUserData();

        // Try to create the profile in database for future use
        try {
          await SupabaseService.client.from('user_profiles').insert({
            'id': _currentUser!.id,
            'name': authName,
            'avatar_url': null,
            'total_quiz_time': null,
            'achievement_badges': 0,
          });
          print('Retroactively created user profile in database');
        } catch (createError) {
          print('Could not create retroactive profile: $createError');
        }
      }
    }
  }

  // Format interval for display
  String _formatInterval(dynamic interval) {
    if (interval == null) return '0h 0m';
    // This is a basic implementation - you might want to parse the actual interval
    return '0h 0m';
  }

  // Create user profile from Google account data
  Future<void> _createProfileFromGoogleData(
      GoogleSignInAccount googleUser) async {
    try {
      if (_currentUser != null) {
        print('Creating user profile from Google data...');

        final profileData = {
          'id': _currentUser!.id,
          'name': googleUser.displayName ?? 'Google User',
          'avatar_url': googleUser.photoUrl,
          'total_quiz_time': null,
          'achievement_badges': 0,
        };

        print('Inserting profile data: $profileData');

        final response = await SupabaseService.client
            .from('user_profiles')
            .insert(profileData)
            .select();

        print('✅ User profile created from Google data: $response');

        // Set user data
        _userData = {
          "id": _currentUser!.id,
          "name": googleUser.displayName ?? 'Google User',
          "email": _currentUser!.email ?? googleUser.email,
          "avatar": googleUser.photoUrl ?? _defaultCatAvatar,
          "totalQuizTime": '0h 0m',
          "achievementBadges": 0,
          "joinedDate": DateTime.now().toIso8601String(),
          "lastActive": DateTime.now().toIso8601String(),
          "preferences": {
            "darkMode": false,
            "notifications": true,
            "language": "English"
          }
        };

        await _saveUserData();
        print('✅ Google user profile setup complete');
      }
    } catch (e) {
      print('❌ Error creating profile from Google data: $e');
      // Fall back to basic user data setup
      _userData = {
        "id": _currentUser?.id ?? googleUser.id,
        "name": googleUser.displayName ?? 'Google User',
        "email": _currentUser?.email ?? googleUser.email,
        "avatar": googleUser.photoUrl ?? _defaultCatAvatar,
        "totalQuizTime": '0h 0m',
        "achievementBadges": 0,
        "joinedDate": DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };
      await _saveUserData();
    }
  }

  // Load user data from SharedPreferences on app start
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user was previously authenticated
      final wasAuthenticated = prefs.getBool('is_authenticated') ?? false;
      final authType = prefs.getString('auth_type') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (wasAuthenticated && userId.isNotEmpty) {
        // Restore user data
        final Map<String, dynamic> parsedData = {
          'id': userId,
          'name': prefs.getString('user_name') ?? 'User',
          'email': prefs.getString('user_email') ?? '',
          'avatar': prefs.getString('user_avatar') ?? _userData['avatar'],
        };

        _userData = {..._userData, ...parsedData};

        // Restore authentication state based on type
        if (authType == 'direct_storage' ||
            authType == 'direct_storage_offline') {
          _isAuthenticated = true;
          print('✅ Restored Direct Storage authentication state');
          print('User data loaded from local storage: $parsedData');
        } else if (authType == 'google_direct') {
          _isAuthenticated = true;
          print('✅ Restored Google Direct authentication state');
          print('User data loaded from local storage: $parsedData');
        } else if (authType == 'guest') {
          _isAuthenticated = true;
          print('✅ Restored Guest authentication state');
          print('Guest data loaded from local storage: $parsedData');
        } else {
          print('Supabase auth detected - will validate with Supabase');
        }
      } else {
        print('No previous authentication found');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
    notifyListeners();
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userData['name']);
      await prefs.setString('user_email', _userData['email']);
      await prefs.setString('user_avatar', _userData['avatar']);

      // Save authentication state with proper type detection
      await prefs.setBool('is_authenticated', _isAuthenticated);
      await prefs.setString('user_id', _userData['id'] ?? '');

      // Determine authentication type based on user ID and current state
      String authType;
      if (_currentUser != null) {
        authType = 'supabase_oauth';
      } else if (_userData['id']?.toString().startsWith('local_') == true) {
        authType = 'direct_storage_offline';
      } else if (_userData['id']?.toString().startsWith('guest_') == true) {
        authType = 'guest';
      } else if (_userData['id']?.toString().contains('-') == true &&
          _userData['id']?.toString().length == 36) {
        // UUID format indicates database storage
        authType = 'direct_storage';
      } else {
        authType = 'google_direct';
      }

      await prefs.setString('auth_type', authType);
      await prefs.setString('last_auth_time', DateTime.now().toIso8601String());

      print('✅ User data and auth state saved to local storage');
      print('   - Auth Type: $authType');
      print('   - User ID: ${_userData['id']}');
      print('   - User Name: ${_userData['name']}');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<void> updateUserName(String newName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userData["name"] = newName.trim();
      await _saveUserData();

      // Update in Supabase if authenticated
      if (_isAuthenticated && _currentUser != null) {
        await SupabaseService.client
            .from('user_profiles')
            .update({'name': newName.trim()}).eq('id', _currentUser!.id);
      }

      print('User name updated successfully: $newName');
    } catch (e) {
      print('Error updating user name: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserAvatar(String newAvatarUrl) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userData["avatar"] = newAvatarUrl;
      await _saveUserData();

      // Update in Supabase if authenticated
      if (_isAuthenticated && _currentUser != null) {
        await SupabaseService.client
            .from('user_profiles')
            .update({'avatar_url': newAvatarUrl}).eq('id', _currentUser!.id);
      }

      print('User avatar updated successfully: $newAvatarUrl');
    } catch (e) {
      print('Error updating user avatar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userData = {..._userData, ...newData};
      await _saveUserData();
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Test both database tables connectivity
  Future<void> testBothTablesConnection() async {
    print('=== USER PROVIDER: TESTING BOTH TABLES ===');

    try {
      // Run comprehensive diagnostics from SupabaseService
      await SupabaseService.runDatabaseDiagnostics();

      // Test current user state
      print('\n=== CURRENT USER STATE IN PROVIDER ===');
      print('Is authenticated: $_isAuthenticated');
      print('Current user ID: ${_currentUser?.id}');
      print('Current user email: ${_currentUser?.email}');
      print('Current user phone: ${_currentUser?.phone}');
      print('User data name: ${_userData['name']}');
      print('User data email: ${_userData['email']}');
      print('Needs profile setup: $needsProfileSetup');
    } catch (e) {
      print('❌ Database connection test failed: $e');
    }
  }

  // === INTERNAL TESTING METHODS ===

  /// Test authentication flow without UI
  Future<void> testAuthenticationFlow() async {
    print('\n=== TESTING AUTHENTICATION FLOW ===');

    try {
      // Test 1: Check current auth state
      print('1. Current authentication state:');
      print('   - Authenticated: $_isAuthenticated');
      print('   - User ID: ${_currentUser?.id}');
      print('   - User email: ${_currentUser?.email}');

      // Test 2: Check auth listeners
      print('\n2. Testing auth state listeners...');
      final authStream = SupabaseService.client.auth.onAuthStateChange;
      print('   - Auth stream available: ${authStream != null}');

      // Test 3: Check session validity
      final session = SupabaseService.client.auth.currentSession;
      print('\n3. Current session:');
      if (session != null) {
        print('   ✅ Session active');
        print('   - Expires at: ${session.expiresAt}');
        print('   - Token type: ${session.tokenType}');
      } else {
        print('   ❌ No active session');
      }

      // Test 4: Check Supabase Auth configuration
      print('\n4. Supabase Auth Configuration:');
      print(
          '   - Supabase client initialized: ${SupabaseService.client != null}');
      print(
          '   - Auth client available: ${SupabaseService.client.auth != null}');

      // Test 5: Test Google Auth availability
      print('\n6. Google Auth Configuration Status:');
      print('   - ⚠️  Google OAuth Setup Required:');
      print('     1. Go to Google Cloud Console');
      print('     2. Create OAuth 2.0 credentials');
      print(
          '     3. Add redirect URI: https://pdstonywpulfhsdiarmr.supabase.co/auth/v1/callback');
      print(
          '     4. Configure in Supabase Dashboard → Authentication → Providers');
      print('     5. Enable Google provider with Client ID & Secret');
      print('   - Deep link configured: com.quiz_master.app://login-callback/');
    } catch (e) {
      print('❌ Authentication flow test failed: $e');
    }
  }

  /// Test data persistence without UI
  Future<void> testDataPersistence() async {
    print('\n=== TESTING DATA PERSISTENCE ===');

    try {
      // Test SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      print('1. SharedPreferences data:');
      print('   - Stored name: ${prefs.getString('user_name')}');
      print('   - Stored email: ${prefs.getString('user_email')}');
      print('   - Stored avatar: ${prefs.getString('user_avatar')}');

      // Test in-memory data
      print('\n2. In-memory user data:');
      print('   - Name: ${_userData['name']}');
      print('   - Email: ${_userData['email']}');
      print('   - Avatar: ${_userData['avatar']}');
      print('   - Total quiz time: ${_userData['totalQuizTime']}');
      print('   - Achievement badges: ${_userData['achievementBadges']}');

      // Test data consistency
      final storedName = prefs.getString('user_name');
      final memoryName = _userData['name'];
      print('\n3. Data consistency check:');
      print(
          '   - Names match: ${storedName == memoryName} ($storedName vs $memoryName)');
    } catch (e) {
      print('❌ Data persistence test failed: $e');
    }
  }

  /// Test database operations without UI
  Future<void> testDatabaseOperations() async {
    print('\n=== TESTING DATABASE OPERATIONS ===');

    try {
      // Test 1: Questions table operations
      print('1. Testing Questions table:');
      final questions = await SupabaseService.getAvailableTags();
      print('   ✅ Available question tags: $questions');

      if (questions.isNotEmpty) {
        final sampleQuestions =
            await SupabaseService.getQuestionsByTag(questions.first);
        print(
            '   ✅ Sample questions for "${questions.first}": ${sampleQuestions.length} found');
      }

      // Test 2: User profiles table operations
      print('\n2. Testing User Profiles table:');
      if (_currentUser != null) {
        try {
          final profile = await SupabaseService.client
              .from('user_profiles')
              .select('*')
              .eq('id', _currentUser!.id)
              .single();
          print('   ✅ Current user profile found: ${profile['name']}');
        } catch (e) {
          print('   ❌ Current user profile not found: $e');
        }
      }

      // Test 3: Database connectivity
      print('\n3. Testing database connectivity:');
      final connectionTest = await SupabaseService.client
          .from('questions')
          .select('count')
          .limit(1);
      print('   ✅ Database connection active: ${connectionTest != null}');
    } catch (e) {
      print('❌ Database operations test failed: $e');
    }
  }

  /// Test profile operations without UI
  Future<void> testProfileOperations() async {
    print('\n=== TESTING PROFILE OPERATIONS ===');

    try {
      if (!_isAuthenticated || _currentUser == null) {
        print('❌ Cannot test profile operations - user not authenticated');
        return;
      }

      print('1. Current profile state:');
      print('   - User ID: ${_currentUser!.id}');
      print('   - Display name: ${_userData['name']}');
      print('   - Avatar URL: ${_userData['avatar']}');
      print('   - Needs setup: $needsProfileSetup');

      // Test profile update capability
      print('\n2. Testing profile update capability:');
      final originalName = _userData['name'];
      final testName = 'Test User ${DateTime.now().millisecondsSinceEpoch}';

      try {
        await updateUserName(testName);
        print('   ✅ Profile name update successful: $testName');

        // Restore original name
        await updateUserName(originalName as String);
        print('   ✅ Profile name restored: $originalName');
      } catch (e) {
        print('   ❌ Profile update failed: $e');
      }
    } catch (e) {
      print('❌ Profile operations test failed: $e');
    }
  }

  /// Run comprehensive internal tests
  Future<void> runComprehensiveInternalTests() async {
    print('\n🧪 === RUNNING COMPREHENSIVE INTERNAL TESTS ===');
    print('Testing all app internal functions without UI interaction\n');

    // Run all tests sequentially
    await testAuthenticationFlow();
    await testDataPersistence();
    await testDatabaseOperations();
    await testProfileOperations();
    await testBothTablesConnection();

    print('\n✅ === ALL INTERNAL TESTS COMPLETED ===');
    print('Check the console output above for detailed results.');
  }

  /// Test Google OAuth specifically
  Future<void> testGoogleAuth() async {
    print('\n🔑 === TESTING GOOGLE OAUTH ===');

    try {
      print('1. Attempting Google authentication...');
      final success = await signInWithGoogle();

      if (success) {
        print('✅ Google OAuth initiated successfully!');
        print('   - Browser/WebView should open');
        print('   - Google OAuth is configured correctly');
      } else {
        print('❌ Google OAuth failed');
      }
    } catch (e) {
      print('❌ Google OAuth Error: $e');

      if (e.toString().contains('OAuth') || e.toString().contains('client')) {
        print('\n🔧 SOLUTION: Google OAuth Not Configured');
        print('1. Go to Google Cloud Console');
        print('2. Create OAuth 2.0 credentials');
        print(
            '3. Add redirect URI: https://pdstonywpulfhsdiarmr.supabase.co/auth/v1/callback');
        print('4. Go to Supabase Dashboard → Authentication → Providers');
        print('5. Enable Google provider with Client ID & Secret');
      } else {
        print('\n🔧 SOLUTION: Check Configuration');
        print('- Verify deep linking setup');
        print('- Check AndroidManifest.xml has intent filter');
      }
    }
  }

  /// Test specific question loading issue
  Future<void> testQuestionLoading() async {
    print('\n📚 === TESTING QUESTION LOADING ISSUE ===');

    try {
      // Test 1: Basic Supabase connection
      print('1. Testing basic Supabase connection...');
      final client = SupabaseService.client;
      print('   ✅ Supabase client available: ${client != null}');

      // Test 2: Test questions table existence
      print('\n2. Testing questions table...');
      try {
        final countResponse =
            await client.from('questions').select('count').limit(1);
        print('   ✅ Questions table accessible: $countResponse');
      } catch (e) {
        print('   ❌ Questions table error: $e');
        print(
            '   🔧 SOLUTION: Questions table might not exist or have wrong permissions');
        return;
      }

      // Test 3: Check if questions table has data
      print('\n3. Checking questions table data...');
      try {
        final allQuestions =
            await client.from('questions').select('id, question, tag').limit(5);
        print('   ✅ Questions found: ${allQuestions.length}');

        if (allQuestions.isEmpty) {
          print('   ❌ PROBLEM FOUND: Questions table is EMPTY!');
          print('   🔧 SOLUTION: You need to add questions to your database');
          print('      1. Go to Supabase Dashboard → Table Editor → questions');
          print('      2. Insert sample questions manually, or');
          print('      3. Use SQL insert statements from SUPABASE_SETUP.md');
          return;
        }

        // Show sample questions
        for (var q in allQuestions) {
          final questionText = q['question']?.toString() ?? '';
          final truncated = questionText.length > 30
              ? questionText.substring(0, 30) + '...'
              : questionText;
          print(
              '     - ID: ${q['id']}, Tag: ${q['tag']}, Question: "$truncated"');
        }
      } catch (e) {
        print('   ❌ Error reading questions: $e');
      }

      // Test 4: Check available tags (subjects)
      print('\n4. Testing available subjects/tags...');
      try {
        final tags = await SupabaseService.getAvailableTags();
        print('   ✅ Available subjects: $tags');

        if (tags.isEmpty) {
          print('   ❌ PROBLEM: No subject tags found!');
          print('   🔧 SOLUTION: Add questions with different "tag" values');
        }
      } catch (e) {
        print('   ❌ Error fetching tags: $e');
      }

      // Test 5: Test specific question fetching
      print('\n5. Testing question fetching by tag...');
      try {
        final tags = await SupabaseService.getAvailableTags();
        if (tags.isNotEmpty) {
          final firstTag = tags.first;
          print('   Testing with tag: "$firstTag"');

          final questions = await SupabaseService.getQuestionsByTag(firstTag);
          print('   ✅ Questions for "$firstTag": ${questions.length} found');

          if (questions.isEmpty) {
            print('   ❌ PROBLEM: getQuestionsByTag returned empty list!');
          } else {
            final questionText = questions.first.question;
            final truncated = questionText.length > 50
                ? questionText.substring(0, 50) + '...'
                : questionText;
            print('   ✅ Sample question: "$truncated"');
          }
        }
      } catch (e) {
        print('   ❌ Error in getQuestionsByTag: $e');
      }
    } catch (e) {
      print('❌ Question loading test failed: $e');
    }

    print('\n=== QUESTION LOADING TEST COMPLETE ===');
  }

  // Image picker and upload functionality
  final ImagePicker _imagePicker = ImagePicker();

  // Pick and upload profile picture
  Future<bool> pickAndUploadProfilePicture({ImageSource source = ImageSource.gallery}) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Starting image picker with source: $source');

      // Pick image from device
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return false;
      }

      print('Image picked: ${pickedFile.path}');
      
      // Upload to Supabase Storage
      final String fileName = 'profile_${_userData['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final File imageFile = File(pickedFile.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      print('Uploading image to Supabase storage...');
      
      // Upload to Supabase storage bucket
      await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(fileName, imageBytes);
      
      // Get public URL
      final String publicUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      print('Image uploaded successfully: $publicUrl');
      
      // Update user avatar
      await updateUserAvatar(publicUrl);
      
      return true;
    } catch (e) {
      print('Error uploading profile picture: $e');
      
      // If Supabase storage fails, just update with local file path for now
      // This is a fallback - in production you'd want proper error handling
      if (e.toString().contains('bucket') || e.toString().contains('storage')) {
        print('Supabase storage not configured, using default avatar');
        // You could implement local storage or show specific error message
      }
      
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show image picker options
  Future<bool> showImagePickerOptions() async {
    // This will be called from UI to show options
    return await pickAndUploadProfilePicture(source: ImageSource.gallery);
  }

  // Remove profile picture (set to default cat avatar)
  Future<void> removeProfilePicture() async {
    await updateUserAvatar(_defaultCatAvatar);
  }

  // Clear user data (for logout)
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_avatar');

      // Clear authentication state
      await prefs.remove('is_authenticated');
      await prefs.remove('user_id');
      await prefs.remove('auth_type');

      // Reset to guest user data
      _userData = {
        "id": null,
        "name": "Guest User",
        "email": "guest@example.com",
        "avatar": _defaultCatAvatar,
        "totalQuizTime": "0h 0m",
        "achievementBadges": 0,
        "joinedDate": DateTime.now().toIso8601String(),
        "lastActive": DateTime.now().toIso8601String(),
        "preferences": {
          "darkMode": false,
          "notifications": true,
          "language": "English"
        }
      };

      print('User data and authentication state cleared');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
