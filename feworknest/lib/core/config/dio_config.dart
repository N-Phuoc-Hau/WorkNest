import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../utils/token_storage.dart';

class DioConfig {
  static Dio createDio({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        logPrint: (object) {
          print('🌐 API LOG: $object');
        },
      ));
    }

    // Add authentication interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add access token to request
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Skip token refresh for auth endpoints (login, register, etc.)
        final isAuthEndpoint = error.requestOptions.path.contains('/Auth/login') ||
                              error.requestOptions.path.contains('/Auth/register') ||
                              error.requestOptions.path.contains('/Auth/refresh-token');
        
        // Handle 401 Unauthorized errors only for protected endpoints
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          try {
            // Check if we have a refresh token
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              // Check if refresh token is expired
              if (await TokenStorage.isRefreshTokenExpired()) {
                // Refresh token is expired, clear all tokens
                await TokenStorage.clearAll();
                return handler.next(error);
              }

              // Try to refresh the access token
              final authService = AuthService();
              final refreshResult = await authService.refreshToken(refreshToken);

              if (refreshResult['success'] == true) {
                // Save new tokens
                await TokenStorage.updateTokens(
                  accessToken: refreshResult['access_token'],
                  refreshToken: refreshResult['refresh_token'],
                  accessTokenExpiresAt: DateTime.parse(refreshResult['access_token_expires_at']),
                  refreshTokenExpiresAt: DateTime.parse(refreshResult['refresh_token_expires_at']),
                );

                // Retry the original request with new access token
                final newAccessToken = refreshResult['access_token'];
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                // Create new request with updated headers
                final newRequest = await dio.fetch(error.requestOptions);
                return handler.resolve(newRequest);
              } else {
                // Refresh failed, clear all tokens
                await TokenStorage.clearAll();
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Token refresh failed: $e');
            }
            // Clear tokens on any error
            await TokenStorage.clearAll();
          }
        }

        // Only log non-auth endpoint errors to avoid double logging
        if (kDebugMode && !isAuthEndpoint) {
          print('❌ API Error: ${error.message}');
          print('🔍 Error Type: ${error.type}');
          if (error.response != null) {
            print('📊 Status Code: ${error.response!.statusCode}');
            print('📋 Response Data: ${error.response!.data}');
          }
        }
        return handler.next(error);
      },
    ));

    return dio;
  }
}
