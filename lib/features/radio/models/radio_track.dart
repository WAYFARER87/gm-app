class RadioTrack {
  final String artist;
  final String title;
  final String image;

  RadioTrack({
    required this.artist,
    required this.title,
    required this.image,
  });

  factory RadioTrack.fromJson(Map<String, dynamic> json) {
    return RadioTrack(
      artist: (json['artist'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      image: (json['image'] ?? json['cover'] ?? json['image_url'] ?? '').toString(),
    );
  }
}
