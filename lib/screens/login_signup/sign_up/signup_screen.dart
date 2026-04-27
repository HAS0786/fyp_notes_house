  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:fyp_ui_design/firebase/services/auth_role_service.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:fyp_ui_design/auth/google_auth_service.dart';
  import 'package:flutter/foundation.dart';



  class SignupScreen extends StatefulWidget {
    final bool isTeacher;
    const SignupScreen({super.key, required this.isTeacher});

    @override
    State<SignupScreen> createState() => _SignupScreenState();
  }

  class _SignupScreenState extends State<SignupScreen> {
    final _formKey = GlobalKey<FormState>();
    final _nameCtrl = TextEditingController();
    final _emailCtrl = TextEditingController();
    final _universityCtrl = TextEditingController();
    final _passCtrl = TextEditingController();
    final _confirmPassCtrl = TextEditingController();

    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;

    /// CREATE USER + SAVE DATA
    Future<void> _signup() async {
      if (!_formKey.currentState!.validate()) return;

      try {
        /// CREATE AUTH USER
        final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        final uid = userCredential.user!.uid;

        /// STORE USER DATA IN FIRESTORE
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'university': _universityCtrl.text.trim(),
          // 'role': widget.isTeacher ? 'teacher' : 'student',
          'role': widget.isTeacher ? 'pending_teacher' : 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // CACHE ROLE (IMPORTANT)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_role',
          widget.isTeacher ? 'pending_teacher' : 'student',
        );



        /// NAVIGATION → AUTH WRAPPER WILL HANDLE NEXT
        Navigator.pushReplacementNamed(context, '/login',
            arguments: widget.isTeacher);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Signup failed')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    }

    /// VALIDATIONS
    String? _validateName(String? value) {
      if (value == null || value.isEmpty) return 'Name is required';
      if (value.length < 3) return 'Name too short';
      return null;
    }

    String? _validateEmail(String? value) {
      if (value == null || value.isEmpty) return 'Email is required';

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) return 'Enter a valid email';

      if (widget.isTeacher &&
          !value.endsWith('.edu.pk') &&
          !value.endsWith('.edu')) {
        return 'Teacher email must end with .edu or .edu.pk';
      }
      return null;
    }

    String? _validatePassword(String? value) {
      if (value == null || value.isEmpty) return 'Password is required';
      if (value.length < 8) return 'Password must be 8+ characters';
      return null;
    }

    String? _validateConfirmPassword(String? value) {
      if (value != _passCtrl.text) return 'Passwords do not match';
      return null;
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isTeacher ? 'Teacher Signup' : 'Student Signup'),
          backgroundColor:  Colors.lightBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// NAME
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration(
                    'Full Name',
                    'Ali Ahmed',
                    Icons.person,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                /// UNIVERSITY
                TextFormField(
                  controller: _universityCtrl,
                  decoration: _inputDecoration(
                    'University',
                    'Punjab University',
                    Icons.school,
                  ),
                ),
                const SizedBox(height: 16),

                /// EMAIL
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    widget.isTeacher ? 'University Email' : 'Email',
                    widget.isTeacher
                        ? 'name@pu.edu.pk'
                        : 'ali@gmail.com',
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
                const SizedBox(height: 16),

                /// CONFIRM PASSWORD
                TextFormField(

                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPassword,
                  decoration: _passwordDecoration(
                    'Confirm Password',
                    _obscureConfirmPassword,
                        () => setState(() {
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                    }),
                  ),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 30),

                /// SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      widget.isTeacher
                          ? 'Request Access'
                          : 'Create Account',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// GOOGLE LOGIN (STUDENT ONLY)
                if (!widget.isTeacher)
                  OutlinedButton.icon(
                    onPressed: kIsWeb ? null : () async {
                      final user =
                      await GoogleAuthService.signInWithGoogleSafe(
                        context: context,
                      );
                      if (user == null) return;
                      Navigator.pushReplacementNamed(
                          context, '/dashboard');
                    },
                    icon: Image.asset(
                      'assets/images/google.png',
                      height: 20,
                    ),
                    label: const Text('Continue with Google'),
                  ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/login',
                          arguments: widget.isTeacher,
                        );
                      },
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }


    /// REUSABLE DECORATIONS
    InputDecoration _inputDecoration(
        String label, String hint, IconData icon) {
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
        String label, bool obscure, VoidCallback toggle) {
      return InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.lightBlue),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,color: Colors.lightBlue,),
          onPressed: toggle,
        ),
        labelText: label,
        hintText: "********",
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
      _nameCtrl.dispose();
      _emailCtrl.dispose();
      _universityCtrl.dispose();
      _passCtrl.dispose();
      _confirmPassCtrl.dispose();
      super.dispose();
    }
  }
