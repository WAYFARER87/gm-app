import 'package:flutter/material.dart';

import '../../core/services/video_api_service.dart';
import 'models/video_category.dart';
import 'video_list.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _api = VideoApiService();
  List<VideoCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  TabController? _tabController;

  void _handleTabChanged() {
    final controller = _tabController;
    if (controller == null) return;
    if (!controller.indexIsChanging && _selectedIndex != controller.index) {
      setState(() {
        _selectedIndex = controller.index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cats = await _api.fetchFeeds();
      final validCats = cats.where((cat) => cat.id.isNotEmpty).toList();
      if (mounted) {
        setState(() {
          _categories = validCats;
          _selectedIndex = _selectedIndex.clamp(0, validCats.length);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Ошибка загрузки');
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
  void dispose() {
    _tabController?.removeListener(_handleTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Center(
        child: Text(_error ?? 'Нет данных'),
      );
    }

    final initialIndex = _selectedIndex.clamp(0, _categories.length);

    return DefaultTabController(
      length: _categories.length + 1,
      initialIndex: initialIndex,
      child: Column(
        children: [
          Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context);
              if (_tabController != controller) {
                _tabController?.removeListener(_handleTabChanged);
                _tabController = controller;
                _tabController?.addListener(_handleTabChanged);
              }
              if (controller != null && controller.index != initialIndex) {
                controller.index = initialIndex;
              }
              return TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  const Tab(text: 'Все видео'),
                  for (final cat in _categories) Tab(text: cat.name),
                ],
                onTap: (index) {
                  if (_selectedIndex != index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                },
              );
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                const VideoList(
                  key: PageStorageKey('videos-all'),
                ),
                for (final cat in _categories)
                  VideoList(
                    key: PageStorageKey('videos-${cat.id}'),
                    categoryId: cat.id,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
