import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/firebase/services/auth_role_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  static Future<User?> signInWithGoogleSafe({
    required BuildContext context,
  }) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user!;
    final ref =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snap = await ref.get();

    // 🟢 FIRST TIME GOOGLE USER → ALWAYS STUDENT
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email,
        'university': '',
        'role': 'student', // 🔒 FORCE STUDENT
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 🔐 SYNC ROLE & BLOCK IF NEEDED
    await AuthRoleService.syncUserToLocal(
      user: user,
    );

    return user;
  }
}
