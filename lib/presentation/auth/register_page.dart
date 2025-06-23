import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // FIX: Added import for TapGestureRecognizer
import 'package:homeconnect/presentation/homeowner/pages/homeowner_dashboard_screen.dart'; // Import for navigation
import 'package:homeconnect/presentation/service_provider/pages/service_provider_dashboard_screen.dart'; // Import for navigation
import 'package:homeconnect/presentation/auth/login_page.dart'; // Import to link back to login

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  bool _showPassword = false;
  String _userType =
      'homeowner'; // 'homeowner' or 'provider' - State for user type selection
  bool _agreeToTerms = false;

  // Controllers for form fields (specific to registration)
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Separate for register
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // Separate for register
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // For basic password validation feedback
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- NEW: Navigation Helper (Local to this page) ---
  void _handleAuthSuccess(BuildContext context) {
    // For UI-first, we're just simulating success and navigating.
    // In the future, this is where actual Firebase authentication logic goes.
    print('Simulating Registration for User Type: $_userType');

    if (_userType == 'homeowner') {
      Navigator.of(context).pushReplacementNamed('/homeowner_dashboard');
    } else {
      // _userType == 'provider'
      Navigator.of(context).pushReplacementNamed('/service_provider_dashboard');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome, ${_emailController.text}!')),
    );
  }
  // --- END NEW ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        // **FIX: Allows scrolling for overflow prevention**
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Join as a ${_userType == 'homeowner' ? 'homeowner' : 'service provider'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildUserTypeSelection(), // **User Type Selection remains here**
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'John',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Doe',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your.email@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+256 700 000 000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  errorText: _passwordError, // Pass error text
                  onChanged: (value) {
                    setState(() {
                      if (value.length < 6) {
                        _passwordError =
                            'Password must be at least 6 characters';
                      } else {
                        _passwordError = null;
                      }
                      // Re-validate confirm password if password changes
                      if (_confirmPasswordController.text.isNotEmpty &&
                          _confirmPasswordController.text != value) {
                        _confirmPasswordError = 'Passwords do not match';
                      } else {
                        _confirmPasswordError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  errorText: _confirmPasswordError, // Pass error text
                  onChanged: (value) {
                    setState(() {
                      if (value != _passwordController.text) {
                        _confirmPasswordError = 'Passwords do not match';
                      } else {
                        _confirmPasswordError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged:
                          (value) =>
                              setState(() => _agreeToTerms = value ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(color: Color(0xFF2563EB)),
                              // FIX: Correct usage of TapGestureRecognizer
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      print('T&C pressed');
                                      // Example: showDialog or Navigator.push
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildGradientButton('Create Account', () {
                  // Basic UI validation before "simulated" registration
                  bool isValid = true;
                  if (_firstNameController.text.isEmpty ||
                      _lastNameController.text.isEmpty ||
                      _emailController.text.isEmpty ||
                      _phoneController.text.isEmpty) {
                    isValid = false;
                  }
                  if (_passwordController.text.length < 6) {
                    setState(() {
                      _passwordError = 'Password must be at least 6 characters';
                    });
                    isValid = false;
                  } else {
                    setState(() {
                      _passwordError = null;
                    });
                  }
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    setState(() {
                      _confirmPasswordError = 'Passwords do not match';
                    });
                    isValid = false;
                  } else {
                    setState(() {
                      _confirmPasswordError = null;
                    });
                  }
                  if (!_agreeToTerms) {
                    isValid = false;
                  }

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill all fields, ensure passwords match and agree to terms.',
                        ),
                      ),
                    );
                    return;
                  }

                  _handleAuthSuccess(context); // Navigate to dashboard
                }),
                const Spacer(), // Pushes content to top if there's extra space
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    TextButton(
                      onPressed: () {
                        // FIX: Added 'const' before LoginPage()
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // User type selection method (moved from original AuthScreen)
  Widget _buildUserTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildUserTypeButton(
            'homeowner',
            'Homeowner',
            Icons.home,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUserTypeButton(
            'provider',
            'Service Provider',
            Icons.people,
            const Color(0xFF9333EA),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeButton(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Re-used _buildTextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }

  // Re-used _buildPasswordField (with errorText and onChanged for validation)
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !_showPassword,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
            ),
            errorText: errorText, // Display error text here
          ),
        ),
      ],
    );
  }

  // Re-used _buildGradientButton
  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
