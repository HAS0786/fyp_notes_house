
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/auth/auth_wrapper.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _resending = false;
  bool _checking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Automatically check periodically while screen is open.
    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Check again when user comes back from email/browser.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification();
    }
  }

  Future<void> _checkVerification() async {
    if (_checking) return;

    _checking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _timer?.cancel();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthWrapper(),
          ),
              (route) => false,
        );
      }
    } catch (_) {
      // Ignore temporary checking errors.
    } finally {
      _checking = false;
    }
  }

  Future<void> _resendEmail() async {
    if (_resending) return;

    setState(() => _resending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await user.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent. Please check your inbox.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to send verification email.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  Future<void> _useAnotherAccount() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/choose-role',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 35),

              Image.asset(
                'assets/images/logo.webp',
                height: 80,
              ),

              const SizedBox(height: 30),

              const Icon(
                Icons.mark_email_unread_outlined,
                size: 70,
                color: Colors.lightBlue,
              ),

              const SizedBox(height: 22),

              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'We sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightBlue,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Please check your inbox and click the verification link. '
                    'After verifying, return to Notes House and we will '
                    'continue automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Didn’t receive the email? Check your Spam or Promotions folder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 30),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.lightBlue,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Waiting for verification...',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resending ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ),
                    side: const BorderSide(
                      color: Colors.lightBlue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _resending
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Resend Verification Email',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _useAnotherAccount,
                child: const Text(
                  'Use Another Account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}