import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiresAtKey = 'access_token_expires_at';
  static const String _refreshTokenExpiresAtKey = 'refresh_token_expires_at';
  static const String _userKey = 'user_data';

  // Save tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_accessTokenExpiresAtKey, accessTokenExpiresAt.toIso8601String());
    await prefs.setString(_refreshTokenExpiresAtKey, refreshTokenExpiresAt.toIso8601String());
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get access token expiration
  static Future<DateTime?> getAccessTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtString = prefs.getString(_accessTokenExpiresAtKey);
    if (expiresAtString != null) {
      return DateTime.parse(expiresAtString);
    }
    return null;
  }

  // Get refresh token expiration
  static Future<DateTime?> getRefreshTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtString = prefs.getString(_refreshTokenExpiresAtKey);
    if (expiresAtString != null) {
      return DateTime.parse(expiresAtString);
    }
    return null;
  }

  // Check if access token is expired
  static Future<bool> isAccessTokenExpired() async {
    final expiresAt = await getAccessTokenExpiresAt();
    if (expiresAt == null) return true;
    
    // Add 5 minutes buffer to refresh before expiration
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
  }

  // Check if refresh token is expired
  static Future<bool> isRefreshTokenExpired() async {
    final expiresAt = await getRefreshTokenExpiresAt();
    if (expiresAt == null) return true;
    
    return DateTime.now().isAfter(expiresAt);
  }

  // Update access token only
  static Future<void> updateAccessToken({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_accessTokenExpiresAtKey, accessTokenExpiresAt.toIso8601String());
  }

  // Update both tokens
  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_accessTokenExpiresAtKey, accessTokenExpiresAt.toIso8601String());
    await prefs.setString(_refreshTokenExpiresAtKey, refreshTokenExpiresAt.toIso8601String());
  }

  // Legacy methods for backward compatibility
  static Future<void> saveToken(String token) async {
    await saveTokens(
      accessToken: token,
      refreshToken: '',
      accessTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  static Future<String?> getToken() async {
    return await getAccessToken();
  }

  static Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessTokenExpiresAtKey);
    await prefs.remove(_refreshTokenExpiresAtKey);
    await prefs.remove(_userKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accessTokenExpiresAtKey);
    await prefs.remove(_refreshTokenExpiresAtKey);
  }

  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
