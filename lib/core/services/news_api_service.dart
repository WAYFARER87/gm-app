import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:m_club/features/news/models/news_category.dart';
import 'package:m_club/features/news/models/news_item.dart';
import 'package:m_club/features/news/models/news_page.dart';

class NewsApiService {
  static final NewsApiService _instance = NewsApiService._internal();
  factory NewsApiService() => _instance;
  NewsApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://russianemirates.com/api/v4/',
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

  /// Получить список новостных лент (feeds)
  Future<List<NewsCategory>> fetchFeeds() async {
    final res = await _dio.get('news/feeds/');
    final raw = res.data;
    final data = raw is Map && raw['data'] is List ? raw['data'] : raw;

    final categories = <NewsCategory>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          categories.add(NewsCategory.fromJson(item));
        }
      }
    } else if (data is Map) {
      for (final item in data.values) {
        if (item is Map<String, dynamic>) {
          categories.add(NewsCategory.fromJson(item));
        }
      }
    }
    return categories;
  }

  /// Получить список новостей
  Future<NewsPage> fetchNews({
    int page = 1,
    int perPage = 20,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{'page': page, 'per-page': perPage};
    if (categoryId?.isNotEmpty ?? false) {
      params['category_id'] = categoryId;
    }

    final res = await _dio.get('news/', queryParameters: params);
    final raw = res.data;

    List? rawItems;
    if (raw is List) {
      rawItems = raw;
    } else if (raw is Map) {
      if (raw['data'] is List) {
        rawItems = raw['data'] as List;
      } else if (raw['news'] is List) {
        rawItems = raw['news'] as List;
      } else if (raw['items'] is List) {
        rawItems = raw['items'] as List;
      } else {
        final firstList = raw.values.whereType<List>().toList();
        if (firstList.isNotEmpty) {
          rawItems = firstList.first;
        }
      }
    }

    if (rawItems == null || rawItems.isEmpty) {
      throw Exception('No news items found in response');
    }

    final items = <NewsItem>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(NewsItem.fromJson(item));
      }
    }

    if (items.isEmpty) {
      throw Exception('No news items could be parsed');
    }

    final pagination = raw is Map && raw['pagination'] is Map
        ? raw['pagination'] as Map
        : const {};

    final pageRaw = pagination['page'];
    final pageNum = pageRaw is num
        ? pageRaw.toInt()
        : pageRaw is String
            ? int.tryParse(pageRaw) ?? page
            : page;

    final perPageRaw = pagination['perPage'];
    final perPageVal = perPageRaw is num
        ? perPageRaw.toInt()
        : perPageRaw is String
            ? int.tryParse(perPageRaw) ?? perPage
            : perPage;

    final totalRaw = pagination['total'];
    final total = totalRaw is num
        ? totalRaw.toInt()
        : totalRaw is String
            ? int.tryParse(totalRaw) ?? items.length
            : items.length;

    final pagesRaw = pagination['pages'];
    int? pages = pagesRaw is num
        ? pagesRaw.toInt()
        : pagesRaw is String
            ? int.tryParse(pagesRaw)
            : null;
    pages ??= (total / perPageVal).ceil();

    return NewsPage(items: items, page: pageNum, pages: pages, total: total);
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
