import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/auth/auth_wrapper.dart';
import 'package:fyp_ui_design/auth/google_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/firebase/services/auth_role_service.dart';
import 'package:fyp_ui_design/firebase/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isTeacher;
  const LoginScreen({super.key, required this.isTeacher});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    if (_validateEmail(email) != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to send reset email')),
      );
    }
  }

  /// Firebase login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!credential.user!.emailVerified) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );

        return;
      }

      // Sync role only (no navigation decision here)
      await AuthRoleService.syncUserToLocal(user: credential.user!);

      await NotificationService.saveToken(); // Notification
      // Let AuthWrapper react automatically
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
      setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    }
  }

  /// Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';

    // FOr only testing Purpose:
    const testTeacherEmail = 'hasnatmughal7565@gmail.com';
    if (widget.isTeacher &&
        value != testTeacherEmail &&
        !value.endsWith('.edu.pk') &&
        !value.endsWith('.edu')) {
      return 'Teacher email must end with .edu or .edu.pk';
    }
    return null;
  }

  /// Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be 8+ characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Teacher Login' : 'Student Login'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 40,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/images/logo.webp', height: 80),
                const SizedBox(height: 32),

                Text(
                  widget.isTeacher ? 'Teacher Login' : 'Welcome Champion!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isTeacher
                      ? 'Log in with your university email'
                      : 'Log in to access your notes and quizzes.',
                ),
                const SizedBox(height: 32),

                /// EMAIL
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    widget.isTeacher ? 'University Email' : 'Email',
                    widget.isTeacher ? 'name@pu.edu.pk' : 'ali@gmail.com',
                    Icons.email,
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                /// PASSWORD
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: _passwordDecoration(
                    'Password',
                    _obscurePassword,
                    () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),

                /// LOGIN BUTTON
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                if (!widget.isTeacher)
                  OutlinedButton.icon(
                    onPressed: kIsWeb
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final user =
                                await GoogleAuthService.signInWithGoogleSafe(
                                  context: context,
                                );

                            if (user == null) {
                              setState(
                                () => _isLoading = false,
                              ); //  missing before
                              return;
                            }

                            final doc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();

                            //  NEW USER → create document
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'name': user.displayName ?? '',
                                  'email': user.email ?? '',
                                  'role': 'student',
                                  'status': 'approved',
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'notificationsEnabled': true, //  ALWAYS ADD
                                }, SetOptions(merge: true));
                            await NotificationService.saveToken();
                            // sync role
                            await AuthRoleService.syncUserToLocal(user: user);
                            setState(() => _isLoading = false);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthWrapper(),
                              ),
                            );
                          },
                    icon: Image.asset('assets/images/google.png', height: 20),
                    label: const Text('Continue with Google'),
                  ),

                const SizedBox(height: 16),

                /// SIGNUP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/signup',
                          arguments: widget.isTeacher,
                        );
                      },
                      child: const Text('Sign Up'),
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

  /// REUSABLE DECORATIONS
  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.lightBlue),
      labelText: label,
      hintText: hint,

      // Borders (different)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  InputDecoration _passwordDecoration(
    String label,
    bool obscure,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      hintText: "********",
      prefixIcon: const Icon(Icons.lock, color: Colors.lightBlue),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.lightBlue,
        ),
        onPressed: toggle,
      ),
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
