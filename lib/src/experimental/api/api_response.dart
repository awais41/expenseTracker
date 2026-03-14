import 'dart:convert';

import '../../core/errors/app_failure.dart';

class ApiErrorPayload {
  const ApiErrorPayload({
    required this.message,
    required this.code,
    this.details,
  });

  final String message;
  final String code;
  final Object? details;

  factory ApiErrorPayload.fromMap(Map<String, dynamic> map) {
    return ApiErrorPayload(
      message: map['message'] as String? ?? 'Unexpected API error.',
      code: map['code'] as String? ?? 'INTERNAL_ERROR',
      details: map['details'],
    );
  }
}

class ApiEnvelope<T> {
  const ApiEnvelope.success(this.data)
    : error = null,
      isSuccess = true;

  const ApiEnvelope.failure(this.error)
    : data = null,
      isSuccess = false;

  final T? data;
  final ApiErrorPayload? error;
  final bool isSuccess;
}

ApiEnvelope<T> decodeEnvelope<T>(
  String responseBody,
  T Function(Object? data) decoder,
) {
  final parsed = responseBody.isEmpty
      ? const <String, dynamic>{}
      : jsonDecode(responseBody) as Map<String, dynamic>;
  if (parsed.containsKey('error')) {
    return ApiEnvelope.failure(
      ApiErrorPayload.fromMap(
        Map<String, dynamic>.from(parsed['error'] as Map),
      ),
    );
  }
  return ApiEnvelope.success(decoder(parsed['data']));
}

AppFailure failureFromApiError(ApiErrorPayload error) {
  switch (error.code) {
    case 'BAD_REQUEST':
      return ValidationFailure(error.message);
    case 'UNAUTHORIZED':
      return UnauthorizedFailure(error.message);
    case 'FORBIDDEN':
      return ForbiddenFailure(error.message);
    case 'NOT_FOUND':
      return NotFoundFailure(error.message);
    case 'CONFLICT':
      return ConflictFailure(error.message);
    case 'INTERNAL_ERROR':
    default:
      return ServerFailure(error.message);
  }
}
