class NoteModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String fileUrl;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.fileUrl,
  });

  factory NoteModel.fromFirestore(String id, Map<String, dynamic> data) {
    return NoteModel(
      id: id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      fileUrl: data['fileUrl'],
    );
  }
}
