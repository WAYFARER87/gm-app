class CinemaShowtime {
  const CinemaShowtime({
    required this.time,
    required this.cinemaId,
    required this.cinemaName,
    required this.room,
    required this.format,
    required this.when,
    required this.endTime,
    required this.buyUrl,
  });

  final String time;
  final String cinemaId;
  final String cinemaName;
  final String room;
  final String format;
  final String when;
  final String endTime;
  final String buyUrl;

  bool get hasBuyUrl => buyUrl.isNotEmpty;
  String get cinemaTitle =>
      cinemaName.isNotEmpty ? cinemaName : cinemaId;

  factory CinemaShowtime.fromJson(Map<String, dynamic> json) {
    final rawCinema = json['cinema'];
    final rawCinemaId = json['cinema_id'] ?? json['cinemaId'];
    final rawCinemaName = json['cinema_name'] ??
        json['cinemaName'] ??
        json['cinema_title'] ??
        json['cinemaTitle'];

    return CinemaShowtime(
      time: _stringValue(json['time']),
      cinemaId: _stringValue(rawCinemaId ?? rawCinema ?? rawCinemaName),
      cinemaName:
          _stringValue(rawCinemaName ?? rawCinema ?? rawCinemaId),
      room: _stringValue(json['room']),
      format: _stringValue(json['format']),
      when: _stringValue(json['when']),
      endTime: _stringValue(json['endTime'] ?? json['end_time']),
      buyUrl: _stringValue(json['buyUrl'] ?? json['buy_url']),
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
