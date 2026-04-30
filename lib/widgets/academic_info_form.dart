import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicSelection {
  String? university;
  String? location;
  String? department;
  String? subject;
  String? semester;

  AcademicSelection({
    this.university,
    this.location,
    this.department,
    this.subject,
    this.semester,
  });
}

class AcademicInfoForm extends StatefulWidget {
  final AcademicSelection value;
  final Function(AcademicSelection) onChanged;

  const AcademicInfoForm({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AcademicInfoForm> createState() => _AcademicInfoFormState();
}

class _AcademicInfoFormState extends State<AcademicInfoForm> {
  late AcademicSelection data;
  final locationCtrl = TextEditingController();

  final List<String> semesters =
  List.generate(8, (i) => 'Semester ${i + 1}');

  @override
  void initState() {
    super.initState();
    data = widget.value;
    locationCtrl.text = data.location ?? "";
  }

  // ================= NORMALIZE =================
  String normalize(String input) {
    input = input.trim();
    if (input.isEmpty) return "";
    return input
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }

  void update(VoidCallback fn) {
    setState(fn);
    widget.onChanged(data);
  }

  // ================= STREAMS =================

  Stream<List<String>> universitiesStream() {
    return FirebaseFirestore.instance
        .collection('universities')
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toSet().toList());
  }

  Stream<List<String>> locationsStream() {
    if (data.university == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('universities')
        .where('name', isEqualTo: data.university)
        .snapshots()
        .map((snapshot) {
      final set = <String>{};

      for (var doc in snapshot.docs) {
        final loc = doc['location'];

        if (loc is List) {
          set.addAll(loc.map((e) => e.toString().trim()));
        } else if (loc is String && loc.isNotEmpty) {
          set.add(loc.trim()); // backward compatibility
        }
      }

      return set.toList();
    });
  }

  Stream<List<String>> departmentsStream() {
    if (data.university == null || locationCtrl.text.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('departments')
        .where('university', isEqualTo: data.university)
        .where('location', isEqualTo: locationCtrl.text.trim())
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toList());
  }

  Stream<List<String>> subjectsStream() {
    if (data.department == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('courses')
        .where('department', isEqualTo: data.department)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toSet().toList());
  }

  // ================= ADD NEW =================

  Future<void> addNew(String type) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add $type"),

        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final text = normalize(controller.text);
              if (text.isEmpty) return;

              final db = FirebaseFirestore.instance;

              if (type == 'University') {
                await db.collection('universities')
                    .doc(text.toLowerCase())
                    .set({
                  'name': text,
                  'location': [],
                }, SetOptions(merge: true));

                update(() {
                  data.university = text;
                  locationCtrl.clear();
                  data.department = null;
                  data.subject = null;
                });
              }

              if (type == 'Location') {
                if (data.university == null) return;

                await db.collection('universities')
                    .doc(data.university!.toLowerCase())
                    .set({
                  'location': FieldValue.arrayUnion([text]),
                }, SetOptions(merge: true));

                update(() {
                  locationCtrl.text = text;
                  data.location = text;
                  data.department = null;
                  data.subject = null;
                });
              }

              if (type == 'Department') {
                if (data.university == null ||
                    locationCtrl.text.isEmpty) return;

                final id =
                '${data.university}_${locationCtrl.text}_$text'
                    .toLowerCase();

                await db.collection('departments').doc(id).set({
                  'name': text,
                  'university': data.university,
                  'location': locationCtrl.text,
                });

                update(() {
                  data.department = text;
                  data.subject = null;
                });
              }

              if (type == 'Subject') {
                if (data.department == null) return;

                final id = '${data.department}_$text'.toLowerCase();

                await db.collection('courses').doc(id).set({
                  'name': text,
                  'department': data.department,
                });

                update(() {
                  data.subject = text;
                });
              }

              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// UNIVERSITY
        StreamBuilder<List<String>>(
          stream: universitiesStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: data.university,
                    items: snap.data!
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => update(() {
                      data.university = v;
                      locationCtrl.clear();
                      data.department = null;
                      data.subject = null;
                    }),
                    decoration:
                    const InputDecoration(labelText: "University"),
                  ),
                ),
                IconButton(
                    onPressed: () => addNew("University"),
                    icon: const Icon(Icons.add_circle)),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        /// LOCATION
        StreamBuilder<List<String>>(
          stream: locationsStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: snap.data!.contains(locationCtrl.text)
                        ? locationCtrl.text
                        : null,
                    items: snap.data!
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => update(() {
                      locationCtrl.text = v!;
                      data.location = v;
                      data.department = null;
                      data.subject = null;
                    }),
                    decoration:
                    const InputDecoration(labelText: "Location"),
                  ),
                ),
                IconButton(
                    onPressed: () => addNew("Location"),
                    icon: const Icon(Icons.add_circle)),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        /// DEPARTMENT
        StreamBuilder<List<String>>(
          stream: departmentsStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: data.department,
                    items: snap.data!
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => update(() {
                      data.department = v;
                      data.subject = null;
                    }),
                    decoration:
                    const InputDecoration(labelText: "Department"),
                  ),
                ),
                IconButton(
                    onPressed: () => addNew("Department"),
                    icon: const Icon(Icons.add_circle)),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        /// SUBJECT
        StreamBuilder<List<String>>(
          stream: subjectsStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: data.subject,
                    items: snap.data!
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        update(() => data.subject = v),
                    decoration:
                    const InputDecoration(labelText: "Subject"),
                  ),
                ),
                IconButton(
                    onPressed: () => addNew("Subject"),
                    icon: const Icon(Icons.add_circle)),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        /// SEMESTER
        DropdownButtonFormField(
          value: data.semester,
          items: semesters
              .map((e) =>
              DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) =>
              update(() => data.semester = v),
          decoration: const InputDecoration(labelText: "Semester"),
        ),
      ],
    );
  }
}