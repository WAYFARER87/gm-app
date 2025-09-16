import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voteRecommendation returns actual rating and vote', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data, isA<FormData>());
          expect(options.path, '/recommendation/vote');
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

    final result = await service.voteRecommendation(123, -1);
    expect(result, {'rating': 10, 'vote': -1});

    service.dio.interceptors.clear();
  });

}
