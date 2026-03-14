import 'package:shared_preferences/shared_preferences.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class AuthTokenStore {
  static const _accessTokenKey = 'api_access_token';
  static const _refreshTokenKey = 'api_refresh_token';

  SharedPreferences? _preferences;

  Future<AuthTokens?> read() async {
    _preferences ??= await SharedPreferences.getInstance();
    final accessToken = _preferences!.getString(_accessTokenKey);
    final refreshToken = _preferences!.getString(_refreshTokenKey);
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> write(AuthTokens tokens) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_accessTokenKey, tokens.accessToken);
    await _preferences!.setString(_refreshTokenKey, tokens.refreshToken);
  }

  Future<void> clear() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.remove(_accessTokenKey);
    await _preferences!.remove(_refreshTokenKey);
  }
}
