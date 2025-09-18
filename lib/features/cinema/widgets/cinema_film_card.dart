import 'package:flutter/material.dart';

import '../models/cinema_film.dart';

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

