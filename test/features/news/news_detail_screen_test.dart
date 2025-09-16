import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/news/models/news_item.dart';
import 'package:m_club/features/news/news_detail_screen.dart';

void main() {
  testWidgets('shows title and content', (tester) async {
    final item = NewsItem(
      id: '1',
      title: 'Test title',
      contentPreview: 'Preview',
      contentFull: '<p>Full text</p>',
      image: '',
      url: 'https://example.com',
      author: 'Author',
      published: DateTime(2024, 1, 1),
      rubric: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NewsDetailScreen(
          initialItems: [item],
          initialIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test title'), findsOneWidget);
    expect(find.text('Full text'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
  });
}
