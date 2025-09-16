import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voteBenefit returns actual rating and vote', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data, isA<FormData>());
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'rating': 10, 'vote': -1}
              },
            ),
          );
        },
      ),
    );

    final result = await service.voteBenefit(123, -1);
    expect(result, {'rating': 10, 'vote': -1});

    service.dio.interceptors.clear();
  });

  test('checkinBenefit sends id and coordinates', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/benefits/checkin');
          expect(options.data, isA<FormData>());
          final form = options.data as FormData;
          final fields = {for (final f in form.fields) f.key: f.value};
          expect(fields['id'], '123');
          expect(fields['coordinates'], '{"lat":10.0,"lng":20.0}');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
            ),
          );
        },
      ),
    );

    await service.checkinBenefit(123, 10.0, 20.0);

    service.dio.interceptors.clear();
  });

  test('checkinRecommendation sends id and coordinates', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/recommendation/checkin');
          expect(options.data, isA<FormData>());
          final form = options.data as FormData;
          final fields = {for (final f in form.fields) f.key: f.value};
          expect(fields['id'], '42');
          expect(fields['coordinates'], '{"lat":1.0,"lng":2.0}');
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
            ),
          );
        },
      ),
    );

    await service.checkinRecommendation(42, 1.0, 2.0);

    service.dio.interceptors.clear();
  });

  test(
      'toggleRecommendationFavorite hits endpoint and parses favorites flag',
      () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/recommendation/favorites');
          expect(options.data, isA<FormData>());
          final form = options.data as FormData;
          final fields = {for (final f in form.fields) f.key: f.value};
          expect(fields['id'], '5');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'favorites': 1}
              },
            ),
          );
        },
      ),
    );

    final result = await service.toggleRecommendationFavorite(5);
    expect(result, true);

    service.dio.interceptors.clear();
  });

  test('toggleRecommendationFavorite parses is_favorite flag', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'is_favorite': false}
              },
            ),
          );
        },
      ),
    );

    final result = await service.toggleRecommendationFavorite(6);
    expect(result, false);

    service.dio.interceptors.clear();
  });

}
