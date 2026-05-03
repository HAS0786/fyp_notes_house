import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fyp_ui_design/firebase/services/local_notification_service.dart';
import 'package:fyp_ui_design/firebase_options.dart';
import 'package:fyp_ui_design/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_login_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/resource_list_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_screen.dart';
import 'package:fyp_ui_design/screens/splashscreen/splash_screen.dart';
import 'package:fyp_ui_design/screens/dashboard/home_screen.dart';
import 'package:fyp_ui_design/screens/login_signup/login_screen.dart';
import 'package:fyp_ui_design/screens/login_signup/sign_up/signup_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_upload/create_mcq_screen.dart';
import 'package:fyp_ui_design/screens/roles_selection/chose_role_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
  await LocalNotificationService.show(message);
}

void handleNotificationClick(RemoteMessage message) {
  final data = message.data;

  // 🔥 delay so navigator ready ho
  Future.delayed(const Duration(milliseconds: 500), () {

    if (data['type'] == 'new_quiz' && data['quizId'] != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            quizId: data['quizId'],
            quizData: [],
            isEditable: false,
            subject: '',
            department: '',
            semester: 0,
            university: '',
            campus: '',
          ),
        ),
      );
    }

    if (data['type'] == 'approved_note' && data['fileUrl'] != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => FileViewerScreen(
            fileUrl: data['fileUrl'],
            title: data['title'] ?? "Note",
          ),
        ),
      );
    }

  });
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalNotificationService.initialize();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // 🔥 ADD HERE
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleNotificationClick(message);
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleNotificationClick(message);
    }
  });


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Notes House',

      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        useMaterial3: true,
      ),

      //  Entry point
      home: const SplashScreen(),

      routes: {
        '/admin-login': (_) => const AdminLoginScreen(),
        '/admin-approve': (_) => const AdminDashboard(),
        '/choose-role': (_) => const ChooseRoleScreen(),
        '/dashboard': (_) => const HomeScreen(),
        '/create-mcq': (_) => const CreateMCQScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          final isTeacher = settings.arguments as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => LoginScreen(isTeacher: isTeacher),
          );
        }

        if (settings.name == '/signup') {
          final isTeacher = settings.arguments as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => SignupScreen(isTeacher: isTeacher),
          );
        }
        return null;
      },
    );
  }
}
