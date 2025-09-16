import 'news_item.dart';

class NewsPage {
  final List<NewsItem> items;
  final int page;
  final int pages;
  final int total;

  NewsPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });
}

