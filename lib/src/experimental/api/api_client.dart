import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../core/errors/app_failure.dart';
import '../../core/result/app_result.dart';
import 'api_config.dart';
import 'api_response.dart';
import 'auth_token_store.dart';

class ApiClient {
  ApiClient({
    required ApiConfig config,
    required AuthTokenStore tokenStore,
    HttpClient? httpClient,
    bool enableLogging = true,
  }) : _config = config,
       _tokenStore = tokenStore,
       _httpClient = httpClient ?? HttpClient(),
       _enableLogging = enableLogging;

  final ApiConfig _config;
  final AuthTokenStore _tokenStore;
  final HttpClient _httpClient;
  final bool _enableLogging;
  Future<AuthTokens?> Function(String refreshToken)? onRefreshToken;
  Future<void> Function()? onUnauthorized;
  Future<AuthTokens?>? _refreshFuture;

  Future<AppResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? data) decoder,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      decoder: decoder,
      requiresAuth: requiresAuth,
    );
  }

  Future<AppResult<T>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decoder,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      decoder: decoder,
      requiresAuth: requiresAuth,
    );
  }

  Future<AppResult<T>> patch<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decoder,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      body: body,
      decoder: decoder,
      requiresAuth: requiresAuth,
    );
  }

  Future<AppResult<T>> delete<T>(
    String path, {
    required T Function(Object? data) decoder,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      decoder: decoder,
      requiresAuth: requiresAuth,
    );
  }

  Future<AppResult<T>> _send<T>({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? data) decoder,
    required bool requiresAuth,
    bool retriedAfterRefresh = false,
  }) async {
    final uri = _config.uri(path, queryParameters: queryParameters);
    final requestHeaders = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    try {
      final request = await _httpClient.openUrl(
        method,
        uri,
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (requiresAuth) {
        final tokens = await _tokenStore.read();
        if (tokens == null) {
          _log(
            'AUTH MISSING [$method] $uri\nheaders: ${_formatJson(requestHeaders)}',
          );
          return AppFailureResult<T>(const UnauthorizedFailure());
        }
        requestHeaders[HttpHeaders.authorizationHeader] =
            'Bearer ${tokens.accessToken}';
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${tokens.accessToken}',
        );
      }
      _logRequest(
        method: method,
        uri: uri,
        headers: requestHeaders,
        body: encodedBody,
        retriedAfterRefresh: retriedAfterRefresh,
      );
      if (encodedBody != null) {
        request.write(encodedBody);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      _logResponse(
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        headers: _extractHeaders(response.headers),
        body: responseBody,
      );

      if (response.statusCode == HttpStatus.unauthorized &&
          requiresAuth &&
          !retriedAfterRefresh &&
          onRefreshToken != null) {
        _log('AUTH REFRESH TRIGGERED [$method] $uri');
        final refreshed = await _refreshTokens();
        if (refreshed != null) {
          return _send(
            method: method,
            path: path,
            body: body,
            queryParameters: queryParameters,
            decoder: decoder,
            requiresAuth: requiresAuth,
            retriedAfterRefresh: true,
          );
        }
        if (onUnauthorized != null) {
          await onUnauthorized!.call();
        }
        return AppFailureResult<T>(const UnauthorizedFailure());
      }

      final envelope = decodeEnvelope<T>(responseBody, decoder);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          envelope.isSuccess) {
        return AppSuccess(envelope.data as T);
      }
      final failure = envelope.error != null
          ? failureFromApiError(envelope.error!)
          : ServerFailure('Unexpected response: ${response.statusCode}');
      return AppFailureResult<T>(failure);
    } on SocketException catch (error) {
      _logError(method: method, uri: uri, error: error);
      return AppFailureResult<T>(const NetworkFailure());
    } on HandshakeException catch (error) {
      _logError(method: method, uri: uri, error: error);
      return AppFailureResult<T>(const NetworkFailure());
    } catch (error) {
      _logError(method: method, uri: uri, error: error);
      return AppFailureResult<T>(ServerFailure(error.toString()));
    }
  }

  Future<AuthTokens?> _refreshTokens() async {
    final existingFuture = _refreshFuture;
    if (existingFuture != null) {
      return existingFuture;
    }
    final completer = Completer<AuthTokens?>();
    _refreshFuture = completer.future;
    final tokens = await _tokenStore.read();
    if (tokens == null || onRefreshToken == null) {
      completer.complete(null);
      _refreshFuture = null;
      return null;
    }
    try {
      _log('AUTH REFRESH REQUEST');
      final refreshed = await onRefreshToken!(tokens.refreshToken);
      if (refreshed != null) {
        await _tokenStore.write(refreshed);
        _log('AUTH REFRESH SUCCESS');
      }
      completer.complete(refreshed);
      return refreshed;
    } catch (_) {
      _log('AUTH REFRESH FAILED');
      completer.complete(null);
      return null;
    } finally {
      _refreshFuture = null;
    }
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
    required bool retriedAfterRefresh,
  }) {
    _log(
      'REQUEST [$method] $uri'
      '${retriedAfterRefresh ? ' (retry)' : ''}\n'
      'headers: ${_formatJson(headers)}\n'
      'body: ${body ?? 'null'}',
    );
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    _log(
      'RESPONSE [$method] $uri\n'
      'status: $statusCode\n'
      'headers: ${_formatJson(headers)}\n'
      'body: ${body.isEmpty ? 'null' : body}',
    );
  }

  void _logError({
    required String method,
    required Uri uri,
    required Object error,
  }) {
    _log('ERROR [$method] $uri\n$error');
  }

  void _log(String message) {
    if (!_enableLogging) {
      return;
    }
    developer.log(message, name: 'ApiClient');
  }

  Map<String, String> _extractHeaders(HttpHeaders headers) {
    final values = <String, String>{};
    headers.forEach((name, headerValues) {
      values[name] = headerValues.join(', ');
    });
    return values;
  }

  String _formatJson(Map<String, String> values) {
    return jsonEncode(values);
  }
}
