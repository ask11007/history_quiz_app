import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import '../models/question_report_model.dart';
import '../config/supabase_config.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static const String _supabaseUrl = SupabaseConfig.url;
  static const String _supabaseAnonKey = SupabaseConfig.anonKey;

  static late SupabaseClient _client;
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    try {
      print('Initializing Supabase with URL: $_supabaseUrl');
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      print('Supabase initialized successfully. Client: $_client');

      // Only do a minimal connection test - no heavy queries
      try {
        final testResponse =
            await _client.from('civil_question').select('count').limit(1);
        print('Database connection test successful: $testResponse');
      } catch (e) {
        print('Database connection test failed: $e');
      }
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => _client;

  // === USER MANAGEMENT METHODS ===

  /// Create a new user record directly in your custom table
  /// This bypasses Supabase Auth and stores user data directly
  static Future<Map<String, dynamic>?> createDirectUser({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    try {
      print('=== CREATING DIRECT USER RECORD ===');
      print('Name: $name');
      print('Email: $email');
      print('Avatar URL: ${avatarUrl ?? "None"}');
      // Generate a unique UUID for the user
      final userId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final userData = {
        'id': userId,
        'name': name.trim(),
        'email': email.toLowerCase().trim(),
        'created_at': now,
      };

      print('Attempting to insert user data: $userData');

      // Insert into your custom users table
      final response = await _client
          .from('user_profiles') // Assuming this is your table name
          .insert(userData)
          .select()
          .single();

      print('✅ User created successfully in database');
      print('User ID: ${response['id']}');
      print('Created at: ${response['created_at']}');

      return response;
    } catch (e) {
      print('❌ Failed to create user record: $e');
      print('Error details: ${e.toString()}');

      // Check if it's a duplicate email error
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique')) {
        print('🔄 User with this email might already exist');
        return await getUserByEmail(email);
      }

      return null;
    }
  }

  /// Get user by email from your custom table
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      print('🔍 Looking for user with email: $email');

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (response != null) {
        print(
            '✅ Found existing user: ${response['name']} (ID: ${response['id']})');
        return response;
      } else {
        print('ℹ️ No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user by email: $e');
      return null;
    }
  }

  /// Get user by ID from your custom table
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      print('🔍 Looking for user with ID: $userId');

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        print('✅ Found user: ${response['name']} (${response['email']})');
        return response;
      } else {
        print('ℹ️ No user found with ID: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user by ID: $e');
      return null;
    }
  }

  /// Update user information
  static Future<Map<String, dynamic>?> updateUser(
    String userId, {
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      print('🔄 Updating user: $userId');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name.trim();
      if (email != null) updateData['email'] = email.toLowerCase().trim();

      if (updateData.isEmpty) {
        print('ℹ️ No data to update');
        return await getUserById(userId);
      }

      print('Update data: $updateData');

      final response = await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      print('✅ User updated successfully');
      return response;
    } catch (e) {
      print('❌ Error updating user: $e');
      return null;
    }
  }

  /// Check if email already exists
  static Future<bool> emailExists(String email) async {
    try {
      final user = await getUserByEmail(email);
      return user != null;
    } catch (e) {
      print('❌ Error checking email existence: $e');
      return false;
    }
  }

  /// Get all users (for admin purposes)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('*')
          .order('created_at', ascending: false);

      print('📋 Retrieved ${response.length} users from database');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching all users: $e');
      return [];
    }
  }

  // Comprehensive database diagnostics - Test BOTH tables
  static Future<void> runDatabaseDiagnostics() async {
    print('=== TESTING BOTH DATABASE TABLES ===');

    try {
      // Test 1: Check if Supabase is initialized
      print('1. Checking Supabase initialization...');
      if (_client == null) {
        print('❌ Supabase client is null!');
        return;
      }
      print('✅ Supabase client initialized');

      // Test 2: Check authentication
      print('\n2. Checking authentication...');
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        print('✅ User is authenticated: ${currentUser.id}');
        print('   Email: ${currentUser.email}');
        print('   Phone: ${currentUser.phone}');
        print('   Created: ${currentUser.createdAt}');
      } else {
        print('❌ No authenticated user');
      }

      // Test 3: CIVIL_QUESTION table
      print('\n3. Testing CIVIL_QUESTION table...');
      try {
        final questionsTest = await _client
            .from('civil_question')
            .select('id, question, exam_name')
            .limit(3);
        print('✅ Civil question table accessible');
        print('   Sample questions found: ${questionsTest.length}');
        for (var q in questionsTest) {
          print(
              '   - ID: ${q['id']}, Exam: ${q['exam_name']}, Question: ${q['question']?.toString().substring(0, 50)}...');
        }

        // Test available exam_names in civil_question
        final tagsTest =
            await _client.from('civil_question').select('exam_name').limit(10);
        final uniqueTags = tagsTest.map((q) => q['exam_name']).toSet().toList();
        print('   Available quiz subjects: $uniqueTags');
      } catch (e) {
        print('❌ Civil question table error: $e');
      }

      // Test 4: USER_PROFILES table
      print('\n4. Testing USER_PROFILES table...');
      try {
        final profilesTest = await _client
            .from('user_profiles')
            .select('id, name, created_at')
            .limit(5);
        print('✅ User profiles table accessible');
        print('   User profiles found: ${profilesTest.length}');
        for (var profile in profilesTest) {
          print(
              '   - ID: ${profile['id']}, Name: ${profile['name']}, Created: ${profile['created_at']}');
        }
      } catch (e) {
        print('❌ User profiles table error: $e');
      }

      // Test 5: Check current user profile specifically
      if (currentUser != null) {
        print('\n5. Testing current user profile...');
        try {
          final userProfile = await _client
              .from('user_profiles')
              .select('*')
              .eq('id', currentUser.id)
              .single();
          print('✅ Current user profile found: ${userProfile['name']}');
          print('   Profile data: $userProfile');
        } catch (e) {
          print('❌ Current user profile not found: $e');
        }
      }

      // Test 6: Check table structures
      print('\n6. Testing table structures...');
      try {
        final questionsStructure =
            await _client.from('civil_question').select('*').limit(1);
        if (questionsStructure.isNotEmpty) {
          print(
              '✅ Civil question table structure: ${questionsStructure.first.keys.toList()}');
        }
      } catch (e) {
        print('❌ Civil question structure error: $e');
      }

      try {
        final profilesStructure =
            await _client.from('user_profiles').select('*').limit(1);
        if (profilesStructure.isNotEmpty) {
          print(
              '✅ User profiles table structure: ${profilesStructure.first.keys.toList()}');
        }
      } catch (e) {
        print('❌ User profiles structure error: $e');
      }

      // Test 7: Test insert capability (if user is authenticated)
      if (currentUser != null) {
        print('\n7. Testing insert capability...');
        try {
          final testInsert = await _client.from('user_profiles').insert({
            'id': currentUser.id,
            'name': 'Test User ${DateTime.now().millisecondsSinceEpoch}',
            'avatar_url': null,
          }).select();
          print('✅ Insert test successful: $testInsert');

          // Clean up test data
          await _client.from('user_profiles').delete().eq('id', currentUser.id);
          print('✅ Test data cleaned up');
        } catch (e) {
          print('❌ Insert test failed: $e');
        }
      }
    } catch (e) {
      print('❌ Database diagnostics failed: $e');
    }

    print('\n=== BOTH TABLES TEST COMPLETE ===');
  }

  // Test database connection and table structure
  static Future<void> testConnection() async {
    try {
      print('Testing Supabase connection...');

      // Test 1: Check if table exists
      final tableTest =
          await _client.from('civil_question').select('id').limit(1);
      print('Table test result: $tableTest');

      // Test 2: Check table structure
      final structureTest =
          await _client.from('civil_question').select('*').limit(1);
      print('Structure test result: $structureTest');

      // Test 3: Check available exam_names
      final tagsTest = await _client.from('civil_question').select('exam_name');
      print('Exam names test result: $tagsTest');
    } catch (e) {
      print('Connection test failed: $e');
    }
  }

  // Fetch questions by exam_name (subject)
  static Future<List<Question>> getQuestionsByTag(String examName) async {
    try {
      print('Fetching questions for exam_name: "$examName"');

      // First, let's check what's actually in the table
      final allData = await _client.from('civil_question').select('*').limit(3);
      print('Raw database content (first 3 rows): $allData');

      // Then try the specific query
      final response = await _client
          .from('civil_question')
          .select()
          .eq('exam_name', examName)
          .order('id');

      print('Supabase response for exam_name "$examName": $response');
      print('Response type: ${response.runtimeType}');
      print('Response length: ${response?.length ?? 'null'}');

      if (response == null || response.isEmpty) {
        print('No questions found for exam_name: $examName');
        return [];
      }

      final questions =
          (response as List).map((json) => Question.fromJson(json)).toList();
      print('Successfully parsed ${questions.length} questions');
      return questions;
    } catch (e) {
      print('Error fetching questions by exam_name: $e');
      print('Error type: ${e.runtimeType}');
      return [];
    }
  }

  // Fetch all questions
  static Future<List<Question>> getAllQuestions() async {
    try {
      final response =
          await _client.from('civil_question').select().order('id');

      return (response as List).map((json) => Question.fromJson(json)).toList();
      return [];
    } catch (e) {
      print('Error fetching all questions: $e');
      return [];
    }
  }

  // Fetch available exam_names (subjects)
  static Future<List<String>> getAvailableTags() async {
    try {
      print('Fetching available exam_names from civil_question table...');

      // First check if table has any data at all
      final countCheck =
          await _client.from('civil_question').select('id').limit(1);
      print('Table data check: $countCheck');

      if (countCheck.isEmpty) {
        print('❌ PROBLEM: Civil question table is completely EMPTY!');
        print('   You need to add data to your civil_question table');
        return [];
      }

      final response = await _client
          .from('civil_question')
          .select('exam_name')
          .order('exam_name');
      print('Exam names response: $response');

      if (response == null || response.isEmpty) {
        print('No exam_names found in response');
        return [];
      }

      final examNames = (response as List)
          .map((json) => json['exam_name'] as String)
          .toSet() // Remove duplicates
          .toList();
      print('Available exam_names extracted: $examNames');
      return examNames;
    } catch (e) {
      print('Error fetching exam_names: $e');
      print('Error type: ${e.runtimeType}');
      return [];
    }
  }

  // NOTE: This method returns empty list since civil_question table doesn't have sub_tag column
  // Kept for backward compatibility
  static Future<List<String>> getAvailableSubTags(String examName) async {
    try {
      print('getAvailableSubTags called for exam_name: "$examName"');
      print(
          '⚠️ Note: civil_question table doesn\'t have sub_tag column, returning empty list');

      // Since civil_question table doesn't have sub_tag column, return empty list
      return [];
    } catch (e) {
      print('Error in getAvailableSubTags: $e');
      return [];
    }
  }

  // NOTE: This method returns empty list since civil_question table doesn't have sub_tag column
  // Kept for backward compatibility
  static Future<List<Question>> getQuestionsByTagAndSubTag(
      String examName, String subTag) async {
    try {
      print(
          'getQuestionsByTagAndSubTag called for exam_name: "$examName" and sub_tag: "$subTag"');
      print(
          '⚠️ Note: civil_question table doesn\'t have sub_tag column, returning empty list');

      // Since civil_question table doesn't have sub_tag column, return empty list
      return [];
    } catch (e) {
      print('Error in getQuestionsByTagAndSubTag: $e');
      return [];
    }
  }

  // Add a new question
  static Future<bool> addQuestion(Question question) async {
    try {
      await _client.from('civil_question').insert(question.toJson());
      return true;
    } catch (e) {
      print('Error adding question: $e');
      return false;
    }
  }

  // Update a question
  static Future<bool> updateQuestion(Question question) async {
    try {
      await _client
          .from('civil_question')
          .update(question.toJson())
          .eq('id', question.id);
      return true;
    } catch (e) {
      print('Error updating question: $e');
      return false;
    }
  }

  // Delete a question
  static Future<bool> deleteQuestion(int id) async {
    try {
      await _client.from('civil_question').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting question: $e');
      return false;
    }
  }

  // === QUESTION REPORT METHODS ===

  /// Submit a question report to the database
  static Future<bool> submitQuestionReport(QuestionReport report) async {
    try {
      print('Submitting question report: ${report.toJson()}');

      final response = await _client
          .from('question_reports')
          .insert(report.toJson())
          .select()
          .single();

      print('Question report submitted successfully: $response');
      return true;
    } catch (e) {
      print('Error submitting question report: $e');
      return false;
    }
  }

  /// Get all reports for a specific question
  static Future<List<QuestionReport>> getQuestionReports(int questionId) async {
    try {
      final response = await _client
          .from('question_reports')
          .select()
          .eq('question_id', questionId)
          .order('reported_at', ascending: false);

      return (response as List)
          .map((json) => QuestionReport.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching question reports: $e');
      return [];
    }
  }

  /// Get all reports (for admin purposes)
  static Future<List<QuestionReport>> getAllReports() async {
    try {
      final response = await _client
          .from('question_reports')
          .select()
          .order('reported_at', ascending: false);

      return (response as List)
          .map((json) => QuestionReport.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all reports: $e');
      return [];
    }
  }

  /// Delete a report (for admin purposes)
  static Future<bool> deleteReport(int reportId) async {
    try {
      await _client.from('question_reports').delete().eq('id', reportId);
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }
}
