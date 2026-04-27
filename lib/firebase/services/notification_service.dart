import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//
// class NotificationService {
//   static Future<void> saveToken() async {
//     await FirebaseMessaging.instance.requestPermission();
//
//     //  Get fresh Android token
//     final token = await FirebaseMessaging.instance.getToken();
//
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user != null && token != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .update({'fcmToken': token});
//     }
//
//     print("FCM TOKEN (ANDROID): $token");
//   }
//
// }
class NotificationService {
  static Future<void> saveToken() async {
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }

    print(" FCM TOKEN SAVED: $token");
  }
}
