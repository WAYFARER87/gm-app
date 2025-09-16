import 'dart:convert';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:m_club/core/utils/parse_bool.dart';
import 'package:m_club/features/auth/user_profile.dart';

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

    // Добавляем interceptor для токена
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = '$token';
        }
        handler.next(options);
      },
    ));
  }

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  @visibleForTesting
  Dio get dio => _dio;

  /// Запрос кода по email
  Future<void> requestCode(String email) async {
    final formData = FormData.fromMap({'email': email});
    await _dio.post('/user/request-code', data: formData);
  }

  /// Проверка кода и получение токена
  Future<bool> verifyCode(String email, String code) async {
    final formData = FormData.fromMap({'email': email, 'code': code});
    final res = await _dio.post('/user/verify-code', data: formData);

    if (res.data != null && res.data['token'] != null) {
      await _storage.write(key: 'auth_token', value: res.data['token']);
      return true;
    }
    return false;
  }

  /// Получить профиль пользователя
  Future<UserProfile> fetchProfile() async {
    final res = await _dio.get('/user/profile');
    final data =
        res.data is Map && res.data['data'] is Map ? res.data['data'] : res.data;
    return UserProfile.fromJson(
        Map<String, dynamic>.from(data ?? <String, dynamic>{}));
  }

  /// Обновить профиль пользователя
  /// Возвращает обновлённый профиль, если сервер его прислал
  Future<UserProfile?> updateProfile({
    String? name,
    String? lastName,
    String? phone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (lastName != null) payload['lastname'] = lastName;
    if (phone != null) payload['phone'] = phone;

    try {
      final res = await _dio.patch('/user/profile', data: payload);
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = res.data is Map && res.data['data'] is Map
            ? res.data['data']
            : res.data;
        if (data is Map) {
          return UserProfile.fromJson(
              Map<String, dynamic>.from(data));
        }
        return null;
      }
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Error code: $status',
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('updateProfile error: $e');
      }
      rethrow;
    }
  }

  /// Получить список категорий
  Future<List<dynamic>> fetchCategories() async {
    final res = await _dio.get('/benefits/categories');
    return res.data ?? [];
  }

  /// Получить список предложений
  Future<List<dynamic>> fetchBenefits() async {
    final res = await _dio.get('/benefits');
    return res.data ?? [];
  }

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

  /// Отправить голос за предложение
  /// [id] - идентификатор предложения
  /// [vote] - значение голоса: 1 (лайк) или -1 (дизлайк)
  /// Возвращает карту с актуальными значениями рейтинга и голосом пользователя
  Future<Map<String, dynamic>> voteBenefit(int id, int vote) async {
    final formData = FormData.fromMap({'id': id, 'vote': vote});
    final res = await _dio.post('/benefits/vote', data: formData);
    final data =
        res.data is Map && res.data['data'] is Map ? res.data['data'] : res.data;
    return {
      'rating': data['rating'],
      'vote': data['vote'],
    };
  }

  /// Изменить состояние избранного для предложения (benefit)
  /// [id] - идентификатор предложения
  /// Возвращает текущий признак избранного. Если сервер не вернул
  /// ожидаемого флага, возвращает `null`.
  Future<bool?> toggleBenefitFavorite(int id) async {
    try {
      final formData = FormData.fromMap({'id': id});
      final res = await _dio.post('/benefits/favorites', data: formData);
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
        print('toggleBenefitFavorite error: $e');
      }
      rethrow;
    }
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

  /// Отметиться в предложении
  Future<void> checkinBenefit(int id, double lat, double lng) async {
    try {
      final formData = FormData.fromMap({
        'id': id,
        'coordinates': jsonEncode({'lat': lat, 'lng': lng}),
      });
      await _dio.post('/benefits/checkin', data: formData);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('checkinBenefit error: $e');
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

  /// Удалить профиль пользователя
  Future<void> deleteProfile() async {
    try {
      await _dio.delete('/user/delete');
    } catch (e) {
      if (kDebugMode) {
        print('deleteProfile error: $e');
      }
      rethrow;
    }
  }

  /// Очистить токен (логаут)
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  /// Проверка, есть ли сохранённый токен
  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      return token != null;
    } catch (e) {
      debugPrint('isLoggedIn error: $e');
      return false;
    }
  }
  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
