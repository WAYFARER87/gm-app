class NewsRubric {
  final String id;
  final String name;
  final String slug;

  NewsRubric({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory NewsRubric.fromJson(Map<String, dynamic> json) {
    return NewsRubric(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
