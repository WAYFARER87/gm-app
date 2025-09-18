class CinemaShowtime {
  const CinemaShowtime({
    required this.time,
    required this.cinemaId,
    required this.room,
    required this.format,
    required this.when,
    required this.endTime,
    required this.buyUrl,
  });

  final String time;
  final String cinemaId;
  final String room;
  final String format;
  final String when;
  final String endTime;
  final String buyUrl;

  bool get hasBuyUrl => buyUrl.isNotEmpty;

  factory CinemaShowtime.fromJson(Map<String, dynamic> json) {
    return CinemaShowtime(
      time: _stringValue(json['time']),
      cinemaId: _stringValue(json['cinema_id']),
      room: _stringValue(json['room']),
      format: _stringValue(json['format']),
      when: _stringValue(json['when']),
      endTime: _stringValue(json['endTime']),
      buyUrl: _stringValue(json['buyUrl']),
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
