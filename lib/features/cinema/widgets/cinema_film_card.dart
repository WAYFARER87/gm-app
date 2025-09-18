import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../core/utils/html_utils.dart';
import '../models/cinema_film.dart';
import '../models/cinema_showtime.dart';

class CinemaFilmCard extends StatelessWidget {
  const CinemaFilmCard({super.key, required this.film});

  final CinemaFilm film;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final infoChips = _buildInfoChips(colorScheme, textTheme);
    final groups = _groupShowtimes(film.showtimes);
    final showtimesByCinema = _groupShowtimesByCinema(film.showtimes);
    final description = film.description?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Poster(imageUrl: film.imageUrl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.name.isNotEmpty ? film.name : 'Без названия',
                    style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (infoChips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: infoChips,
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      htmlToPlainText(description),
                      style: (textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (groups.isNotEmpty && showtimesByCinema.isNotEmpty) ...[
                    _ShowtimeScheduleTable(
                      dayLabels: groups.keys.toList(),
                      cinemaShowtimes: showtimesByCinema,
                    ),
                  ] else
                    Text(
                      'Нет ближайших сеансов',
                      style:
                          (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoChips(ColorScheme colorScheme, TextTheme textTheme) {
    final chips = <Widget>[];

    if (film.genre.isNotEmpty) {
      chips.add(_InfoChip(
        icon: Icons.local_movies_outlined,
        label: film.genre,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ));
    }

    final durationText = _durationText(film.duration);
    if (durationText != null) {
      chips.add(_InfoChip(
        icon: Icons.schedule_outlined,
        label: durationText,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ));
    }

    final ratingText = _ratingText(film.rating, film.ratingVotes);
    if (ratingText != null) {
      chips.add(_InfoChip(
        icon: Icons.star_rate_rounded,
        label: ratingText,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ));
    }

    if (film.year != null && film.year!.isNotEmpty) {
      chips.add(_InfoChip(
        icon: Icons.event,
        label: 'Год: ${film.year}',
        colorScheme: colorScheme,
        textTheme: textTheme,
      ));
    }

    return chips;
  }

  LinkedHashMap<String, List<CinemaShowtime>> _groupShowtimes(
    List<CinemaShowtime> showtimes,
  ) {
    final groups = LinkedHashMap<String, List<CinemaShowtime>>();
    for (final showtime in showtimes) {
      final key = showtime.when.isNotEmpty ? showtime.when : 'Расписание';
      groups.putIfAbsent(key, () => []).add(showtime);
    }
    return groups;
  }

  LinkedHashMap<String, LinkedHashMap<String, List<CinemaShowtime>>>
      _groupShowtimesByCinema(
    List<CinemaShowtime> showtimes,
  ) {
    final groups =
        LinkedHashMap<String, LinkedHashMap<String, List<CinemaShowtime>>>();
    for (final showtime in showtimes) {
      final cinemaGroup = groups.putIfAbsent(
        showtime.cinemaId,
        () => LinkedHashMap<String, List<CinemaShowtime>>(),
      );
      final key = showtime.when.isNotEmpty ? showtime.when : 'Расписание';
      cinemaGroup.putIfAbsent(key, () => <CinemaShowtime>[]).add(showtime);
    }
    return groups;
  }

  String? _durationText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed != null && parsed > 0) {
      return '$parsed мин';
    }
    return trimmed;
  }

  String? _ratingText(String rating, int? votes) {
    final value = rating.trim();
    if (value.isEmpty || value == '0') return null;
    if (votes != null && votes > 0) {
      return '$value ★ (${votes.toString()} голосов)';
    }
    return '$value ★';
  }

}

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl});

  static const double _posterWidth = 132.0;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.local_movies, size: 48, color: Colors.grey),
        );

    final poster = imageUrl.isEmpty
        ? placeholder()
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder(),
          );

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: SizedBox(
        width: _posterWidth,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: poster,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowtimeScheduleTable extends StatelessWidget {
  const _ShowtimeScheduleTable({
    required this.dayLabels,
    required this.cinemaShowtimes,
  });

  final List<String> dayLabels;
  final LinkedHashMap<String, LinkedHashMap<String, List<CinemaShowtime>>>
      cinemaShowtimes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final headerStyle = (textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withOpacity(0.6),
    );
    final cinemaStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final timeStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: colorScheme.onSurface,
    );
    final emptyStyle = timeStyle.copyWith(
      color: colorScheme.onSurface.withOpacity(0.4),
    );

    return Table(
      columnWidths: {
        0: const IntrinsicColumnWidth(),
        for (var i = 1; i <= dayLabels.length; i++) i: const FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            _ScheduleCell(
              child: Text('Кинотеатр', style: headerStyle),
            ),
            for (final day in dayLabels)
              _ScheduleCell(
                alignCenter: true,
                child: Text(
                  _formatDayLabel(day),
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        for (final cinemaEntry in cinemaShowtimes.entries)
          TableRow(
            children: [
              _ScheduleCell(
                child: Text(
                  _formatCinemaName(cinemaEntry.key),
                  style: cinemaStyle,
                ),
              ),
              for (final day in dayLabels)
                _ScheduleCell(
                  alignCenter: true,
                  child: _buildTimeCell(
                    cinemaEntry.value[day] ?? const <CinemaShowtime>[],
                    timeStyle,
                    emptyStyle,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _formatDayLabel(String raw) {
    final plain = htmlToPlainText(raw).trim();
    return plain.isNotEmpty ? plain : raw;
  }

  static String _formatCinemaName(String raw) {
    final plain = htmlToPlainText(raw).replaceAll('\n', ' ').trim();
    return plain.isNotEmpty ? plain : 'Кинотеатр';
  }

  static Widget _buildTimeCell(
    List<CinemaShowtime> showtimes,
    TextStyle timeStyle,
    TextStyle emptyStyle,
  ) {
    final values = showtimes
        .map(_formatShowtime)
        .where((value) => value.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      return Text('—', style: emptyStyle, textAlign: TextAlign.center);
    }

    return Text(
      values.join('\n'),
      style: timeStyle,
      textAlign: TextAlign.center,
    );
  }

  static String _formatShowtime(CinemaShowtime showtime) {
    final parts = <String>[];

    final time = showtime.time.trim();
    if (time.isNotEmpty) {
      parts.add(time);
    }

    final room = showtime.room.trim();
    if (room.isNotEmpty) {
      parts.add(room);
    }

    final format = showtime.format.trim();
    if (format.isNotEmpty) {
      parts.add(format);
    }

    return parts.join(' • ');
  }
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({required this.child, this.alignCenter = false});

  final Widget child;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    final alignment = alignCenter ? Alignment.center : Alignment.centerLeft;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}
