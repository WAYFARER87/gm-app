import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:m_club/core/services/api_service.dart';
import 'package:m_club/features/auth/club_card_screen.dart';
import 'package:m_club/features/mclub/offer_detail_screen.dart';
import 'package:m_club/features/mclub/offer_model.dart';

Offer _buildOffer({
  required int vote,
  required int rating,
  DateTime? dateEnd,
  List<Branch> branches = const [],
}) {
  return Offer(
    id: '1',
    categoryIds: const [],
    categoryNames: const [],
    title: 'Title',
    titleShort: 'Title',
    descriptionShort: 'Short',
    descriptionHtml: '<p>Full</p>',
    benefitText: '',
    benefitPercent: null,
    dateStart: null,
    dateEnd: dateEnd,
    photoUrl: null,
    photosUrl: const [],
    shareUrl: null,
    branches: branches,
    links: OfferLinks(),
    rating: rating,
    vote: vote,
    isFavorite: false,
  );
}

class _FakeGeolocator extends GeolocatorPlatform {
  final Position position;
  _FakeGeolocator(this.position);

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      position;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('highlights upvote and shows rating', (tester) async {
    final offer = _buildOffer(vote: 1, rating: 42);
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final upIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    final downIcon =
        tester.widget<Icon>(find.byIcon(Icons.arrow_downward_outlined));
    expect(upIcon.color, Colors.green);
    expect(downIcon.color, Colors.grey);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('highlights downvote and shows rating', (tester) async {
    final offer = _buildOffer(vote: -1, rating: 7);
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final upIcon =
        tester.widget<Icon>(find.byIcon(Icons.arrow_upward_outlined));
    final downIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
    expect(upIcon.color, Colors.grey);
    expect(downIcon.color, Colors.red);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows formatted end date', (tester) async {
    final offer = _buildOffer(vote: 0, rating: 0, dateEnd: DateTime(2024, 5, 20));
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    expect(find.text('Действует до 20.05.2024'), findsOneWidget);
  });

  testWidgets('lays out vote row horizontally', (tester) async {
    final offer = _buildOffer(vote: 0, rating: 10);
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final upPos =
        tester.getTopLeft(find.byIcon(Icons.arrow_upward_outlined));
    final ratingPos = tester.getTopLeft(find.text('10'));
    final downPos =
        tester.getTopLeft(find.byIcon(Icons.arrow_downward_outlined));

    expect(upPos.dy, closeTo(ratingPos.dy, 1));
    expect(ratingPos.dy, closeTo(downPos.dy, 1));
    expect(upPos.dx < ratingPos.dx, true);
    expect(ratingPos.dx < downPos.dx, true);
  });

  testWidgets('rating and date containers have equal height', (tester) async {
    final offer =
        _buildOffer(vote: 0, rating: 5, dateEnd: DateTime(2024, 5, 20));
    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    final ratingContainer = find.ancestor(
      of: find.byIcon(Icons.arrow_upward_outlined),
      matching:
          find.byWidgetPredicate((w) => w is Container && w.decoration != null),
    );

    final dateContainer = find.ancestor(
      of: find.text('Действует до 20.05.2024'),
      matching: find.byType(Container),
    );

    final ratingSize = tester.getSize(ratingContainer);
    final dateSize = tester.getSize(dateContainer);
    expect(ratingSize.height, dateSize.height);
  });

  testWidgets('opens card without checkin when far', (tester) async {
    final api = ApiService();
    api.dio.interceptors.clear();
    RequestOptions? lastRequest;
    api.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        lastRequest = options;
        handler.resolve(Response(requestOptions: options, data: {}));
      }),
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

    final offer = _buildOffer(
      vote: 0,
      rating: 0,
      branches: [Branch(lat: 10, lng: 10)],
    );

    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Клубная карта'));
    await tester.pumpAndSettle();

    expect(find.byType(ClubCardScreen), findsOneWidget);
    expect(lastRequest, isNull);
  });

  testWidgets('opens card and checks in when near', (tester) async {
    final api = ApiService();
    api.dio.interceptors.clear();
    RequestOptions? lastRequest;
    api.dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        lastRequest = options;
        handler.resolve(Response(requestOptions: options, data: {}));
      }),
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

    final offer = _buildOffer(
      vote: 0,
      rating: 0,
      branches: [Branch(lat: 0, lng: 0)],
    );

    await tester.pumpWidget(MaterialApp(home: OfferDetailScreen(offer: offer)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Клубная карта'));
    await tester.pumpAndSettle();

    expect(find.byType(ClubCardScreen), findsOneWidget);
    expect(lastRequest?.path, '/benefits/checkin');
  });
}
