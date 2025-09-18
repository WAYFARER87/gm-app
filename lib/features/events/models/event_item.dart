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
  final String startTimeText;
  final String endTimeText;
  final String venueName;
  final String venueAddress;
  final String categoryName;

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
    this.startTimeText = '',
    this.endTimeText = '',
    required this.venueName,
    required this.venueAddress,
    required this.categoryName,
  });

  String get fallbackDateText {
    final startText = startTimeText.trim();
    final endText = endTimeText.trim();
    if (startText.isEmpty && endText.isEmpty) {
      return '';
    }
    if (startText.isEmpty) {
      return endText;
    }
    if (endText.isEmpty || startText == endText) {
      return startText;
    }
    return '$startText – $endText';
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    DateTime? start;
    DateTime? end;
    String startTimeText = '';
    String endTimeText = '';

    Map<String, dynamic>? combineDateAndTime(dynamic date, dynamic time) {
      final hasDate = _stringifyDateCandidate(date).isNotEmpty;
      final hasTime = _stringifyDateCandidate(time).isNotEmpty;
      if (!hasDate && !hasTime) {
        return null;
      }
      return <String, dynamic>{
        if (date != null) 'date': date,
        if (time != null) 'time': time,
      };
    }

    final startCandidates = <dynamic>[];
    final endCandidates = <dynamic>[];

    final scheduleMap = schedule is Map<String, dynamic> ? schedule : null;
    if (scheduleMap != null) {
      final scheduleDate = scheduleMap['date'] ?? scheduleMap['day'];
      final scheduleStartDate = scheduleMap['date_start'] ?? scheduleDate;
      final scheduleEndDate = scheduleMap['date_end'] ?? scheduleDate;

      startCandidates.addAll([
        scheduleMap['start'],
        scheduleMap['start_time'],
        scheduleMap['from'],
        scheduleMap['date_start'],
        scheduleMap['begin'],
        combineDateAndTime(
          scheduleStartDate,
          scheduleMap['time'] ??
              scheduleMap['start_time'] ??
              scheduleMap['clock'],
        ),
        scheduleMap['date'],
        scheduleMap['time'],
      ]);

      endCandidates.addAll([
        scheduleMap['end'],
        scheduleMap['end_time'],
        scheduleMap['to'],
        scheduleMap['date_end'],
        scheduleMap['finish'],
        combineDateAndTime(
          scheduleEndDate,
          scheduleMap['time_end'] ??
              scheduleMap['end_time'] ??
              scheduleMap['finish_time'],
        ),
        scheduleMap['time_end'],
      ]);
    }

    final baseDate = json['date'];
    final startDatePart = json['date_start'] ??
        json['start_date'] ??
        json['startDate'] ??
        baseDate;
    final endDatePart = json['date_end'] ??
        json['end_date'] ??
        json['endDate'] ??
        baseDate;

    startCandidates.addAll([
      json['start'],
      json['start_time'],
      json['startDate'],
      json['start_date'],
      json['date_start'],
      combineDateAndTime(
        startDatePart,
        json['time'] ??
            json['start_time'] ??
            json['time_start'] ??
            json['timeStart'],
      ),
      baseDate,
      json['time'],
      json['time_start'],
      json['timeStart'],
    ]);

    endCandidates.addAll([
      json['end'],
      json['end_time'],
      json['endDate'],
      json['end_date'],
      json['date_end'],
      combineDateAndTime(
        endDatePart,
        json['time_end'] ??
            json['end_time'] ??
            json['time_finish'] ??
            json['timeEnd'],
      ),
      json['time_end'],
      json['timeEnd'],
    ]);

    start = _parseFromCandidates(
      startCandidates,
      (value) {
        if (startTimeText.isEmpty) {
          startTimeText = value;
        }
      },
    );
    end = _parseFromCandidates(
      endCandidates,
      (value) {
        if (endTimeText.isEmpty) {
          endTimeText = value;
        }
      },
    );

    final explicitStartTime = _firstNonEmptyString([
      json['time'],
      json['time_start'],
      json['timeStart'],
      if (scheduleMap != null) ...[
        scheduleMap['time'],
        scheduleMap['start_time'],
        scheduleMap['clock'],
      ],
    ]);
    if (explicitStartTime.isNotEmpty) {
      startTimeText = explicitStartTime;
    }

    final explicitEndTime = _firstNonEmptyString([
      json['time_end'],
      json['timeEnd'],
      json['end_time'],
      json['endTime'],
      json['time_finish'],
      json['timeFinish'],
      if (scheduleMap != null) ...[
        scheduleMap['time_end'],
        scheduleMap['end_time'],
        scheduleMap['finish'],
      ],
    ]);
    if (explicitEndTime.isNotEmpty) {
      endTimeText = explicitEndTime;
    }

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
      startTimeText: startTimeText,
      endTimeText: endTimeText,
      venueName: venueName,
      venueAddress: venueAddress,
      categoryName: _extractCategoryName(json),
    );
  }

  static DateTime? _parseFromCandidates(
    List<dynamic> candidates,
    void Function(String) onFallback,
  ) {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final parsed = _parseDateTime(candidate);
      if (parsed != null) {
        return parsed;
      }
      final fallback = _stringifyDateCandidate(candidate);
      if (fallback.isNotEmpty) {
        onFallback(fallback);
      }
    }
    return null;
  }

  static String _firstNonEmptyString(Iterable<dynamic> values) {
    for (final value in values) {
      final text = _stringifyDateCandidate(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _stringifyDateCandidate(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    if (value is Iterable) {
      for (final element in value) {
        final text = _stringifyDateCandidate(element);
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }
    if (value is Map) {
      for (final key in const ['time', 'date', 'value', 'text', 'label', 'display']) {
        if (value.containsKey(key)) {
          final text = _stringifyDateCandidate(value[key]);
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
      for (final entry in value.values) {
        final text = _stringifyDateCandidate(entry);
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }
    return value.toString().trim();
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
    final tickets = json['tickets'];
    final parsed = _stringifyTicketValue(tickets).trim();

    if (parsed.isEmpty) {
      return '';
    }

    final lowerParsed = parsed.toLowerCase();

    if (parsed == '[]' || parsed == '{}' || lowerParsed == 'null') {
      return '';
    }

    return parsed;
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

  static String _extractCategoryName(Map<String, dynamic> json) {
    String parseCategory(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      if (value is num || value is bool) {
        return value.toString();
      }
      if (value is Iterable) {
        for (final element in value) {
          final parsed = parseCategory(element);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
        return '';
      }
      if (value is Map) {
        for (final key in const ['name', 'title', 'label', 'value', 'text']) {
          final parsed = parseCategory(value[key]);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
        for (final entry in value.values) {
          final parsed = parseCategory(entry);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
        return '';
      }
      return value.toString().trim();
    }

    final candidates = [
      json['category'],
      json['category_name'],
      json['category_title'],
      json['categoryName'],
      json['categoryTitle'],
      json['category_label'],
      json['feed_name'],
      json['feed_title'],
      json['feedName'],
      json['feedTitle'],
      json['feed'],
      json['section'],
      json['type'],
    ];

    for (final candidate in candidates) {
      final parsed = parseCategory(candidate);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return '';
  }
}
