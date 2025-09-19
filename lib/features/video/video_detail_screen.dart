import 'package:flutter/material.dart';

import '../../core/services/video_api_service.dart';
import 'models/video_item.dart';
import 'video_article_view.dart';

class VideoDetailScreen extends StatefulWidget {
  const VideoDetailScreen({
    super.key,
    required this.initialItems,
    required this.initialIndex,
    this.categoryId,
  });

  final List<VideoItem> initialItems;
  final int initialIndex;
  final String? categoryId;

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final _api = VideoApiService();
  late List<VideoItem> _items;
  late int _currentIndex;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pages = 1;
  late PageController _pageController;
  late final String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
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
      final page = await _api.fetchVideos(
        page: _page,
        categoryId: _categoryId,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page + 1;
        _pages = page.pages;
      });
    } catch (e) {
      if (e.toString().contains('No video items')) {
        _pages = _page - 1;
      } else {
        if (!mounted) return;
        setState(() => _error = 'Ошибка загрузки');
      }
    } finally {
      if (!mounted) {
        _isLoading = false;
        return;
      }
      setState(() => _isLoading = false);
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
            itemBuilder: (context, index) => VideoArticleView(
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
