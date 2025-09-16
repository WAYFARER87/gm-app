import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/mclub/offer_model.dart';

void main() {
  group('Offer.fromJson vote parsing', () {
    Map<String, dynamic> buildJson(dynamic vote) => {
          'id': 1,
          'category': [],
          'title': 't',
          'title_short': 'ts',
          'description_short': '',
          'description': '',
          'benefit': '',
          'photos_url': [],
          'branches': [],
          'links': {},
          'rating': 0,
          'is_favorite': 0,
          if (vote != null) 'vote': vote,
        };

    test('parses vote 1', () {
      final offer = Offer.fromJson(buildJson(1));
      expect(offer.vote, 1);
    });

    test('parses vote -1', () {
      final offer = Offer.fromJson(buildJson(-1));
      expect(offer.vote, -1);
    });

    test('parses vote 0', () {
      final offer = Offer.fromJson(buildJson(0));
      expect(offer.vote, 0);
    });

    test('parses null vote as 0', () {
      final offer = Offer.fromJson(buildJson(null));
      expect(offer.vote, 0);
    });
  });

  group('Offer.fromJson sponsor_email parsing', () {
    Map<String, dynamic> buildJson(String? email) => {
          'id': 1,
          'category': [],
          'title': 't',
          'title_short': 'ts',
          'description_short': '',
          'description': '',
          'benefit': '',
          'photos_url': [],
          'branches': [],
          'links': {},
          'rating': 0,
          'is_favorite': 0,
          if (email != null) 'sponsor_email': email,
        };

    test('parses sponsor_email', () {
      final offer = Offer.fromJson(buildJson('manager@example.com'));
      expect(offer.sponsorEmail, 'manager@example.com');
    });

    test('parses absent sponsor_email as null', () {
      final offer = Offer.fromJson(buildJson(null));
      expect(offer.sponsorEmail, isNull);
    });
  });
}
