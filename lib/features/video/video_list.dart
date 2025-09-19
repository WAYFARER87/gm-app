import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/services/video_api_service.dart';
import '../../core/utils/html_utils.dart';
import '../../core/utils/time_ago.dart';
import '../news/widgets/news_list_item_skeleton.dart';
import 'models/video_item.dart';
import 'video_detail_screen.dart';

class VideoList extends StatefulWidget {
  const VideoList({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  final _api = VideoApiService();
  final _scrollController = ScrollController();
  final List<VideoItem> _items = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _pages = 1;
      _error = null;
    });
    await _loadMore();
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
        categoryId: widget.categoryId,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page + 1;
        _pages = page.pages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки';
      });
    } finally {
      if (!mounted) {
        _isLoading = false;
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_isLoading) {
        return ListView.separated(
          itemCount: 5,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, __) => const NewsListItemSkeleton(),
        );
      }
      if (_error != null) {
        return Center(
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
        );
      }
    }

    final showBottom = _isLoading || _error != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: _items.length + (showBottom ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index >= _items.length - 1) {
            return const SizedBox.shrink();
          }
          return const Divider(height: 0);
        },
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (_isLoading) {
              return const NewsListItemSkeleton();
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Ошибка'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadMore,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
          }
          final item = _items[index];
          return VideoListItem(
            item: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoDetailScreen(
                    initialItems: _items,
                    initialIndex: index,
                    categoryId: widget.categoryId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoListItem extends StatelessWidget {
  const VideoListItem({super.key, required this.item, this.onTap});

  final VideoItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width * 0.6;
    final previewPlain = htmlToPlainText(item.contentPreview);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.image.isNotEmpty)
            Hero(
              tag: item.id,
              child: CachedNetworkImage(
                imageUrl: item.image,
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: imageHeight,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  height: imageHeight,
                  color: Colors.grey.shade200,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: imageHeight,
              color: Colors.grey.shade200,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.rubric != null && item.rubric!.name.isNotEmpty)
                  Text(
                    item.rubric!.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                  ),
                ),
                if (previewPlain.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      previewPlain,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    [
                      if (item.published != null) timeAgo(item.published),
                      if (item.author.trim().isNotEmpty) item.author,
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
