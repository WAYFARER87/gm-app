import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
