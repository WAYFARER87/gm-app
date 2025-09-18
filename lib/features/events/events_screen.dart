import 'package:flutter/material.dart';

import '../../core/services/events_api_service.dart';
import 'events_list.dart';
import 'models/event_category.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    this.apiService,
    this.storageKeyPrefix = 'events',
  });

  final EventsApiService? apiService;
  final String storageKeyPrefix;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late EventsApiService _api;
  List<EventCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? EventsApiService();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant EventsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiService != widget.apiService) {
      _api = widget.apiService ?? EventsApiService();
      _loadCategories();
    }
  }

  void _handleTabChanged() {
    final controller = _tabController;
    if (controller == null) return;
    if (!controller.indexIsChanging && _selectedIndex != controller.index) {
      setState(() => _selectedIndex = controller.index);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cats = await _api.fetchFeeds();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedIndex = _selectedIndex.clamp(0, cats.length);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Ошибка загрузки');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Нет данных'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final initialIndex = _selectedIndex.clamp(0, _categories.length);
    final categoryNames = {
      for (final cat in _categories) cat.id: cat.name,
    };
    final prefix = widget.storageKeyPrefix;

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
                  const Tab(text: 'Все события'),
                  for (final cat in _categories) Tab(text: cat.name),
                ],
                onTap: (index) {
                  if (_selectedIndex != index) {
                    setState(() => _selectedIndex = index);
                  }
                },
              );
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                EventsList(
                  key: PageStorageKey('$prefix-all'),
                  categoryNames: categoryNames,
                  apiService: _api,
                ),
                for (final cat in _categories)
                  EventsList(
                    key: PageStorageKey('$prefix-${cat.id}'),
                    categoryId: cat.id,
                    categoryNames: categoryNames,
                    apiService: _api,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
