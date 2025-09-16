import 'package:intl/intl.dart';

String timeAgo(dynamic input) {
  DateTime date;
  if (input is DateTime) {
    date = input;
  } else if (input is int) {
    date = DateTime.fromMillisecondsSinceEpoch(
      input < 1000000000000 ? input * 1000 : input,
    );
  } else if (input is double) {
    final ms = input < 1000000000000 ? (input * 1000).toInt() : input.toInt();
    date = DateTime.fromMillisecondsSinceEpoch(ms);
  } else {
    throw ArgumentError('Unsupported input type');
  }

  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays >= 7) {
    return DateFormat('dd.MM.yyyy', 'ru').format(date);
  } else if (diff.inDays >= 1) {
    final days = diff.inDays;
    return '$days ${_plural(days, 'день', 'дня', 'дней')} назад';
  } else if (diff.inHours >= 1) {
    final hours = diff.inHours;
    return '$hours ${_plural(hours, 'час', 'часа', 'часов')} назад';
  } else {
    final minutes = diff.inMinutes;
    return '$minutes ${_plural(minutes, 'минута', 'минуты', 'минут')} назад';
  }
}

String _plural(int number, String one, String few, String many) {
  final n = number % 100;
  if (n >= 11 && n <= 14) {
    return many;
  }
  switch (number % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
  }
}

