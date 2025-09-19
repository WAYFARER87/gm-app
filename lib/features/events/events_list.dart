import 'package:flutter/material.dart';

import '../../core/services/events_api_service.dart';
import 'events_detail_screen.dart';
import 'models/event_item.dart';
import 'widgets/event_list_item_skeleton.dart';
import 'utils/event_date_formatter.dart';

class EventsList extends StatefulWidget {
  const EventsList({
    super.key,
    this.categoryId,
    this.categoryNames = const {},
    this.apiService,
  });

  final String? categoryId;
  final Map<String, String> categoryNames;
  final EventsApiService? apiService;

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  late EventsApiService _api;
  final _scrollController = ScrollController();
  final List<EventItem> _items = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? EventsApiService();
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
      final page = await _api.fetchEvents(
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
  void didUpdateWidget(covariant EventsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiService != widget.apiService) {
      _api = widget.apiService ?? EventsApiService();
      _refresh();
      return;
    }
    if (oldWidget.categoryId != widget.categoryId) {
      _refresh();
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
          separatorBuilder: (_, __) =>
              const Divider(height: 0, indent: 16, endIndent: 16),
          itemBuilder: (_, __) => const EventListItemSkeleton(),
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
      return const Center(child: Text('Нет данных'));
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
          return const Divider(height: 0, indent: 16, endIndent: 16);
        },
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (_isLoading) {
              return const EventListItemSkeleton();
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
          return EventListItem(
            item: item,
            eventCategoryName: item.categoryName,
            categoryName: widget.categoryNames[item.feedId],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(item: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EventListItem extends StatelessWidget {
  const EventListItem({
    super.key,
    required this.item,
    this.onTap,
    this.categoryName,
    this.eventCategoryName,
  });

  final EventItem item;
  final VoidCallback? onTap;
  final String? categoryName;
  final String? eventCategoryName;

  @override
  Widget build(BuildContext context) {
    final date = formatEventDateRange(item.startDate, item.endDate);
    final fallbackDate = item.fallbackDateText;
    final theme = Theme.of(context);
    const posterWidth = 120.0;
    const posterAspectRatio = 3 / 4;
    final posterHeight = posterWidth / posterAspectRatio;
    final colorScheme = theme.colorScheme;
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.2,
    );
    final baseInfoStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontSize: 14,
      color: colorScheme.onSurface.withOpacity(0.75),
      height: 1.4,
    );
    final labelStyle = baseInfoStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final placeParts = [
      if (item.venueName.isNotEmpty) item.venueName,
      if (item.venueAddress.isNotEmpty) item.venueAddress,
    ];
    final placeText =
        placeParts.isNotEmpty ? placeParts.join(', ') : 'Не указано';
    final categoryCandidates = <String>[
      if ((eventCategoryName ?? '').trim().isNotEmpty)
        (eventCategoryName ?? '').trim(),
      if (item.categoryName.trim().isNotEmpty) item.categoryName.trim(),
      if ((categoryName ?? '').trim().isNotEmpty)
        (categoryName ?? '').trim(),
    ];
    final categoryText =
        categoryCandidates.isNotEmpty ? categoryCandidates.first : 'Не указана';
    final dateText = date.isNotEmpty
        ? date
        : (fallbackDate.isNotEmpty ? fallbackDate : 'Не указана');

    Widget buildPoster() {
      final borderRadius = BorderRadius.circular(12);
      final placeholder = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.event, size: 32, color: Colors.grey),
      );

      if (item.image.isNotEmpty) {
        final imageWidget = ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            item.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
        return Hero(
          tag: 'event-${item.id}',
          child: imageWidget,
        );
      }

      return ClipRRect(
        borderRadius: borderRadius,
        child: placeholder,
      );
    }

    Widget buildInfoLine(String label, String value) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: labelStyle),
            TextSpan(text: value, style: baseInfoStyle),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: posterWidth,
              height: posterHeight,
              child: buildPoster(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 12),
                  buildInfoLine('Место', placeText),
                  const SizedBox(height: 8),
                  buildInfoLine('Категория', categoryText),
                  const SizedBox(height: 8),
                  buildInfoLine('Дата', dateText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

