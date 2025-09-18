class EventItem {
  final String id;
  final String feedId;
  final String title;
  final String summary;
  final String description;
  final String image;
  final String url;
  final String price;
  final String organizer;
  final String phone;
  final DateTime? startDate;
  final DateTime? endDate;
  final String venueName;
  final String venueAddress;

  EventItem({
    required this.id,
    required this.feedId,
    required this.title,
    required this.summary,
    required this.description,
    required this.image,
    required this.url,
    required this.price,
    required this.organizer,
    required this.phone,
    this.startDate,
    this.endDate,
    required this.venueName,
    required this.venueAddress,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    DateTime? start;
    DateTime? end;
    if (schedule is Map<String, dynamic>) {
      start = _parseDateTime(
            schedule['start'] ??
                schedule['start_time'] ??
                schedule['from'] ??
                schedule['date_start'] ??
                schedule['begin'],
          ) ??
          _parseDateTime(schedule['date']);
      end = _parseDateTime(
        schedule['end'] ??
            schedule['end_time'] ??
            schedule['to'] ??
            schedule['date_end'] ??
            schedule['finish'],
      );
    }

    start ??= _parseDateTime(
      json['start'] ??
          json['start_time'] ??
          json['startDate'] ??
          json['start_date'] ??
          json['date_start'] ??
          json['date'],
    );
    end ??= _parseDateTime(
      json['end'] ??
          json['end_time'] ??
          json['endDate'] ??
          json['end_date'] ??
          json['date_end'],
    );

    final location = json['location'] ?? json['place'] ?? json['venue'];
    String venueName = '';
    String venueAddress = '';
    if (location is Map) {
      venueName = (location['name'] ?? location['title'] ?? location['venue'])
          .toString();
      venueAddress =
          (location['address'] ?? location['full_address'] ?? location['street'])
              .toString();
    } else if (location != null) {
      venueName = location.toString();
    }

    venueName = venueName.isNotEmpty
        ? venueName
        : (json['venue_name'] ?? json['club'] ?? json['organisation'])
            ?.toString() ??
            '';
    venueAddress = venueAddress.isNotEmpty
        ? venueAddress
        : (json['venue_address'] ??
                json['address'] ??
                json['location_address'] ??
                json['place_address'])
            ?.toString() ??
            '';

    return EventItem(
      id: json['id']?.toString() ?? json['event_id']?.toString() ?? '',
      feedId: json['feed_id']?.toString() ?? json['category_id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      summary: (json['summary'] ??
              json['content_preview'] ??
              json['contentPreview'] ??
              json['intro'] ??
              json['preview'] ??
              json['introtext'] ??
              json['intro_text'] ??
              json['short_description'] ??
              json['shortDescription'] ??
              json['short_content'] ??
              json['shortContent'] ??
              json['teaser'] ??
              '')
          .toString(),
      description: (json['description'] ??
              json['content'] ??
              json['body'] ??
              json['content_full'] ??
              json['full_description'] ??
              '')
          .toString(),
      image: (json['image'] ??
              json['image_url'] ??
              json['poster'] ??
              json['cover'] ??
              json['photo'] ??
              '')
          .toString(),
      url: (json['url'] ?? json['link'] ?? json['website'] ?? '').toString(),
      price: _extractTicketInfo(json),
      organizer:
          (json['organizer'] ?? json['author'] ?? json['owner'] ?? '').toString(),
      phone: (json['phone'] ?? json['contact_phone'] ?? '').toString(),
      startDate: start,
      endDate: end,
      venueName: venueName,
      venueAddress: venueAddress,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value == 0) return null;
      final ms = value < 1000000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    if (value is double) {
      final ms = value < 1000000000000 ? (value * 1000).round() : value.round();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    if (value is List && value.isNotEmpty) {
      for (final entry in value) {
        final parsed = _parseDateTime(entry);
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }
    if (value is Map) {
      final datePart = value['date'] ?? value['day'] ?? value['start'] ?? value['value'];
      final timePart =
          value['time'] ?? value['clock'] ?? value['start_time'] ?? value['hours'];
      final combined = [datePart, timePart].whereType<String>().join(' ');
      if (combined.isNotEmpty) {
        final parsed = DateTime.tryParse(combined);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
      if (datePart != null) {
        return _parseDateTime(datePart);
      }
      if (timePart != null) {
        return _parseDateTime(timePart);
      }
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final normalized = trimmed.replaceAll('T', ' ');
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.toLocal();
      }
      final withT = DateTime.tryParse(trimmed);
      if (withT != null) {
        return withT.toLocal();
      }
    }
    return null;
  }

  static String _extractTicketInfo(Map<String, dynamic> json) {
    final candidates = [
      json['price'],
      json['cost'],
      json['fee'],
      json['ticket_price'],
      json['tickets'],
    ];

    for (final candidate in candidates) {
      final parsed = _stringifyTicketValue(candidate).trim();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return '';
  }

  static String _stringifyTicketValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    if (value is Iterable) {
      final items = value
          .map(_stringifyTicketValue)
          .where((element) => element.trim().isNotEmpty)
          .toList();
      if (items.isEmpty) return '';
      return items.join('\n');
    }
    if (value is Map) {
      final textKeys = ['text', 'description', 'info', 'details', 'summary'];
      String text = '';
      for (final key in textKeys) {
        text = _stringifyTicketValue(value[key]);
        if (text.isNotEmpty) break;
      }

      final name = _stringifyTicketValue(
        value['name'] ??
            value['title'] ??
            value['label'] ??
            value['type'] ??
            value['category'],
      );
      final price = _stringifyTicketValue(
        value['price'] ??
            value['cost'] ??
            value['fee'] ??
            value['value'] ??
            value['amount'],
      );
      final url = _stringifyTicketValue(
        value['url'] ?? value['link'] ?? value['href'],
      );

      final parts = <String>[];
      if (text.isNotEmpty) {
        parts.add(text);
      } else {
        final namePriceParts = <String>[];
        if (name.isNotEmpty) namePriceParts.add(name);
        if (price.isNotEmpty) namePriceParts.add(price);
        if (namePriceParts.isNotEmpty) {
          parts.add(namePriceParts.join(' — '));
        }
      }

      if (url.isNotEmpty) {
        parts.add(url);
      }

      if (parts.isEmpty) {
        final fallback = value.values
            .map(_stringifyTicketValue)
            .where((element) => element.trim().isNotEmpty)
            .toList();
        if (fallback.isNotEmpty) {
          parts.addAll(fallback);
        }
      }

      return parts.join('\n').trim();
    }

    return value.toString().trim();
  }
}
