class CourseModel {
  final String id;
  final String name;

  CourseModel({required this.id, required this.name});

  factory CourseModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
