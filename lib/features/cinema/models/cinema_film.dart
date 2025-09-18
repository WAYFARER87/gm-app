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
    final kpData = json['kp_data'];
    final resolvedCountry = _resolveCountry(filmdata, kpData);

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

      country: resolvedCountry,

      poster: filmdata is Map ? _nullableString(filmdata['poster']) : null,
      showtimes: _parseShowtimes(json['showtimes']),
    );
  }

  static String? _resolveCountry(dynamic filmdata, dynamic kpData) {
    final countryFromFilmdata =
        filmdata is Map ? _parseCountries(filmdata['country'] ?? filmdata['countries']) : null;
    if (countryFromFilmdata != null) {
      return countryFromFilmdata;
    }

    if (kpData is Map) {
      final countryFromKp = _parseCountries(kpData['countries']);
      if (countryFromKp != null) {
        return countryFromKp;
      }
    }

    return null;
  }

  static String? _parseCountries(dynamic raw) {
    if (raw == null) return null;

    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (raw is num) {
      final text = raw.toString().trim();
      return text.isEmpty ? null : text;
    }

    if (raw is Iterable) {
      final parts = <String>[];
      for (final item in raw) {
        final parsed = _parseCountries(item);
        if (parsed != null && parsed.trim().isNotEmpty) {
          parts.add(parsed.trim());
        }
      }
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
      return null;
    }

    if (raw is Map) {
      for (final key in const ['name', 'title', 'country', 'value']) {
        if (raw.containsKey(key)) {
          final parsed = _parseCountries(raw[key]);
          if (parsed != null) {
            return parsed;
          }
        }
      }
      final nested = _parseCountries(raw.values);
      if (nested != null) {
        return nested;
      }
      return null;
    }

    final fallback = raw.toString().trim();
    return fallback.isEmpty ? null : fallback;
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
