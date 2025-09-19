import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CurrencyRate {
  const CurrencyRate({
    required this.code,
    required this.value,
    required this.growth,
  });

  final String code;
  final double value;
  final double growth;

  bool get hasPositiveTrend => growth > 0;

  bool get hasNegativeTrend => growth < 0;
}

class RatesResponse {
  const RatesResponse({
    required this.date,
    required this.base,
    required this.rates,
    required this.fallback,
  });

  final DateTime? date;
  final String? base;
  final List<CurrencyRate> rates;
  final bool fallback;

  factory RatesResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    final rawRates = json['rates'];
    final rates = <CurrencyRate>[];
    if (rawRates is Map) {
      for (final entry in rawRates.entries) {
        final key = entry.key;
        if (key == null) {
          continue;
        }
        final code = key.toString();
        if (code.isEmpty) {
          continue;
        }
        final value = entry.value;
        if (value is Map) {
          final rate = _parseRate(code, value.cast<dynamic, dynamic>());
          if (rate != null) {
            rates.add(rate);
          }
        }
      }
    }

    final fallbackRaw = json['fallback'];
    final fallback = fallbackRaw == true || fallbackRaw == 'true';

    return RatesResponse(
      date: parsedDate,
      base: json['base']?.toString(),
      rates: rates,
      fallback: fallback,
    );
  }

  static CurrencyRate? _parseRate(String code, Map<dynamic, dynamic> value) {
    final parsedValue = _toDouble(value['value']);
    if (parsedValue == null) {
      return null;
    }
    final parsedGrowth = _toDouble(value['growth']) ?? 0;
    return CurrencyRate(
      code: code,
      value: parsedValue,
      growth: parsedGrowth,
    );
  }

  static double? _toDouble(dynamic source) {
    if (source is num) {
      return source.toDouble();
    }
    if (source is String) {
      return double.tryParse(source.replaceAll(',', '.'));
    }
    return null;
  }
}

class RatesApiService {
  RatesApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://gorodmore.ru/api/',
        headers: const {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  late final Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  Future<RatesResponse> fetchRates() async {
    final res = await _dio.get('rates');
    final raw = res.data;
    final payload = _unwrapResponse(raw);
    if (payload is Map<String, dynamic>) {
      return RatesResponse.fromJson(payload);
    }
    if (payload is Map) {
      return RatesResponse.fromJson(
        payload.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw Exception('Unexpected rates response format: ${payload.runtimeType}');
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
}
