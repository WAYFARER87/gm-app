import 'dart:collection';
import 'dart:math' as math;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;
          final horizontalSpacing = isCompact ? 16.0 : 24.0;
          final contentPadding = EdgeInsets.fromLTRB(
            0,
            isCompact ? 20 : 24,
            isCompact ? 16 : 24,
            24,
          );

          final details = Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  film.name.isNotEmpty ? film.name : 'Без названия',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (infoChips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: infoChips,
                  ),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    htmlToPlainText(description),
                    style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Сеансы',
                  style: (textTheme.titleMedium ?? textTheme.titleSmall ??
                          const TextStyle())
                      .copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (groups.isNotEmpty && showtimesByCinema.isNotEmpty)
                  _ShowtimeScheduleTable(
                    dayLabels: groups.keys.toList(),
                    cinemaShowtimes: showtimesByCinema,
                  )
                else
                  Text(
                    'Нет ближайших сеансов',
                    style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          );

          final basePosterWidth =
              isCompact ? 120.0 : _Poster.defaultWidth;
          final maxPosterWidth = constraints.maxWidth - horizontalSpacing;
          final posterWidth =
              (maxPosterWidth.isFinite && maxPosterWidth > 0)
                  ? math.min(
                      basePosterWidth,
                      maxPosterWidth * (isCompact ? 0.45 : 0.35),
                    )
                  : basePosterWidth;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(
                imageUrl: film.imageUrl,
                width: posterWidth,
              ),
              SizedBox(width: horizontalSpacing),
              Expanded(child: details),
            ],
          );
        },
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
  const _Poster({required this.imageUrl, required this.width});

  static const double defaultWidth = 136.0;
  final String imageUrl;
  final double width;

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

    final posterWidth = width.isFinite && width > 0 ? width : defaultWidth;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: SizedBox(
        width: posterWidth,
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
      color: colorScheme.onSurface.withOpacity(0.7),
      letterSpacing: 0.2,
    );
    final cinemaStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final timeStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final emptyStyle = timeStyle.copyWith(
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface.withOpacity(0.4),
    );
    final borderColor = colorScheme.outline.withOpacity(0.16);
    final headerColor = colorScheme.surfaceVariant.withOpacity(0.6);
    final chipColor = colorScheme.primary.withOpacity(0.08);

    Widget buildTable() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: {
            0: const IntrinsicColumnWidth(),
            for (var i = 1; i <= dayLabels.length; i++) i: const FlexColumnWidth(),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor, width: 1),
            verticalInside: BorderSide(color: borderColor, width: 1),
            top: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
            left: BorderSide(color: borderColor, width: 1),
            right: BorderSide(color: borderColor, width: 1),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                _ScheduleCell(
                  child: Text('Кинотеатр', style: headerStyle),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                for (final day in dayLabels)
                  _ScheduleCell(
                    alignCenter: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Text(
                      _formatCinemaName(cinemaEntry.key),
                      style: cinemaStyle,
                    ),
                  ),
                  for (final day in dayLabels)
                    _ScheduleCell(
                      alignCenter: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: _buildTimeCell(
                        cinemaEntry.value[day] ?? const <CinemaShowtime>[],
                        timeStyle,
                        emptyStyle,
                        chipColor,
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final table = buildTable();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        );
      },
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
    Color chipColor,
  ) {
    final values = showtimes
        .map(_formatShowtime)
        .where((value) => value.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      return Text('—', style: emptyStyle, textAlign: TextAlign.center);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final value in values)
          DecoratedBox(
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(value, style: timeStyle, textAlign: TextAlign.center),
            ),
          ),
      ],
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
  const _ScheduleCell({
    required this.child,
    this.alignCenter = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  final Widget child;
  final bool alignCenter;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final alignment = alignCenter ? Alignment.center : Alignment.centerLeft;
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}
