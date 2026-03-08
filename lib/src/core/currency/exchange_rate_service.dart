import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExchangeRateResult {
  const ExchangeRateResult({
    required this.base,
    required this.target,
    required this.rate,
    required this.date,
  });

  final String base;
  final String target;
  final double rate;
  final String date;

  Map<String, Object> toMap() {
    return {
      'base': base,
      'target': target,
      'rate': rate,
      'date': date,
    };
  }

  factory ExchangeRateResult.fromMap(Map<String, dynamic> map) {
    return ExchangeRateResult(
      base: map['base'] as String,
      target: map['target'] as String,
      rate: (map['rate'] as num).toDouble(),
      date: map['date'] as String,
    );
  }
}

class ExchangeRateService {
  const ExchangeRateService();

  static const _frankfurterUrl = 'https://api.frankfurter.dev/v1/latest';
  static const _openErApiUrl = 'https://open.er-api.com/v6/latest';

  Future<ExchangeRateResult> latestRate({
    required String base,
    required String target,
    required SharedPreferences preferences,
  }) async {
    if (base == target) {
      return ExchangeRateResult(
        base: base,
        target: target,
        rate: 1,
        date: DateTime.now().toIso8601String(),
      );
    }

    try {
      final result = await _latestRateFromProviders(base: base, target: target);
      await preferences.setString(_cacheKey(base, target), jsonEncode(result.toMap()));
      return result;
    } on SocketException {
      return _cachedOrThrow(
        preferences,
        base,
        target,
        'No internet connection and no cached exchange rate available.',
      );
    } on HttpException catch (error) {
      return _cachedOrThrow(
        preferences,
        base,
        target,
        'Unable to fetch exchange rate. ${error.message}',
      );
    } on FormatException {
      return _cachedOrThrow(
        preferences,
        base,
        target,
        'Invalid exchange rate response.',
      );
    } on ExchangeRateException catch (error) {
      return _cachedOrThrow(preferences, base, target, error.message);
    }
  }

  Future<ExchangeRateResult> _latestRateFromProviders({
    required String base,
    required String target,
  }) async {
    try {
      return await _fetchFrankfurter(base: base, target: target);
    } catch (_) {
      return _fetchOpenErApi(base: base, target: target);
    }
  }

  Future<ExchangeRateResult> _fetchFrankfurter({
    required String base,
    required String target,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_frankfurterUrl?base=$base&symbols=$target');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Frankfurter returned ${response.statusCode}.',
          uri: uri,
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final rates = Map<String, dynamic>.from(decoded['rates'] as Map);
      final rate = (rates[target] as num?)?.toDouble();
      if (rate == null) {
        throw const ExchangeRateException('Currency rate is unavailable.');
      }

      return ExchangeRateResult(
        base: base,
        target: target,
        rate: rate,
        date: decoded['date'] as String? ?? '',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<ExchangeRateResult> _fetchOpenErApi({
    required String base,
    required String target,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_openErApiUrl/$base');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Open ER API returned ${response.statusCode}.',
          uri: uri,
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if ((decoded['result'] as String?) != 'success') {
        throw const ExchangeRateException('Fallback exchange rate request failed.');
      }
      final rates = Map<String, dynamic>.from(decoded['rates'] as Map);
      final rate = (rates[target] as num?)?.toDouble();
      if (rate == null) {
        throw const ExchangeRateException('Currency rate is unavailable.');
      }

      return ExchangeRateResult(
        base: base,
        target: target,
        rate: rate,
        date: decoded['time_last_update_utc'] as String? ?? '',
      );
    } finally {
      client.close(force: true);
    }
  }

  ExchangeRateResult _cachedOrThrow(
    SharedPreferences preferences,
    String base,
    String target,
    String message,
  ) {
    final cached = preferences.getString(_cacheKey(base, target));
    if (cached != null && cached.isNotEmpty) {
      return ExchangeRateResult.fromMap(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    }
    throw ExchangeRateException(message);
  }

  String _cacheKey(String base, String target) =>
      'cached_exchange_rate_${base}_$target';
}
