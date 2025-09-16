import 'news_rubric.dart';

class NewsCategory {
  final String id;
  final String name;
  final List<NewsRubric> rubrics;

  NewsCategory({
    required this.id,
    required this.name,
    required this.rubrics,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    final rubrics = <NewsRubric>[];
    final rawRubrics = json['rubrics'];
    if (rawRubrics is List) {
      for (final r in rawRubrics) {
        if (r is Map<String, dynamic>) {
          rubrics.add(NewsRubric.fromJson(r));
        }
      }
    }
    return NewsCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rubrics: rubrics,
    );
  }
}
