import 'package:flutter/material.dart';

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

    final titleStyle = (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.2,
    );
    final baseInfoStyle =
        (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontSize: 14,
      color: colorScheme.onSurface.withOpacity(0.75),
      height: 1.4,
    );
    final labelStyle = baseInfoStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );

    Widget buildInfoLine(String label, String value) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: labelStyle),
            TextSpan(text: value, style: baseInfoStyle),
          ],
        ),
        softWrap: true,
      );
    }

    String normalizeValue(String? value, String placeholder) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isNotEmpty ? trimmed : placeholder;
    }

    final yearText = normalizeValue(film.year, 'Не указан');
    final countryText = normalizeValue(film.country, 'Не указана');
    final genreText = normalizeValue(film.genre, 'Не указан');
    final durationValue = _durationText(film.duration);
    final durationText = normalizeValue(durationValue, 'Не указана');

    final infoItems = <MapEntry<String, String>>[
      MapEntry('Год', yearText),
      MapEntry('Страна', countryText),
      MapEntry('Жанр', genreText),
      MapEntry('Длительность', durationText),
    ];

    final infoChildren = <Widget>[];
    for (var i = 0; i < infoItems.length; i++) {
      final item = infoItems[i];
      infoChildren.add(buildInfoLine(item.key, item.value));
      if (i < infoItems.length - 1) {
        infoChildren.add(const SizedBox(height: 8));
      }
    }

    const posterWidth = 120.0;
    const posterAspectRatio = 3 / 4;
    final posterHeight = posterWidth / posterAspectRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: posterWidth,
            height: posterHeight,
            child: InkWell(onTap: () => _showShowtimes(context), child: _Poster(imageUrl: film.imageUrl)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  film.name.isNotEmpty ? film.name : 'Без названия',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                const SizedBox(height: 12),
                ...infoChildren,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _durationText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed != null) {
      if (parsed <= 0) {
        return null;
      }
      return '$parsed мин';
    }
    return trimmed;
  }

  void _showShowtimes(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final tt = Theme.of(context).textTheme;
      final desc = (film.description ?? '').trim();

      return Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, t, child) {
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 8),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  desc,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurface.withOpacity(0.92),
                    height: 1.45,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.outlineVariant.withOpacity(0.0),
                      cs.outlineVariant.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 90,
              child: _ShowtimesStrip(
                showtimes: film.showtimes,
                onTapItem: null,
              ),
            ),
          ],
        ),
      );
    },
  );
}
}

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.local_movies, size: 48, color: Colors.grey),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}


class _ShowtimesStrip extends StatelessWidget {
  const _ShowtimesStrip({required this.showtimes, this.onTapItem});

  final List<CinemaShowtime> showtimes;
  final VoidCallback? onTapItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    if (showtimes.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: showtimes.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final s = showtimes[i];
        final when = _normalizeWhen(s.when);
        final time = (s.time.trim().isNotEmpty ? s.time.trim() : '—:—');
        final cinemaRaw = (s.cinemaName.isNotEmpty ? s.cinemaName : s.cinemaId).trim();
        final cinema = cinemaRaw.isEmpty ? 'Кинотеатр не указан' : cinemaRaw;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTapItem,
          child: Container(
            height: 90,
            width: 168,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(when, style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text(time, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  cinema,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _normalizeWhen(String w) {
    final lw = w.trim().toLowerCase();
    if (lw == 'сегодня') return 'Сегодня';
    if (lw == 'завтра') return 'Завтра';
    return w.trim().isEmpty ? 'Дата не указана' : w.trim();
  }
}

class _ShowtimesSheet extends StatelessWidget {
  const _ShowtimesSheet({required this.film});

  final CinemaFilm film;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final showtimes = film.showtimes;
    final cinemaGroups = _groupByCinema(showtimes);

    final titleStyle = (textTheme.titleLarge ?? const TextStyle(fontSize: 22)).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final subtitleStyle =
        (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: colorScheme.onSurface.withOpacity(0.7),
    );

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Сеансы', style: titleStyle),
                      if (film.name.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          film.name,
                          style: subtitleStyle,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cinemaGroups.isEmpty
                ? Center(
                    child: Text(
                      'Расписание недоступно',
                      style: subtitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: cinemaGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = cinemaGroups[index];
                      return _CinemaScheduleCard(group: group);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_CinemaGroupData> _groupByCinema(List<CinemaShowtime> showtimes) {
    final groups = <_CinemaGroupData>[];
    final indexByCinema = <String, int>{};

    for (final showtime in showtimes) {
      final cinemaTitle = _resolveCinemaTitle(showtime);
      final existingIndex = indexByCinema[cinemaTitle];
      if (existingIndex == null) {
        groups.add(
          _CinemaGroupData(
            cinemaTitle: cinemaTitle,
            showtimes: [showtime],
          ),
        );
        indexByCinema[cinemaTitle] = groups.length - 1;
      } else {
        groups[existingIndex].showtimes.add(showtime);
      }
    }

    return groups;
  }

  String _resolveCinemaTitle(CinemaShowtime showtime) {
    final normalizedName = _normalizeShowtimeValue(showtime.cinemaName);
    final normalizedId = _normalizeShowtimeValue(showtime.cinemaId);
    final resolved = normalizedName ?? normalizedId;
    return resolved ?? 'Кинотеатр не указан';
  }
}

class _CinemaGroupData {
  _CinemaGroupData({
    required this.cinemaTitle,
    List<CinemaShowtime>? showtimes,
  }) : showtimes = List<CinemaShowtime>.from(showtimes ?? const []);

  final String cinemaTitle;
  final List<CinemaShowtime> showtimes;
}

class _CinemaScheduleCard extends StatelessWidget {
  const _CinemaScheduleCard({required this.group});

  final _CinemaGroupData group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cinemaStyle = (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.2,
    );
    final dateStyle = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withOpacity(0.7),
      height: 1.3,
    );
    final detailStyle =
        (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
      color: colorScheme.onSurface.withOpacity(0.8),
      height: 1.3,
    );
    final timeStyle = (textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.primary,
      height: 1.2,
    );

    final dateGroups = _groupShowtimesByDate(group.showtimes);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.cinemaTitle,
                    style: cinemaStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < dateGroups.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 12),
                Divider(color: colorScheme.outline.withOpacity(0.2)),
                const SizedBox(height: 12),
              ],
              Text(dateGroups[i].dateLabel, style: dateStyle),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (var j = 0; j < dateGroups[i].showtimes.length; j++) ...[
                    _ShowtimeRow(
                      showtime: dateGroups[i].showtimes[j],
                      timeStyle: timeStyle,
                      detailStyle: detailStyle,
                      colorScheme: colorScheme,
                    ),
                    if (j < dateGroups[i].showtimes.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShowtimeRow extends StatelessWidget {
  const _ShowtimeRow({
    required this.showtime,
    required this.timeStyle,
    required this.detailStyle,
    required this.colorScheme,
  });

  final CinemaShowtime showtime;
  final TextStyle timeStyle;
  final TextStyle detailStyle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final timeText = _normalizeShowtimeValue(showtime.time) ?? '—';

    final details = <String>[];
    final formatText = _normalizeShowtimeValue(showtime.format);
    if (formatText != null) {
      details.add(formatText);
    }
    final roomText = _normalizeShowtimeValue(showtime.room);
    if (roomText != null) {
      details.add('Зал $roomText');
    }
    final endTimeText = _normalizeShowtimeValue(showtime.endTime);
    if (endTimeText != null) {
      details.add('До $endTimeText');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(timeText, style: timeStyle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: details.isEmpty
              ? Text('Информация уточняется', style: detailStyle)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final detail in details)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: colorScheme.surfaceVariant.withOpacity(0.6),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(detail, style: detailStyle),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ShowtimeDateGroup {
  _ShowtimeDateGroup({
    required this.dateLabel,
    List<CinemaShowtime>? showtimes,
  }) : showtimes = List<CinemaShowtime>.from(showtimes ?? const []);

  final String dateLabel;
  final List<CinemaShowtime> showtimes;
}

List<_ShowtimeDateGroup> _groupShowtimesByDate(List<CinemaShowtime> showtimes) {
  final groups = <_ShowtimeDateGroup>[];
  final indexByDate = <String, int>{};

  for (final showtime in showtimes) {
    final dateLabel =
        _normalizeShowtimeValue(showtime.when) ?? 'Дата не указана';
    final index = indexByDate[dateLabel];
    if (index == null) {
      groups.add(
        _ShowtimeDateGroup(
          dateLabel: dateLabel,
          showtimes: [showtime],
        ),
      );
      indexByDate[dateLabel] = groups.length - 1;
    } else {
      groups[index].showtimes.add(showtime);
    }
  }

  for (final group in groups) {
    group.showtimes.sort((a, b) {
      final timeA = _normalizeShowtimeValue(a.time);
      final timeB = _normalizeShowtimeValue(b.time);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });
  }

  return groups;
}

String? _normalizeShowtimeValue(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

