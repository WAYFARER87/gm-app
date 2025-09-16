import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
