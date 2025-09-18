import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/events_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = EventsApiService();

  setUp(() {
    service.dio.interceptors.clear();
  });

  tearDown(() {
    service.dio.interceptors.clear();
  });

  test('fetchEvents sends category id when provided', () async {
    String? passedCategoryId;
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.endsWith('events')) {
            passedCategoryId =
                options.queryParameters['category_id']?.toString();
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {
                    'items': [
                      {
                        'id': 1,
                        'feed_id': '777',
                        'title': 'Event',
                        'summary': 'Summary',
                        'description': 'Description',
                        'image': 'image.png',
                        'url': 'https://example.com',
                        'price': 'Free',
                        'organizer': 'Org',
                        'phone': '1234567890',
                        'venue_name': 'Venue',
                        'venue_address': 'Address',
                      },
                    ],
                    'pagination': {
                      'page': 1,
                      'perPage': 10,
                      'total': 1,
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

    await service.fetchEvents(categoryId: '777');
    expect(passedCategoryId, '777');
  });

  test('fetchEvents uses custom base path', () async {
    final calendarService = EventsApiService(basePath: 'calendar');
    String? requestedPath;

    calendarService.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPath = options.path;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'items': [
                    {
                      'id': 1,
                      'feed_id': '777',
                      'title': 'Event',
                      'summary': 'Summary',
                      'description': 'Description',
                      'image': 'image.png',
                      'url': 'https://example.com',
                      'price': 'Free',
                      'organizer': 'Org',
                      'phone': '1234567890',
                      'venue_name': 'Venue',
                      'venue_address': 'Address',
                    },
                  ],
                  'pagination': {
                    'page': 1,
                    'perPage': 10,
                    'total': 1,
                  },
                },
              },
            ),
          );
        },
      ),
    );

    await calendarService.fetchEvents();
    expect(requestedPath, 'calendar');
    calendarService.dio.interceptors.clear();
  });
}
