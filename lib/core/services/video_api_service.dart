import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/video/models/video_category.dart';
import '../../features/video/models/video_item.dart';
import '../../features/video/models/video_page.dart';

class VideoApiService {
  static final VideoApiService _instance = VideoApiService._internal();
  factory VideoApiService() => _instance;
  VideoApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://gorodmore.ru/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': _resolveLang(),
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  late Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  /// Получить список видеокатегорий (feeds)
  Future<List<VideoCategory>> fetchFeeds() async {
    final res = await _dio.get('video/feeds');
    final raw = res.data;
    final payload = _unwrapResponse(raw);

    final categories = <VideoCategory>[];
    final data = _extractList(payload) ?? _extractList(raw);
    if (data != null) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          categories.add(VideoCategory.fromJson(item));
        }
      }
    } else if (payload is Map) {
      for (final entry in payload.entries) {
        if (entry.value is Map<String, dynamic>) {
          categories
              .add(VideoCategory.fromJson(entry.value as Map<String, dynamic>));
        }
      }
    }
    return categories;
  }

  /// Получить список видео
  Future<VideoPage> fetchVideos({
    int page = 1,
    int perPage = 20,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{'page': page, 'perPage': perPage};
    if (categoryId?.isNotEmpty ?? false) {
      params['category_id'] = categoryId;
    }

    final res = await _dio.get('video', queryParameters: params);
    final raw = res.data;
    final payload = _unwrapResponse(raw);

    final rawItems = _extractList(payload) ?? _extractList(raw);

    if (rawItems == null || rawItems.isEmpty) {
      throw Exception('No video items found in response');
    }

    final items = <VideoItem>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(VideoItem.fromJson(item));
      }
    }

    if (items.isEmpty) {
      throw Exception('No video items could be parsed');
    }

    final pagination = _extractPagination(payload) ??
        _extractPagination(raw) ??
        const {};

    final pageNum =
        _parseInt(pagination['page'] ?? pagination['current_page']) ?? page;

    final perPageVal = _parseInt(
          pagination['perPage'] ?? pagination['per_page'] ?? pagination['limit'],
        ) ??
        perPage;

    final total = _parseInt(
          pagination['total'] ??
              pagination['total_items'] ??
              pagination['totalItems'] ??
              pagination['count'],
        ) ??
        items.length;

    int? pages = _parseInt(
      pagination['pages'] ??
          pagination['last_page'] ??
          pagination['total_pages'] ??
          pagination['lastPage'],
    );
    final safePerPage = perPageVal > 0
        ? perPageVal
        : (items.isNotEmpty ? items.length : 1);
    if (pages == null && safePerPage > 0) {
      pages = (total / safePerPage).ceil();
    }

    final pagesCount = pages ?? (total / safePerPage).ceil();

    return VideoPage(
      items: items,
      page: pageNum,
      pages: pagesCount,
      total: total,
    );
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }

  dynamic _unwrapResponse(dynamic raw) {
    if (raw is Map) {
      for (final key in const ['data', 'result', 'payload']) {
        if (raw[key] != null) {
          return raw[key];
        }
      }
    }
    return raw;
  }

  List<dynamic>? _extractList(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      for (final key
          in const ['items', 'videos', 'video', 'feeds', 'list', 'results', 'data']) {
        if (data.containsKey(key)) {
          final list = _extractList(data[key]);
          if (list != null) {
            return list;
          }
        }
      }

      final mapValues = <Map<String, dynamic>>[];
      data.forEach((key, value) {
        final keyStr = key.toString();
        if ({'pagination', 'meta', '_meta', 'links', '_links'}.contains(keyStr)) {
          return;
        }
        if (value is Map<String, dynamic>) {
          mapValues.add(value);
        }
      });
      if (mapValues.isNotEmpty) {
        return mapValues;
      }

      for (final entry in data.entries) {
        final keyStr = entry.key.toString();
        if ({'pagination', 'meta', '_meta', 'links', '_links'}.contains(keyStr)) {
          continue;
        }
        final list = _extractList(entry.value);
        if (list != null) {
          return list;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractPagination(dynamic source) {
    if (source is Map) {
      for (final key in const ['pagination', 'meta']) {
        final value = source[key];
        if (value is Map) {
          if (_looksLikePagination(value)) {
            return value.map((k, v) => MapEntry(k.toString(), v));
          }
          final nested = _extractPagination(value);
          if (nested != null) {
            return nested;
          }
        }
      }

      for (final entry in source.entries) {
        final value = entry.value;
        if (value is Map) {
          if (_looksLikePagination(value)) {
            return value.map((k, v) => MapEntry(k.toString(), v));
          }
          final nested = _extractPagination(value);
          if (nested != null) {
            return nested;
          }
        }
      }
    }
    return null;
  }

  bool _looksLikePagination(Map<dynamic, dynamic> map) {
    const keys = {
      'page',
      'current_page',
      'currentPage',
      'per_page',
      'perPage',
      'limit',
      'total',
      'total_items',
      'totalItems',
      'count',
      'pages',
      'last_page',
      'lastPage',
      'total_pages',
      'totalPages',
    };
    for (final key in map.keys) {
      if (keys.contains(key.toString())) {
        return true;
      }
    }
    return false;
  }

  int? _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) {
        return asDouble.toInt();
      }
    }
    return null;
  }
}
