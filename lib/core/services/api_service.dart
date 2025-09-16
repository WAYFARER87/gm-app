import 'dart:convert';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:m_club/core/utils/parse_bool.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.mclub.ae/v4',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json', 'Accept-Language': _resolveLang(),},
    ));
  }

  late Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  /// Получить список рекомендаций
  Future<List<dynamic>> fetchRecommendations() async {
    final res = await _dio.get('/recommendation');
    return res.data ?? [];
  }

  /// Получить список категорий рекомендаций
  Future<List<dynamic>> fetchRecommendationCategories() async {
    final res = await _dio.get('/recommendation/categories');
    return res.data ?? [];
  }

  /// Отправить голос за рекомендацию
  /// [id] - идентификатор рекомендации
  /// [vote] - значение голоса: 1 (лайк) или -1 (дизлайк)
  /// Возвращает карту с актуальными значениями рейтинга и голосом пользователя
  Future<Map<String, dynamic>> voteRecommendation(int id, int vote) async {
    final formData = FormData.fromMap({'id': id, 'vote': vote});
    final res = await _dio.post('/recommendation/vote', data: formData);
    final data =
        res.data is Map && res.data['data'] is Map ? res.data['data'] : res.data;
    return {
      'rating': data['rating'],
      'vote': data['vote'],
    };
  }

  /// Изменить состояние избранного для рекомендации
  /// [id] - идентификатор рекомендации
  /// Возвращает текущий признак избранного. Если сервер не вернул
  /// ожидаемого флага, возвращает `null`.
  Future<bool?> toggleRecommendationFavorite(int id) async {
    try {
      final formData = FormData.fromMap({'id': id});
      final res = await _dio.post('/recommendation/favorites', data: formData);
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is Map) {
        final value = data.containsKey('favorites')
            ? data['favorites']
            : data['is_favorite'];
        if (value == null) return null;
        if (value is bool || value is String || value is num) {
          return parseBool(value);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('toggleRecommendationFavorite error: $e');
      }
      rethrow;
    }
  }

  /// Отметиться в рекомендации
  Future<void> checkinRecommendation(int id, double lat, double lng) async {
    try {
      final formData = FormData.fromMap({
        'id': id,
        'coordinates': jsonEncode({'lat': lat, 'lng': lng}),
      });
      await _dio.post('/recommendation/checkin', data: formData);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('checkinRecommendation error: $e');
      }
      rethrow;
    }
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
