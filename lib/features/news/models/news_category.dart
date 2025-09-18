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
      id: _extractCategoryId(json) ?? '',
      name: json['name']?.toString() ?? '',
      rubrics: rubrics,
    );
  }
}

String? _extractCategoryId(Map<String, dynamic> json) {
  final primaryId = _extractFirstString(json, const ['id']);
  if (primaryId != null) {
    return primaryId;
  }

  final feedId = _extractFirstString(
    json,
    const ['feed_id', 'feedId', 'feedID', 'feed-id', 'feedid'],
  );
  if (feedId != null) {
    return feedId;
  }

  for (final entry in json.entries) {
    final normalizedKey = _normalizeKey(entry.key.toString());
    if (normalizedKey == 'id' || normalizedKey == 'feedid') {
      final valueStr = _valueToString(entry.value);
      if (valueStr != null) {
        return valueStr;
      }
    }
  }

  return null;
}

String? _extractFirstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final valueStr = _valueToString(json[key]);
    if (valueStr != null) {
      return valueStr;
    }
  }

  final normalizedKeys = keys.map(_normalizeKey).toSet();
  for (final entry in json.entries) {
    final normalizedKey = _normalizeKey(entry.key.toString());
    if (normalizedKeys.contains(normalizedKey)) {
      final valueStr = _valueToString(entry.value);
      if (valueStr != null) {
        return valueStr;
      }
    }
  }

  return null;
}

String _normalizeKey(String key) {
  return key.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
}

String? _valueToString(dynamic value) {
  if (value == null) {
    return null;
  }
  final str = value.toString();
  if (str.isEmpty) {
    return null;
  }
  return str;
}
