import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final description = film.description?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Poster(imageUrl: film.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
                  const SizedBox(height: 16),
                  Text(
                    htmlToPlainText(description),
                    style: (textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in groups.entries) ...[
                    if (entry != groups.entries.first) const SizedBox(height: 16),
                    Text(
                      entry.key,
                      style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final showtime in entry.value)
                      _ShowtimeTile(
                        showtime: showtime,
                        onBuyPressed: showtime.hasBuyUrl
                            ? () => _openBuyUrl(context, showtime.buyUrl)
                            : null,
                      ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Нет ближайших сеансов',
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
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

  Future<void> _openBuyUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showLaunchError(context);
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showLaunchError(context);
      }
    } catch (_) {
      _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Не удалось открыть ссылку')),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.local_movies, size: 48, color: Colors.grey),
    );

    if (imageUrl.isEmpty) {
      return AspectRatio(aspectRatio: 3 / 4, child: placeholder);
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
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

class _ShowtimeTile extends StatelessWidget {
  const _ShowtimeTile({required this.showtime, this.onBuyPressed});

  final CinemaShowtime showtime;
  final VoidCallback? onBuyPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final details = <String>[];
    final cinemaName = htmlToPlainText(showtime.cinemaId).replaceAll('\n', ', ');
    if (cinemaName.trim().isNotEmpty) {
      details.add(cinemaName.trim());
    }
    if (showtime.endTime.trim().isNotEmpty) {
      details.add('До ${showtime.endTime.trim()}');
    }

    final timeParts = <String>[];
    if (showtime.time.trim().isNotEmpty) {
      timeParts.add(showtime.time.trim());
    }
    if (showtime.room.trim().isNotEmpty) {
      timeParts.add(showtime.room.trim());
    }
    if (showtime.format.trim().isNotEmpty) {
      timeParts.add(showtime.format.trim());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primary.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timeParts.isNotEmpty)
            Text(
              timeParts.join(' • '),
              style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.join('\n'),
              style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: colorScheme.onSurface.withOpacity(0.75),
                height: 1.3,
              ),
            ),
          ],
          if (onBuyPressed != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onBuyPressed,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Купить билет'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
