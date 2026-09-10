import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {

  Future<void> _openLink(String value) async {
    final uri = Uri.parse(value);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoTile(
              Icons.email,
              'Email',
              'noteshouseapp@gmail.com',
              'mailto:noteshouseapp@gmail.com',
            ),

            _infoTile(
              Icons.phone,
              'Phone',
              '+92 300 1234567',
              'tel:+923001234567',
            ),

            _infoTile(
              Icons.web,
              'Website',
              'www.notes-house.vercel.app',
              'https://www.notes-house.vercel.app',
            ),

            const SizedBox(height: 24),


            const SizedBox(height: 16),

            ]
        ),
      ),
    );
  }

  Widget _infoTile(
      IconData icon,
      String title,
      String subtitle,
      String url,
      ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlue),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
