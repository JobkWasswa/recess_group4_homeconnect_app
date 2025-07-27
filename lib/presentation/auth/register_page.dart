import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homeconnect/config/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _showPassword = false;
  bool _agreeToTerms = false;
  String _userType = 'homeowner';

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _passwordError;
  String? _confirmError;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _navigateAfterRegistration() {
    if (_userType == 'homeowner') {
      Navigator.pushReplacementNamed(context, AppRoutes.homeownerDashboard);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.serviceProviderCreateProfile,
      );
    }
  }

  Future<void> _saveRoleToFirestore(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'userType': _userType,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      if (_userType == 'homeowner') 'location': _locationCtrl.text,
    });
  }

  Future<void> _registerWithEmail() async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await _saveRoleToFirestore(cred.user!.uid, cred.user!.email!);
      _navigateAfterRegistration();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      final userCred = await _auth.signInWithPopup(googleProvider);
      await _saveRoleToFirestore(userCred.user!.uid, userCred.user!.email!);
      _navigateAfterRegistration();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    }
  }

  bool _validateForm() {
    bool ok = true;
    if (_emailCtrl.text.isEmpty) ok = false;

    if (_passwordCtrl.text.length < 6) {
      _passwordError = 'Min 6 characters';
      ok = false;
    } else {
      _passwordError = null;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      _confirmError = 'Passwords do not match';
      ok = false;
    } else {
      _confirmError = null;
    }

    if (_userType == 'homeowner' && _locationCtrl.text.isEmpty) {
      ok = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your location')),
      );
    }

    if (!_agreeToTerms) ok = false;
    setState(() {});
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 4,
          centerTitle: true,
          title: const Text(
            'Create Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8A80), // light pink
                  Color(0xFF6A11CB), // purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Join as:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildRoleButton('homeowner', 'Homeowner')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleButton('provider', 'Service Provider'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                errorText: _confirmError,
              ),
            ),
            const SizedBox(height: 16),
            if (_userType == 'homeowner') ...[
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g. Kampala)',
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                ),
                const Expanded(
                  child: Text('I agree to the Terms & Conditions'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Image.asset('lib/assets/google_logo.png', width: 20),
              label: const Text('Sign up with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _signUpWithGoogle,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_validateForm()) {
                  _registerWithEmail();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fix errors & agree to terms'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed:
                      () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String type, String label) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.transparent,
          border: Border.all(color: selected ? Colors.blue : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
