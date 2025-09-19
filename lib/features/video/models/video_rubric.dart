class VideoRubric {
  final String id;
  final String name;
  final String slug;

  VideoRubric({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory VideoRubric.fromJson(Map<String, dynamic> json) {
    return VideoRubric(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
