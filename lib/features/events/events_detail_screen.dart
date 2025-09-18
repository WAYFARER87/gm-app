import 'package:flutter/material.dart';

import '../../core/utils/html_utils.dart';
import 'models/event_item.dart';
import 'utils/event_date_formatter.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.item});

  final EventItem item;

  @override
  Widget build(BuildContext context) {
    final description = htmlToPlainText(
      item.description.isNotEmpty ? item.description : item.summary,
    );
    final date = formatEventDateRange(
      item.startDate,
      item.endDate,
      includeWeekday: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.title.isNotEmpty ? item.title : 'Событие',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        children: [
          if (item.image.isNotEmpty)
            Hero(
              tag: 'event-${item.id}',
              child: Image.network(
                item.image,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 260,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.event, size: 48, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              height: 260,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.event, size: 64, color: Colors.grey),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 12),
                if (date.isNotEmpty)
                  _InfoRow(
                    icon: Icons.schedule,
                    text: date,
                  ),
                if (item.venueName.isNotEmpty || item.venueAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InfoRow(
                      icon: Icons.place,
                      text: [
                        if (item.venueName.isNotEmpty) item.venueName,
                        if (item.venueAddress.isNotEmpty) item.venueAddress,
                      ].join(', '),
                    ),
                  ),
                if (item.price.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InfoRow(
                      icon: Icons.sell,
                      text: item.price,
                    ),
                  ),
                if (item.organizer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InfoRow(
                      icon: Icons.business_center,
                      text: item.organizer,
                    ),
                  ),
                if (item.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InfoRow(
                      icon: Icons.phone,
                      text: item.phone,
                    ),
                  ),
                if (item.url.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InfoRow(
                      icon: Icons.link,
                      text: item.url,
                    ),
                  ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (description.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('Описание недоступно'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
