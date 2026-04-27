

class UniversityModel {
  final String id;
  final String name;
  final String location;

  UniversityModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory UniversityModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UniversityModel(
      id: id,
      name: data['name'],
      location: data['location'] ?? '',
    );
  }
}
