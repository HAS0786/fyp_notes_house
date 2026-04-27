import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/admin/admin_approve_teachers.dart';

import '../screens/dashboard/home_screen.dart';
import '../screens/dashboard/pendingapproval/pendingapprovalscreen.dart';
import '../screens/roles_selection/chose_role_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  /// 🔹 Fetch role safely
  Future<String?> _getRole(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['role'];
  }

  @override
  void initState() {
    super.initState();

    // 🔔 App opened via notification
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

        // ❌ Not logged in
        if (!authSnap.hasData) {
          return const ChooseRoleScreen();
        }

        final user = authSnap.data!;

        // ✅ Logged in → fetch role
        return FutureBuilder<String?>(
          future: _getRole(user),
          builder: (context, roleSnap) {

            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ❌ Role missing → force logout
            if (!roleSnap.hasData || roleSnap.data == null) {
              FirebaseAuth.instance.signOut();
              return const ChooseRoleScreen();
            }

            final role = roleSnap.data!;

            // 🛑 Pending teacher
            if (role == 'pending_teacher') {
              return const PendingApprovalScreen();
            }

            // 🧑‍💼 Admin dashboard
            if (role == 'admin') {
              return const AdminApproveTeachersScreen();
            }

            // 🎓 Student / Teacher
            if (role == 'student' || role == 'teacher') {
              return const HomeScreen();
            }

            // ❌ Fallback (safety)
            return const Scaffold(
              body: Center(child: Text("Invalid user role")),
            );
          },
        );
      },
    );
  }
}
