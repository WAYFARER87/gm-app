import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/cinema/models/cinema_film.dart';

class CinemaApiService {
  CinemaApiService() {
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

  late final Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  Future<List<CinemaFilm>> fetchFilms() async {
    final res = await _dio.get('cinema');
    final raw = res.data;
    final payload = _unwrapResponse(raw);

    final data = _extractList(payload) ?? _extractList(raw);
    if (data == null) {
      return const [];
    }

    final films = <CinemaFilm>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        films.add(CinemaFilm.fromJson(item));
      } else if (item is Map) {
        films.add(
          CinemaFilm.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }

    return films;
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
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
      for (final key in const ['items', 'cinema', 'films', 'list', 'results']) {
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
    }
    return null;
  }
}
