import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'about_us_screen.dart';
import 'change_password_screen.dart';
import 'contact_us_screen.dart';
import 'edit_profile_screen.dart';
import '../roles_selection/chose_role_screen.dart';
import 'package:http/http.dart' as http;


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  String _name = '';
  String _email = '';
  String _university = '';
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// LOAD USER DATA
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _name = prefs.getString('user_name') ?? 'User';
      _university = prefs.getString('user_uni') ?? '';
      _imagePath = prefs.getString('profile_image');
      _email = FirebaseAuth.instance.currentUser?.email ?? '';
      _notificationsOn = prefs.getBool('notifications_on') ?? true;
    });
  }

  Future<void> updateNotificationStatus(bool isOn) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse("$baseUrl/update-notification"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "notificationsEnabled": isOn,
      }),
    );

    print("STATUS UPDATE RESPONSE: ${response.body}");
  }
  /// PICK PROFILE IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', image.path);

      setState(() {
        _imagePath = image.path;
      });
    }
  }

  /// LOGOUT
  Future<void> _logout() async {
    // 🔥 CLEAR LOCAL CACHE
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 🔐 SIGN OUT FROM FIREBASE
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
          (_) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(

        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Profile Image
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _imagePath != null
                      ? FileImage(File(_imagePath!))
                      : const AssetImage('assets/images/user.png')
                  as ImageProvider,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (_university.isNotEmpty)
              Text(_university, style: const TextStyle(color: Colors.grey)),

            Text(_email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            _tile(Icons.person, 'Edit Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            }),

            _tile(Icons.lock, 'Change Password', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            }),

            Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.lightBlue,
                    size: 28,
                  ),
                ),

                title: const Text('Notifications'),

                // 🔥 YAHAN ARROW KI JAGAH SWITCH
                trailing: Switch(
                  value: _notificationsOn,
                  // hoverColor: Colors.lightBlue,
                  activeThumbColor: Colors.lightBlue,
                  onChanged: (v) async {
                    setState(() => _notificationsOn = v);

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_on', v);

                    await updateNotificationStatus(v);
                  },
                ),
              ),
            ),
            _tile(Icons.info, 'About Us', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
              );
            }),

            _tile(Icons.support_agent, 'Help & Support', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            }),

            _tile(
              Icons.logout,
              'Log Out',
              _logout,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color? color,
      }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,

        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.lightBlue,
            size: 28,
          ),
        ),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
