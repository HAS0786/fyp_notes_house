import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_ui_design/screens/roles_selection/student_details_screen.dart';

import '../screens/dashboard/home_screen.dart';
import '../screens/dashboard/pendingapproval/pendingapprovalscreen.dart';
import '../screens/roles_selection/chose_role_screen.dart';
import 'email_verification_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  /// 🔹 Fetch role safely
  Future<Map<String, dynamic>?> _getUserData(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  void initState() {
    super.initState();

    /// 🔔 FOREGROUND NOTIFICATION (THIS IS MISSING)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Notification';
      final body = message.data['body'] ?? '';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title\n$body"),
          duration: const Duration(seconds: 3),
        ),
      );
    });

    /// 🔔 CLICK NOTIFICATION
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {

        // ⏳ Checking auth
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //  Not logged in
        if (!authSnap.hasData) {
          return const ChooseRoleScreen();
        }

        final user = authSnap.data!;

        // Email verification check
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        //  Logged in → fetch role
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(user),
          builder: (context, roleSnap) {

            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Role missing → force logout
            if (!roleSnap.hasData || roleSnap.data == null) {
              FirebaseAuth.instance.signOut();
              return const ChooseRoleScreen();
            }

            final data = roleSnap.data!;
            final role = data['role'];
            final status = data['status'];

            /// Pending teacher
            if (role == 'teacher' && status == 'pending') {
              return const PendingApprovalScreen();
            }

            //  Admin dashboard
            if (role == 'admin') {
              return const AdminDashboard();
            }

            // Student / Teacher
            if (role == 'student' || role == 'teacher') {
              return const HomeScreen();
            }

            // Fallback (safety)
            return const Scaffold(
              body: Center(child: Text("Invalid user role")),
            );
          },
        );
      },
    );
  }
}
