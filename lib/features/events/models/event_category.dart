class EventCategory {
  final String id;
  final String name;
  final String description;
  final String image;

  EventCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id']?.toString() ?? json['feed_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description:
          (json['description'] ?? json['about'] ?? json['summary'] ?? '')
              .toString(),
      image: (json['image'] ?? json['image_url'] ?? json['cover'] ?? '')
          .toString(),
    );
  }
}
