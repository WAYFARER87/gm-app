import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/events/events_detail_screen.dart';
import 'package:m_club/features/events/events_list.dart';
import 'package:m_club/features/events/models/event_item.dart';

void main() {
  test('EventItem.fromJson uses content preview for summary', () {
    final item = EventItem.fromJson({
      'id': 42,
      'feed_id': '100',
      'title': 'Sample Event',
      'content_preview': 'Short preview text',
      'description': 'Longer description',
    });

    expect(item.summary, 'Short preview text');
  });

  test('EventItem.fromJson extracts category name with fallbacks', () {
    final directCategory = EventItem.fromJson({
      'id': 1,
      'feed_id': '500',
      'title': 'Direct Category Event',
      'category': {'title': 'Музыка'},
    });

    expect(directCategory.categoryName, 'Музыка');

    final fallbackCategory = EventItem.fromJson({
      'id': 2,
      'feed_id': '501',
      'title': 'Fallback Category Event',
      'category_title': 'Театр',
    });

    expect(fallbackCategory.categoryName, 'Театр');
  });

  test('EventItem.fromJson builds ticket info from tickets field only', () {
    final item = EventItem.fromJson({
      'id': 21,
      'feed_id': '510',
      'title': 'Ticketed Event',
      'price': 'Should be ignored',
      'tickets': [
        {'name': 'Взрослый', 'price': '500 ₽'},
        {'name': 'Детский', 'price': '300 ₽'},
      ],
    });

    expect(item.price, 'Взрослый — 500 ₽\nДетский — 300 ₽');
  });

  test('EventItem.fromJson keeps price empty when tickets lack info', () {
    final item = EventItem.fromJson({
      'id': 22,
      'feed_id': '511',
      'title': 'Free Event',
      'price': '250 ₽',
      'tickets': null,
    });

    expect(item.price, isEmpty);
  });

  testWidgets('EventListItem displays parsed summary text', (tester) async {
    final item = EventItem.fromJson({
      'id': 7,
      'feed_id': '200',
      'title': 'Preview Event',
      'content_preview': '<p>Preview body</p>',
      'description': '<p>Full description</p>',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventListItem(item: item),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Preview body'), findsOneWidget);
  });

  testWidgets('EventListItem prefers item category over fallback', (tester) async {
    final item = EventItem.fromJson({
      'id': 11,
      'feed_id': '300',
      'title': 'Category Event',
      'category': 'Музыка',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventListItem(
            item: item,
            eventCategoryName: item.categoryName,
            categoryName: 'Фолбэк',
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Музыка'), findsOneWidget);
    expect(find.textContaining('Фолбэк'), findsNothing);
  });

  testWidgets('EventListItem uses raw time when date parsing fails', (tester) async {
    final item = EventItem.fromJson({
      'id': 12,
      'feed_id': '310',
      'title': 'Time Only Event',
      'time': '19:30',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventListItem(item: item),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('19:30'), findsOneWidget);
  });

  testWidgets('EventDetailScreen shows raw time fallback when needed',
      (tester) async {
    final item = EventItem.fromJson({
      'id': 13,
      'feed_id': '320',
      'title': 'Detail Time Event',
      'time': '21:00',
      'description': '',
      'summary': '',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(item: item),
      ),
    );

    await tester.pump();

    expect(find.text('21:00'), findsOneWidget);
  });

  testWidgets('EventDetailScreen renders multiline description', (tester) async {
    final item = EventItem.fromJson({
      'id': 14,
      'feed_id': '330',
      'title': 'Description Event',
      'description': '<p>Первый абзац</p><p>Второй абзац</p>',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(item: item),
      ),
    );

    await tester.pump();

    final description =
        tester.widget<Text>(find.byKey(const Key('event-description')));
    expect(description.data, 'Первый абзац\n\nВторой абзац');
  });

  testWidgets('EventDetailScreen hides ticket summary when absent', (tester) async {
    final item = EventItem.fromJson({
      'id': 15,
      'feed_id': '331',
      'title': 'No Tickets Event',
      'description': '',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(item: item),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Билеты'), findsNothing);
  });

  testWidgets('EventDetailScreen opens poster viewer on tap', (tester) async {
    final item = EventItem.fromJson({
      'id': 16,
      'feed_id': '332',
      'title': 'Poster Viewer Event',
      'description': '',
      'summary': '',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(item: item),
      ),
    );

    await tester.pump();

    await tester.tap(find.byHeroTag('event-${item.id}'));
    await tester.pumpAndSettle();

    expect(find.text('Постер'), findsOneWidget);
  });
}
