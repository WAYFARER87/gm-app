import 'package:intl/intl.dart';

String formatEventDateRange(
  DateTime? start,
  DateTime? end, {
  bool includeWeekday = false,
}) {
  if (start == null && end == null) return '';
  final datePattern = includeWeekday ? 'EEEE, d MMMM' : 'd MMMM';
  final dateFormatter = DateFormat(datePattern, 'ru');
  final timeFormatter = DateFormat('HH:mm');

  if (start == null) {
    return 'до ${dateFormatter.format(end!)}';
  }

  if (end == null) {
    final date = dateFormatter.format(start);
    final time = timeFormatter.format(start);
    return '$date · $time';
  }

  final sameDay = start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  final startDate = dateFormatter.format(start);
  final startTime = timeFormatter.format(start);
  final endDate = dateFormatter.format(end);
  final endTime = timeFormatter.format(end);

  if (sameDay) {
    return '$startDate · $startTime – $endTime';
  }

  return '$startDate $startTime – $endDate $endTime';
}
