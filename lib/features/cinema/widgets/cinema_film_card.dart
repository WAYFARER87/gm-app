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
            child: _Poster(imageUrl: film.imageUrl),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => _showShowtimes(context),
                    child: const Text('Показать сеансы'),
                  ),
                ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => _ShowtimesSheet(film: film),
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

class _ShowtimesSheet extends StatelessWidget {
  const _ShowtimesSheet({required this.film});

  final CinemaFilm film;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final showtimes = film.showtimes;

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
            child: showtimes.isEmpty
                ? Center(
                    child: Text(
                      'Расписание недоступно',
                      style: subtitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: showtimes.length,
                    itemBuilder: (context, index) {
                      final showtime = showtimes[index];
                      return _ShowtimeTile(showtime: showtime);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShowtimeTile extends StatelessWidget {
  const _ShowtimeTile({required this.showtime});

  final CinemaShowtime showtime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String? normalized(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final whenText = normalized(showtime.when) ?? '—';
    final timeText = normalized(showtime.time) ?? '—';

    final details = <String>[];
    final roomText = normalized(showtime.room);
    if (roomText != null) {
      details.add(roomText);
    }
    final formatText = normalized(showtime.format);
    if (formatText != null) {
      details.add(formatText);
    }
    final endTimeText = normalized(showtime.endTime);
    if (endTimeText != null) {
      details.add('До $endTimeText');
    }

    final whenStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
        .copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.2,
    );
    final timeStyle = (textTheme.headlineSmall ?? const TextStyle())
        .copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: colorScheme.primary,
      height: 1.1,
    );
    final detailStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
        .copyWith(
      color: colorScheme.onSurface.withOpacity(0.75),
      height: 1.3,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(whenText, style: whenStyle),
            const SizedBox(height: 6),
            Text(
              timeText,
              style: timeStyle,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (var i = 0; i < details.length; i++) ...[
                Text(details[i], style: detailStyle),
                if (i < details.length - 1) const SizedBox(height: 4),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

