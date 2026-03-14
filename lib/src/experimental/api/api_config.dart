class ApiConfig {
  const ApiConfig({
    required this.origin,
    this.basePath = '/api/v1',
  });

  final String origin;
  final String basePath;

  bool get isConfigured => origin.trim().isNotEmpty;

  Uri uri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedOrigin = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedOrigin$basePath$normalizedPath',
    ).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }
}
