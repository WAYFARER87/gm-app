import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                if (film.showtimes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ShowtimesSection(showtimes: film.showtimes),
                ],
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

}

class _ShowtimesSection extends StatelessWidget {
  const _ShowtimesSection({required this.showtimes});

  final List<CinemaShowtime> showtimes;

  @override
  Widget build(BuildContext context) {
    if (showtimes.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = <String, List<CinemaShowtime>>{};

    for (final showtime in showtimes) {
      final normalizedDate = showtime.when.trim().isEmpty
          ? 'Дата не указана'
          : showtime.when.trim();
      groups.putIfAbsent(normalizedDate, () => <CinemaShowtime>[]).add(showtime);
    }

    final sectionTitleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );

    final groupEntries = groups.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Расписание', style: sectionTitleStyle),
        const SizedBox(height: 12),
        ...List.generate(groupEntries.length, (index) {
          final entry = groupEntries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == groupEntries.length - 1 ? 0 : 12),
            child: _ShowtimeGroupCard(
              date: entry.key,
              showtimes: entry.value,
            ),
          );
        }),
      ],
    );
  }
}

class _ShowtimeGroupCard extends StatelessWidget {
  const _ShowtimeGroupCard({required this.date, required this.showtimes});

  final String date;
  final List<CinemaShowtime> showtimes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final dividerColor = colorScheme.outline.withOpacity(0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: dateStyle),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final showtime in showtimes)
                _ShowtimeChip(showtime: showtime),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowtimeChip extends StatelessWidget {
  const _ShowtimeChip({required this.showtime});

  final CinemaShowtime showtime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(999);
    final textStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.primary,
    );

    final timeText = showtime.time.trim().isEmpty ? '—' : showtime.time.trim();

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(timeText, style: textStyle),
          if (showtime.hasBuyUrl) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ],
      ),
    );

    if (!showtime.hasBuyUrl) {
      return pill;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => _openBuyUrl(context),
        child: pill,
      ),
    );
  }

  Future<void> _openBuyUrl(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(showtime.buyUrl.trim());
    if (uri == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
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

