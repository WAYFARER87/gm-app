import 'event_item.dart';

class EventPage {
  final List<EventItem> items;
  final int page;
  final int pages;
  final int total;

  EventPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });
}
