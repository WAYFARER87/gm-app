import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:m_club/features/radio/models/radio_track.dart';

class RadioApiService {
  static final RadioApiService _instance = RadioApiService._internal();
  factory RadioApiService() => _instance;
  RadioApiService._internal() {
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

  Future<Map<String, String>> fetchStreams() async {
    try {
      final res = await _dio.get('radio/list');
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      final streams = <String, String>{};
      if (data is Map) {
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key != null && value != null) {
            streams[key.toString()] = value.toString();
          }
        }
        return streams;
      }
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Invalid response format',
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('fetchStreams error: $e');
      }
      rethrow;
    }
  }

  Future<RadioTrack?> fetchTrackInfo() async {
    try {
      final res = await _dio.get('radio/get-info');
      final raw = res.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is Map) {
        return RadioTrack.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('fetchTrackInfo error: $e');
      }
      rethrow;
    }
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
