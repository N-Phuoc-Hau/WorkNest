import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    print('DEBUG AuthProvider: _loadFromStorage started');
    state = state.copyWith(isLoading: true);
    
    try {
      final accessToken = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();

      print('DEBUG AuthProvider: Storage tokens - accessToken: ${accessToken != null ? "EXISTS" : "NULL"}, refreshToken: ${refreshToken != null ? "EXISTS" : "NULL"}');

      if (accessToken != null && refreshToken != null) {
        print('DEBUG AuthProvider: Tokens found, checking expiration...');
        // Check if access token is expired
        if (await TokenStorage.isAccessTokenExpired()) {
          print('DEBUG AuthProvider: Access token expired, trying to refresh...');
          // Access token expired, try to refresh
          if (await TokenStorage.isRefreshTokenExpired()) {
            print('DEBUG AuthProvider: Refresh token also expired, logging out...');
            // Refresh token also expired, logout
            await logout();
            return;
          }

          final authService = ref.read(authServiceProvider);
          final refreshResult = await authService.refreshToken(refreshToken);
          
          if (refreshResult['success'] == true) {
            print('DEBUG AuthProvider: Token refresh SUCCESS');
            // Save new tokens
            await TokenStorage.updateTokens(
              accessToken: refreshResult['access_token'],
              refreshToken: refreshResult['refresh_token'],
              accessTokenExpiresAt: DateTime.parse(refreshResult['access_token_expires_at']),
              refreshTokenExpiresAt: DateTime.parse(refreshResult['refresh_token_expires_at']),
            );
            
            state = state.copyWith(
              accessToken: refreshResult['access_token'],
              isAuthenticated: true,
            );
            print('DEBUG AuthProvider: Set isAuthenticated = TRUE after token refresh');
            await fetchUserProfile();
          } else {
            print('DEBUG AuthProvider: Token refresh FAILED, logging out...');
            // Cannot refresh, logout
            await logout();
            return;
          }
        } else {
          print('DEBUG AuthProvider: Access token still valid, setting authenticated');
          // Access token is still valid
          state = state.copyWith(
            accessToken: accessToken,
            isAuthenticated: true,
          );
          print('DEBUG AuthProvider: Set isAuthenticated = TRUE with existing token');
          await fetchUserProfile();
        }
      } else {
        print('DEBUG AuthProvider: No tokens found in storage');
      }
    } catch (e) {
      print('DEBUG AuthProvider: _loadFromStorage exception: $e');
      // If any error occurs, try to logout silently
      await logout();
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tải thông tin người dùng',
      );
    } finally {
      print('DEBUG AuthProvider: _loadFromStorage completed');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<UserModel?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email, password);

      print('DEBUG AuthProvider: Login result = $result');

      if (result['success'] == true) {
        final user = UserModel.fromJson(result['user']);
        final accessToken = result['access_token'];
        final refreshToken = result['refresh_token'];
        final accessTokenExpiresAt = DateTime.parse(result['access_token_expires_at']);
        final refreshTokenExpiresAt = DateTime.parse(result['refresh_token_expires_at']);

        // Save tokens to storage
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          accessTokenExpiresAt: accessTokenExpiresAt,
          refreshTokenExpiresAt: refreshTokenExpiresAt,
        );

        state = state.copyWith(
          user: user,
          accessToken: accessToken,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );

        print('DEBUG AuthProvider: Login SUCCESS, returning user: ${user.fullName}');
        return user;
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: result['message'] ?? 'Đăng nhập thất bại',
        );
        print('DEBUG AuthProvider: Login FAILED, returning null. Error: ${result['message']}');
        print('DEBUG AuthProvider: isAuthenticated set to FALSE');
        return null;
      }
    } catch (e) {
      print('DEBUG AuthProvider: Exception caught: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Đã có lỗi xảy ra, vui lòng thử lại.',
      );
      print('DEBUG AuthProvider: isAuthenticated set to FALSE (exception)');
      return null;
    }
  }

  Future<bool> register(Map<String, dynamic> userData, {bool isRecruiter = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = ref.read(authServiceProvider);
      final result = isRecruiter 
          ? await authService.registerRecruiter(userData)
          : await authService.registerCandidate(userData);

      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Đăng ký thất bại',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registerWithFiles(
    Map<String, dynamic> userData, {
    bool isRecruiter = false,
    XFile? avatarFile,
    List<XFile> companyImageFiles = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = ref.read(authServiceProvider);
      final result = isRecruiter 
          ? await authService.registerRecruiterWithFiles(userData, avatarFile, companyImageFiles)
          : await authService.registerCandidateWithFiles(userData, avatarFile);

      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Đăng ký thất bại',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Revoke refresh token if available
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        final authService = ref.read(authServiceProvider);
        await authService.revokeToken(refreshToken);
      }
    } catch (e) {
      // Ignore errors during logout
    }

    // Clear all tokens
    await TokenStorage.clearAll();
    state = const AuthState(isLoading: false);
  }

  Future<void> fetchUserProfile() async {
    if (state.accessToken == null) return;

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.fetchUserProfile(state.accessToken!);

      if (result['success'] == true) {
        final user = UserModel.fromJson(result['user']);
        state = state.copyWith(user: user);
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (state.accessToken == null) return false;

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.updateProfile(
        state.accessToken!,
        profileData,
      );

      if (result['success'] == true) {
        final user = UserModel.fromJson(result['user']);
        state = state.copyWith(user: user);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Check current token status
  Future<Map<String, dynamic>?> checkTokenStatus() async {
    if (state.accessToken == null) return null;

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.checkTokenStatus(state.accessToken!);
      return result['success'] == true ? result['data'] : null;
    } catch (e) {
      return null;
    }
  }

  // Refresh current token
  Future<bool> refreshToken() async {
    if (state.accessToken == null) return false;

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.refreshToken(state.accessToken!);

      if (result['success'] == true) {
        final newToken = result['token'];
        
        // Save new token to storage
        final prefs = await ref.read(sharedPreferencesProvider.future);
        await prefs.setString('access_token', newToken);

        state = state.copyWith(accessToken: newToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Auto refresh token if needed (call this periodically)
  Future<void> autoRefreshTokenIfNeeded() async {
    final tokenStatus = await checkTokenStatus();
    if (tokenStatus != null) {
      final timeToExpiry = DateTime.parse(tokenStatus['expiresAt']).difference(DateTime.now());
      
      // If token expires in less than 1 hour, refresh it
      if (timeToExpiry.inHours < 1 && timeToExpiry.inMinutes > 0) {
        await refreshToken();
      } else if (timeToExpiry.isNegative) {
        // Token already expired, logout
        await logout();
      }
    }
  }
}
