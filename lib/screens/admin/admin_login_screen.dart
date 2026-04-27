import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool hidePass = true;

  Future<void> loginAdmin() async {
    setState(() => loading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists || doc.data()?['role'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw 'This is not an admin account';
      }

      Navigator.pushReplacementNamed(context, '/admin-approve');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: Text("Admin Login"),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF7F8FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 80, color: Colors.blue),

              const SizedBox(height: 16),

              const Text(
                "Welcome Admin!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Login to manage teachers & content",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Admin Email",
                  prefixIcon: Icon(Icons.email,color: Colors.lightBlue,),
                  border: OutlineInputBorder(),
                  ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passCtrl,
                obscureText: hidePass,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock,color: Colors.lightBlue,),
                  suffixIcon: IconButton(
                    icon: Icon(
                        hidePass ? Icons.visibility_off : Icons.visibility,color: Colors.lightBlue,),
                    onPressed: () =>
                        setState(() => hidePass = !hidePass),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white
                  ),
                  onPressed: loading ? null : loginAdmin,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login as Admin"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
