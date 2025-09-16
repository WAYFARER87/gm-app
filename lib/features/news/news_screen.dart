import 'package:flutter/material.dart';

import '../../core/services/news_api_service.dart';
import 'models/news_category.dart';
import 'news_category_screen.dart';
import 'news_list.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _api = NewsApiService();
  List<NewsCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

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
      if (mounted) {
        setState(() => _categories = cats);
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Center(
        child: Text(_error ?? 'Нет данных'),
      );
    }

    return DefaultTabController(
      length: _categories.length + 1,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Все новости'),
              for (final cat in _categories) Tab(text: cat.name),
            ],
            onTap: (index) {
              if (index == 0) return;
              final category = _categories[index - 1];
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewsCategoryScreen(category: category),
                ),
              );
            },
          ),
          const Expanded(
            child: NewsList(),
          ),
        ],
      ),
    );
  }
}

