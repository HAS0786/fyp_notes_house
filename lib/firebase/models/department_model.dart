class DepartmentModel {
  final String id;
  final String name;

  DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return DepartmentModel(
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
