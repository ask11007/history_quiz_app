import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class TestDirectStorageScreen extends StatefulWidget {
  const TestDirectStorageScreen({Key? key}) : super(key: key);

  @override
  State<TestDirectStorageScreen> createState() =>
      _TestDirectStorageScreenState();
}

class _TestDirectStorageScreenState extends State<TestDirectStorageScreen> {
  String _testOutput = '';
  bool _isRunning = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  void _addOutput(String text) {
    setState(() {
      _testOutput += '$text\n';
    });
  }

  Future<void> _testDirectUserCreation() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _addOutput('❌ Please enter both name and email');
      return;
    }

    setState(() {
      _isRunning = true;
      _testOutput = '🧪 Testing Direct User Creation...\n\n';
    });

    try {
      _addOutput(
          '📝 Creating user: ${_nameController.text} (${_emailController.text})');

      final userRecord = await SupabaseService.createDirectUser(
        name: _nameController.text,
        email: _emailController.text,
      );

      if (userRecord != null) {
        _addOutput('✅ User created successfully!');
        _addOutput('   - ID: ${userRecord['id']}');
        _addOutput('   - Name: ${userRecord['name']}');
        _addOutput('   - Email: ${userRecord['email']}');
        _addOutput('   - Created: ${userRecord['created_at']}');
      } else {
        _addOutput('❌ User creation failed');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testUserRetrieval() async {
    if (_emailController.text.isEmpty) {
      _addOutput('❌ Please enter an email to search');
      return;
    }

    setState(() {
      _isRunning = true;
    });

    try {
      _addOutput('\n🔍 Looking for user: ${_emailController.text}');

      final user = await SupabaseService.getUserByEmail(_emailController.text);

      if (user != null) {
        _addOutput('✅ User found!');
        _addOutput('   - ID: ${user['id']}');
        _addOutput('   - Name: ${user['name']}');
        _addOutput('   - Email: ${user['email']}');
        _addOutput('   - Created: ${user['created_at']}');
      } else {
        _addOutput('❌ User not found');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testAllUsers() async {
    setState(() {
      _isRunning = true;
    });

    try {
      _addOutput('\n📋 Fetching all users...');

      final users = await SupabaseService.getAllUsers();

      _addOutput('✅ Found ${users.length} users:');
      for (var user in users) {
        _addOutput(
            '   - ${user['name']} (${user['email']}) - ${user['created_at']}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testGoogleAuth() async {
    setState(() {
      _isRunning = true;
      _testOutput =
          '🔑 Testing Google Authentication with Direct Storage...\n\n';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      _addOutput('📱 Starting Google Sign-In...');
      final success = await userProvider.signInWithGoogle();

      if (success) {
        _addOutput('✅ Google authentication successful!');
        _addOutput('   - User authenticated: ${userProvider.isAuthenticated}');
        _addOutput('   - User name: ${userProvider.userName}');
        _addOutput('   - User email: ${userProvider.userEmail}');
        _addOutput('   - User ID: ${userProvider.userData['id']}');

        // Check if user was stored in database
        final dbUser =
            await SupabaseService.getUserByEmail(userProvider.userEmail);
        if (dbUser != null) {
          _addOutput('✅ User record found in database!');
          _addOutput('   - Database ID: ${dbUser['id']}');
        } else {
          _addOutput('⚠️ User not found in database (may be local only)');
        }
      } else {
        _addOutput('❌ Google authentication failed');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Test User';
    _emailController.text = 'testuser@example.com';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Storage Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Direct User Storage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Input fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Test buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _testDirectUserCreation,
                  child: const Text('Create User'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testUserRetrieval,
                  child: const Text('Find User'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testAllUsers,
                  child: const Text('List All'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testGoogleAuth,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Test Google Auth'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testOutput = '';
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Clear Output'),
            ),

            const SizedBox(height: 20),

            const Text(
              'Test Output:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testOutput.isEmpty
                        ? 'No output yet. Run tests to see results.'
                        : _testOutput,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            if (_isRunning)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
