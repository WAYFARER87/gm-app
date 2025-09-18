import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/html_utils.dart';
import 'models/event_item.dart';
import 'utils/event_date_formatter.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.item});

  final EventItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final parsedDescription = htmlToPlainText(
      item.description.isNotEmpty ? item.description : item.summary,
    );
    final ticketInfo = _formatTicketInfo(item.price);

    final date = formatEventDateRange(
      item.startDate,
      item.endDate,
      includeWeekday: true,
    );
    final dateText = date.isNotEmpty ? date : item.fallbackDateText;

    final colorScheme = theme.colorScheme;
    const posterWidth = 120.0;
    const posterAspectRatio = 3 / 4;
    final posterHeight = posterWidth / posterAspectRatio;

    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1.2,
    );
    final baseInfoStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      fontSize: 14,
      color: colorScheme.onSurface.withOpacity(0.75),
      height: 1.4,
    );
    final labelStyle = baseInfoStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );

    Widget buildSummaryLine(String label, String value) {
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

    Widget buildPoster() {
      final borderRadius = BorderRadius.circular(12);
      final placeholder = Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.event, size: 48, color: Colors.grey),
      );

      Widget posterChild;
      if (item.image.isNotEmpty) {
        posterChild = ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            item.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        );
      } else {
        posterChild = ClipRRect(
          borderRadius: borderRadius,
          child: placeholder,
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPoster(context),
        child: Hero(
          tag: 'event-${item.id}',
          child: posterChild,
        ),
      );
    }

    void shareEvent() {
      final locationParts = [
        if (item.venueName.trim().isNotEmpty) item.venueName.trim(),
        if (item.venueAddress.trim().isNotEmpty) item.venueAddress.trim(),
      ];
      final shareText = [
        if (item.title.trim().isNotEmpty) item.title.trim(),
        if (dateText.trim().isNotEmpty) dateText.trim(),
        if (locationParts.isNotEmpty) locationParts.join(', '),
        if (item.url.trim().isNotEmpty) item.url.trim(),
      ].join('\n').trim();

      if (shareText.isNotEmpty) {
        Share.share(shareText);
      }
    }

    final categoryText =
        item.categoryName.trim().isNotEmpty ? item.categoryName.trim() : 'Не указана';
    final dateSummary = dateText.isNotEmpty ? dateText : 'Не указана';
    final placeParts = [
      if (item.venueName.trim().isNotEmpty) item.venueName.trim(),
      if (item.venueAddress.trim().isNotEmpty) item.venueAddress.trim(),
    ];
    final placeText =
        placeParts.isNotEmpty ? placeParts.join(', ') : 'Не указано';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.title.isNotEmpty ? item.title : 'Событие',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: shareEvent,
            tooltip: 'Поделиться',
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: posterWidth,
                height: posterHeight,
                child: buildPoster(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 12),
                    buildSummaryLine('Место', placeText),
                    const SizedBox(height: 8),
                    buildSummaryLine('Категория', categoryText),
                    const SizedBox(height: 8),
                    buildSummaryLine('Дата', dateSummary),
                    if (ticketInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      buildSummaryLine('Билеты', ticketInfo),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (parsedDescription.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              parsedDescription,
              key: const Key('event-description'),
              softWrap: true,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            const Text('Описание недоступно'),
          ],
        ],
      ),
    );
  }

  void _openPoster(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EventPosterFullScreen(
          imageUrl: item.image,
          heroTag: 'event-${item.id}',
        ),
      ),
    );
  }

  String _formatTicketInfo(String price) {
    final trimmed = price.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (!trimmed.contains('<')) {
      return trimmed;
    }

    final normalized = trimmed
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    final segments = normalized
        .split('\n')
        .map((segment) => htmlToPlainText(segment).trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return htmlToPlainText(normalized).trim();
    }

    return segments.join('\n');
  }
}

class _EventPosterFullScreen extends StatelessWidget {
  const _EventPosterFullScreen({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 220,
      height: 300,
      color: Colors.grey.shade900,
      alignment: Alignment.center,
      child: const Icon(Icons.event, size: 96, color: Colors.white70),
    );

    Widget buildPoster() {
      if (imageUrl.trim().isEmpty) {
        return placeholder;
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Постер'),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: buildPoster(),
        ),
      ),
    );
  }
}
