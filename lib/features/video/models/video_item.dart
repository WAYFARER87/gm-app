import 'video_rubric.dart';

class VideoItem {
  final String id;
  final String title;
  final String contentPreview;
  final String contentFull;
  final String image;
  final String url;
  final String author;
  final DateTime? published;
  final VideoRubric? rubric;
  final String videoFrame;

  VideoItem({
    required this.id,
    required this.title,
    required this.contentPreview,
    required this.contentFull,
    required this.image,
    required this.url,
    required this.author,
    required this.videoFrame,
    this.published,
    this.rubric,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    VideoRubric? rubric;
    final r = json['rubric'];
    if (r is Map<String, dynamic>) {
      rubric = VideoRubric.fromJson(r);
    }

    DateTime? published;
    final p = json['published'] ?? json['published_at'] ?? json['date'];
    if (p != null) {
      published = DateTime.tryParse(p.toString());
    }

    return VideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      contentPreview:
          (json['content_preview'] ?? json['preview'] ?? json['introtext'] ?? json['short_content'] ?? '')
              .toString(),
      contentFull:
          (json['content_full'] ?? json['content'] ?? json['fulltext'] ?? json['full_text'] ?? '').toString(),
      image: (json['image'] ?? json['image_url'] ?? json['photo_url'] ?? '').toString(),
      url: (json['url'] ?? json['link'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      videoFrame: (json['video_frame'] ?? json['videoFrame'] ?? '').toString(),
      published: published,
      rubric: rubric,
    );
  }
}
