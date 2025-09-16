import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:m_club/core/services/api_service.dart';
import 'package:m_club/features/uae_unlocked/uae_unlocked_screen.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  final Position position;
  _FakeGeolocator(this.position);

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async => position;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calls checkin when user is near branch after 15s', (tester) async {
    final api = ApiService();
    api.dio.interceptors.clear();
    RequestOptions? lastRequest;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/recommendation/categories') {
            handler.resolve(Response(requestOptions: options, data: []));
          } else if (options.path == '/recommendation') {
            handler.resolve(Response(requestOptions: options, data: [
              {
                'id': 5,
                'title': 'Rec',
                'branches': [
                  {'lattitude': '0', 'longitude': '0'}
                ],
              }
            ]));
          } else if (options.path == '/recommendation/checkin') {
            lastRequest = options;
            handler.resolve(Response(requestOptions: options, data: {}));
          } else {
            handler.resolve(Response(requestOptions: options, data: {}));
          }
        },
      ),
    );

    GeolocatorPlatform.instance = _FakeGeolocator(
      Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime(0),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: UAEUnlockedScreen()));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(lastRequest?.path, '/recommendation/checkin');
    final form = lastRequest?.data as FormData;
    final fields = {for (final f in form.fields) f.key: f.value};
    expect(fields['id'], '5');
  });
}

