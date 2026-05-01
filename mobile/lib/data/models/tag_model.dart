class TagModel {
  const TagModel({required this.id, required this.name});

  final String id;
  final String name;

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
