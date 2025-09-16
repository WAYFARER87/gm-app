import 'package:flutter/material.dart';

import '../../core/services/news_api_service.dart';
import 'models/news_item.dart';
import 'news_article_view.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.initialItems,
    required this.initialIndex,
  });

  final List<NewsItem> initialItems;
  final int initialIndex;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _api = NewsApiService();
  late List<NewsItem> _items;
  late int _currentIndex;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pages = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _page = (_items.length / 20).ceil() + 1;
    _pages = _page;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (index >= _items.length - 2) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _page > _pages) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _api.fetchNews(page: _page);
      setState(() {
        _items.addAll(page.items);
        _page = page.page + 1;
        _pages = page.pages;
      });
    } catch (e) {
      if (e.toString().contains('No news items')) {
        _pages = _page - 1;
      } else {
        if (mounted) setState(() => _error = 'Ошибка загрузки');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            pageSnapping: true,
            itemBuilder: (context, index) => NewsArticleView(
              key: ValueKey(_items[index].id),
              item: _items[index],
            ),
          ),
          if (_isLoading)
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadMore,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

