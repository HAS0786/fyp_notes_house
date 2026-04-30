// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// class StudentDetailsScreen extends StatefulWidget {
//   const StudentDetailsScreen({super.key});
//
//   @override
//   State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
// }
//
// class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
//
//   String? university;
//   String? department;
//   int? semester;
//
//   final TextEditingController customUniversityCtrl = TextEditingController();
//   final TextEditingController customDepartmentCtrl = TextEditingController();
//
//   bool isLoading = false;
//   bool loadingData = true;
//
//   List<String> universities = [];
//   List<String> departments = [];
//
//   final semesters = List.generate(8, (index) => index + 1);
//
//   /// 🔹 Normalize
//   String normalize(String text) {
//     return text.toLowerCase().trim();
//   }
//
//   /// 🔥 LOAD FROM FIRESTORE (REAL DATA)
//   Future<void> loadData() async {
//     final notesSnap =
//     await FirebaseFirestore.instance.collection('notes').get();
//
//     final uniSet = <String>{};
//     final depSet = <String>{};
//
//     for (var doc in notesSnap.docs) {
//       final data = doc.data();
//
//       if (data['university'] != null) {
//         uniSet.add(data['university']);
//       }
//       if (data['department'] != null) {
//         depSet.add(data['department']);
//       }
//     }
//
//     universities = uniSet.toList();
//     departments = depSet.toList();
//
//     universities.add("Other");
//     departments.add("Other");
//
//     setState(() => loadingData = false);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }
//
//   Future<void> saveDetails() async {
//
//     if (university == null || department == null || semester == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all fields")),
//       );
//       return;
//     }
//
//     if (university == "Other" && customUniversityCtrl.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter your university")),
//       );
//       return;
//     }
//
//     if (department == "Other" && customDepartmentCtrl.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter your department")),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//
//     String finalUniversity =
//     university == "Other" ? customUniversityCtrl.text : university!;
//
//     String finalDepartment =
//     department == "Other" ? customDepartmentCtrl.text : department!;
//
//     await FirebaseFirestore.instance.collection('users').doc(uid).update({
//       "university": normalize(finalUniversity),
//       "department": normalize(finalDepartment),
//       "semester": semester,
//     });
//
//     if (!mounted) return;
//
//     Navigator.pushReplacementNamed(context, '/dashboard');
//   }
//
//   @override
//   void dispose() {
//     customUniversityCtrl.dispose();
//     customDepartmentCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     if (loadingData) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FC),
//       appBar: AppBar(
//         title: const Text("Academic Details"),
//         backgroundColor: Colors.lightBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//
//             /// UNIVERSITY
//             DropdownButtonFormField<String>(
//               value: university,
//               decoration: const InputDecoration(
//                 labelText: "University",
//                 border: OutlineInputBorder(),
//               ),
//               items: universities.map((u) {
//                 return DropdownMenuItem(value: u, child: Text(u));
//               }).toList(),
//               onChanged: (val) => setState(() => university = val),
//             ),
//
//             if (university == "Other") ...[
//               const SizedBox(height: 12),
//               TextField(
//                 controller: customUniversityCtrl,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your university",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             /// DEPARTMENT
//             DropdownButtonFormField<String>(
//               value: department,
//               decoration: const InputDecoration(
//                 labelText: "Department",
//                 border: OutlineInputBorder(),
//               ),
//               items: departments.map((d) {
//                 return DropdownMenuItem(value: d, child: Text(d));
//               }).toList(),
//               onChanged: (val) => setState(() => department = val),
//             ),
//
//             if (department == "Other") ...[
//               const SizedBox(height: 12),
//               TextField(
//                 controller: customDepartmentCtrl,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your department",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             /// SEMESTER
//             DropdownButtonFormField<int>(
//               value: semester,
//               decoration: const InputDecoration(
//                 labelText: "Semester",
//                 border: OutlineInputBorder(),
//               ),
//               items: semesters.map((s) {
//                 return DropdownMenuItem(value: s, child: Text("Semester $s"));
//               }).toList(),
//               onChanged: (val) => setState(() => semester = val),
//             ),
//
//             const SizedBox(height: 30),
//
//             ElevatedButton(
//               onPressed: isLoading ? null : saveDetails,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.lightBlue,
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//               child: isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Save & Continue"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }