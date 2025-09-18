import 'package:flutter/material.dart';

import '../../core/services/events_api_service.dart';
import '../../core/utils/html_utils.dart';
import 'events_detail_screen.dart';
import 'models/event_item.dart';
import 'widgets/event_list_item_skeleton.dart';
import 'utils/event_date_formatter.dart';

class EventsList extends StatefulWidget {
  const EventsList({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  final _api = EventsApiService();
  final _scrollController = ScrollController();
  final List<EventItem> _items = [];
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
      final page = await _api.fetchEvents(
        page: _page,
        categoryId: widget.categoryId,
      );
      setState(() {
        _items.addAll(page.items);
        _page = page.page + 1;
        _pages = page.pages;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  @override
  void didUpdateWidget(covariant EventsList oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          separatorBuilder: (_, __) => const Divider(height: 0),
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
          return const Divider(height: 0);
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
  const EventListItem({super.key, required this.item, this.onTap});

  final EventItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width * 0.56;
    final summary = htmlToPlainText(item.summary.isNotEmpty
        ? item.summary
        : item.description);
    final date = formatEventDateRange(item.startDate, item.endDate);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.image.isNotEmpty)
            Hero(
              tag: 'event-${item.id}',
              child: Image.network(
                item.image,
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
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
              child: const Icon(Icons.event, size: 48, color: Colors.grey),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
                if (summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                if (item.venueName.isNotEmpty || item.venueAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              if (item.venueName.isNotEmpty) item.venueName,
                              if (item.venueAddress.isNotEmpty) item.venueAddress,
                            ].join(', '),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.price.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.sell, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.price,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
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

