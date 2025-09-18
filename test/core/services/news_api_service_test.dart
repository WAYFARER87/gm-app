import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/news_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = NewsApiService();

  setUp(() {
    service.dio.interceptors.clear();
  });

  tearDown(() {
    service.dio.interceptors.clear();
  });

  test('fetchNews parses items and pagination', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'items': [
                    {'id': 1, 'title': 'First'},
                    {'id': 2, 'title': 'Second'},
                  ],
                  'pagination': {
                    'current_page': 2,
                    'per_page': 10,
                    'total': 20,
                    'last_page': 2,
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchNews(page: 2, perPage: 10);
    expect(page.items, hasLength(2));
    expect(page.page, 2);
    expect(page.total, 20);
    expect(page.pages, 2);
  });

  test('fetchNews parses pagination when numbers are strings', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'items': [
                    {'id': 1, 'title': 'First'},
                    {'id': 2, 'title': 'Second'},
                  ],
                  'meta': {
                    'pagination': {
                      'current_page': '2',
                      'per_page': '10',
                      'total': '20',
                      'total_pages': '2',
                    },
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchNews(page: 2, perPage: 10);
    expect(page.items, hasLength(2));
    expect(page.page, 2);
    expect(page.total, 20);
    expect(page.pages, 2);
  });

  test('fetchNews computes pages when missing', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'items': [
                    {'id': 1, 'title': 'Only'},
                  ],
                  'pagination': {
                    'current_page': 1,
                    'per_page': 8,
                    'total': 15,
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchNews(page: 1, perPage: 8);
    expect(page.items, hasLength(1));
    expect(page.page, 1);
    expect(page.total, 15);
    expect(page.pages, 2);
  });

  test('fetchFeeds maps feed id variations to category id', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'feeds': [
                    {'feed_id': 10, 'name': 'First'},
                    {'feedId': 'alpha', 'name': 'Second'},
                    {'feed-id': 'beta', 'name': 'Third'},
                  ],
                },
              },
            ),
          );
        },
      ),
    );

    final feeds = await service.fetchFeeds();
    expect(feeds.map((c) => c.id).toList(), ['10', 'alpha', 'beta']);
  });

  test('fetchNews sends feed id when provided', () async {
    String? passedCategoryId;
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.endsWith('news/feeds')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': [
                    {'feed_id': 777, 'name': 'Category'},
                  ],
                },
              ),
            );
            return;
          }

          if (options.path.endsWith('news')) {
            passedCategoryId = options.queryParameters['feed_id']?.toString();
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {
                    'items': [
                      {'id': 1, 'title': 'Only'},
                    ],
                    'pagination': {
                      'current_page': 1,
                      'per_page': 10,
                      'total': 1,
                      'last_page': 1,
                    },
                  },
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    final categories = await service.fetchFeeds();
    expect(categories, hasLength(1));
    expect(categories.first.id, '777');

    await service.fetchNews(categoryId: categories.first.id);
    expect(passedCategoryId, '777');
  });
}
