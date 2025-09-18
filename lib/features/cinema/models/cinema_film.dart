import 'cinema_showtime.dart';

class CinemaFilm {
  CinemaFilm({
    required this.filmId,
    required this.name,
    required this.imageUrl,
    required this.genre,
    required this.duration,
    required this.rating,
    required this.trailerUrl,
    required this.uuid,
    this.time,
    this.description,
    this.year,
    this.country,
    this.poster,
    this.ratingVotes,
    this.replyCount,
    List<CinemaShowtime>? showtimes,
  }) : showtimes = List.unmodifiable(showtimes ?? const []);

  final String filmId;
  final String name;
  final String imageUrl;
  final String genre;
  final String duration;
  final String rating;
  final String trailerUrl;
  final String uuid;
  final String? time;
  final String? description;
  final String? year;
  final String? country;
  final String? poster;
  final int? ratingVotes;
  final int? replyCount;
  final List<CinemaShowtime> showtimes;

  bool get hasPoster => imageUrl.isNotEmpty;
  bool get hasTrailer => trailerUrl.isNotEmpty;

  factory CinemaFilm.fromJson(Map<String, dynamic> json) {
    final filmdata = json['filmdata'];

    return CinemaFilm(
      filmId: _stringValue(json['film_id']),
      name: _stringValue(json['name']),
      imageUrl: _stringValue(json['img']),
      genre: _stringValue(json['genre']),
      duration: _stringValue(json['duration']),
      rating: _stringValue(json['rating']),
      trailerUrl: _stringValue(json['lvideo']),
      uuid: _stringValue(json['uuid']),
      time: _nullableString(json['time']),
      ratingVotes: _parseInt(json['ratingVotes']),
      replyCount: _parseInt(json['replys']),
      description: filmdata is Map ? _nullableString(filmdata['description']) : null,
      year: filmdata is Map ? _nullableString(filmdata['year']) : null,
      country: filmdata is Map
          ? _nullableString(filmdata['country'] ?? filmdata['countries'])
          : null,
      poster: filmdata is Map ? _nullableString(filmdata['poster']) : null,
      showtimes: _parseShowtimes(json['showtimes']),
    );
  }

  static List<CinemaShowtime> _parseShowtimes(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((raw) => raw.map((key, value) => MapEntry(key.toString(), value)))
          .map(CinemaShowtime.fromJson)
          .toList();
    }
    if (value is Map) {
      final showtimes = <CinemaShowtime>[];
      value.forEach((_, raw) {
        if (raw is Map) {
          showtimes.add(
            CinemaShowtime.fromJson(
              raw.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      });
      return showtimes;
    }
    return const [];
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return int.tryParse(value.toString());
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final stringValue = _stringValue(value).trim();
    return stringValue.isEmpty ? null : stringValue;
  }
}
