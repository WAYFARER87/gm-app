import 'video_item.dart';

class VideoPage {
  final List<VideoItem> items;
  final int page;
  final int pages;
  final int total;

  VideoPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });
}
